/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.util;

import gov.nasa.worldwind.*;
import gov.nasa.worldwind.avlist.AVKey;
import gov.nasa.worldwind.event.*;
import gov.nasa.worldwind.geom.*;
import gov.nasa.worldwind.globes.Globe;
import gov.nasa.worldwind.layers.*;
import gov.nasa.worldwind.pick.*;
import gov.nasa.worldwind.render.*;
import gov.nasa.worldwind.render.airspaces.*;
import gov.nasa.worldwind.render.airspaces.Box;
import gov.nasa.worldwind.render.airspaces.Polygon;
import gov.nasa.worldwind.render.markers.*;

import java.awt.*;
import java.util.*;
import java.util.List;

/**
 * @author tag
 * @version $Id$
 */
public class AirspaceEditor implements SelectListener
{
    // Control point purposes
    /**
     * Indicates that a control point is associated with annotation.
     */
    protected String ANNOTATION = "gov.nasa.worldwind.airspaceditor.Annotation";
    /**
     * Indicates a control point is associated with a location.
     */
    protected String LOCATION = "gov.nasa.worldwind.airspaceditor.Location";
    /**
     * Indicates that a control point is associates with whole-shape rotation.
     */
    protected String ROTATION = "gov.nasa.worldwind.airspaceditor.Rotation";
    /**
     * Indicates that a control point is associated with the left width of a shape.
     */
    protected String LEFT_WIDTH = "gov.nasa.worldwind.airspaceditor.LeftWidth";
    /**
     * Indicates that a control point is associated with the right width of a shape.
     */
    protected String RIGHT_WIDTH = "gov.nasa.worldwind.airspaceditor.RightWidth";
    /**
     * Indicates that a control point is associated with the inner radius of a shape.
     */
    protected String INNER_RADIUS = "gov.nasa.worldwind.airspaceditor.InnerRadius";
    /**
     * Indicates that a control point is associated with the outer radius of a shape.
     */
    protected String OUTER_RADIUS = "gov.nasa.worldwind.airspaceditor.OuterRadius";
    /**
     * Indicates that a control point is associated with the left azimuth of a shape.
     */
    protected String LEFT_AZIMUTH = "gov.nasa.worldwind.airspaceditor.LeftAzimuth";
    /**
     * Indicates that a control point is associated with the right azimuth of a shape.
     */
    protected String RIGHT_AZIMUTH = "gov.nasa.worldwind.airspaceditor.RightAzimuth";

    protected static class ControlPointMarker extends BasicMarker
    {
        /**
         * The control point's ID.
         */
        protected int id;
        /**
         * Identifies individual track boxes and cake layers.
         */
        protected int leg;
        /**
         * Indicates the feature the control point affects.
         */
        protected String purpose; // indicates the feature the control point affects
        /**
         * Indicates size (in meters) if this control point affects a size of the shape, otherwise null.
         */
        protected Double size;
        /**
         * Indicates angle if this control point affects an angle associated with the shape, otherwise null.
         */
        protected Angle rotation;

        public ControlPointMarker(Position position, MarkerAttributes attrs, int id, String purpose)
        {
            super(position, attrs);
            this.id = id;
            this.purpose = purpose;
        }

        public ControlPointMarker(Position position, MarkerAttributes attrs, int id, int leg, String purpose)
        {
            this(position, attrs, id, purpose);

            this.leg = leg;
        }

        public int getId()
        {
            return this.id;
        }

        public int getLeg()
        {
            return leg;
        }

        public String getPurpose()
        {
            return this.purpose;
        }

        public Double getSize()
        {
            return size;
        }

        public Angle getRotation()
        {
            return rotation;
        }
    }

    /**
     * Editor state indicating that the shape is not being resized or moved.
     */
    protected static final int NONE = 0;
    /**
     * Editor state indicating that the shape is being moved.
     */
    protected static final int MOVING = 1;
    /**
     * Editor state indicating that the shape is being sized or otherwise respecified.
     */
    protected static final int SIZING = 2;

    /**
     * The {@link gov.nasa.worldwind.WorldWindow} associated with the shape.
     */
    protected final WorldWindow wwd;
    /**
     * The shape associated with the editor. Specified at construction and not subsequently modifiable.
     */
    protected Airspace shape;
    /**
     * The layer holding the editor's control points.
     */
    protected MarkerLayer controlPointLayer;
    /**
     * The layer holding the rotation line and perhaps other affordances.
     */
    protected RenderableLayer accessoryLayer;
    /**
     * The layer holding the control point's annotation.
     */
    protected RenderableLayer annotationLayer;
    /**
     * The layer holding a shadow copy of the shape while the shape is being moved or sized.
     */
    protected RenderableLayer shadowLayer;
    /**
     * The control point annotation.
     */
    protected EditorAnnotation annotation;
    /**
     * The units formatter to use when creating control point annotations.
     */
    protected UnitsFormat unitsFormat;

    /**
     * Indicates whether the editor is ready for editing.
     */
    protected boolean armed;
    /**
     * Indicates whether the editor is in the midst of an editing operation.
     */
    protected boolean active;
    /**
     * Indicates the current editing operation, one of NONE, MOVING or SIZING.
     */
    protected int activeOperation = NONE;
    /**
     * The terrain position associated with the cursor during the just previous drag event.
     */
    protected Position previousPosition = null;
    /**
     * The control point associated with the current sizing operation.
     */
    protected ControlPointMarker currentSizingMarker;
    protected AirspaceAttributes originalAttributes;
    protected AirspaceAttributes originalHighlightAttributes;
    /**
     * For shapes without an inherent heading, the current heading established by the editor for the shape.
     */
    protected Angle currentHeading = Angle.ZERO;
    /**
     * Indicates track legs that are adjacent to their previous leg in the track.
     */
    protected List<Box> trackAdjacencyList;

    protected MarkerAttributes locationMarkerAttributes;
    protected MarkerAttributes sizeMarkerAttributes;
    protected MarkerAttributes angleMarkerAttributes;

    /**
     * Constructs and editor for a specified shape. Once constructed, the editor must be armed to operate. See {@link
     * #setArmed(boolean)}.
     *
     * @param wwd           the {@link gov.nasa.worldwind.WorldWindow} associated with the specified shape.
     * @param originalShape the shape to edit.
     *
     * @throws java.lang.IllegalArgumentException if either the specified world window or shape is null.
     */
    public AirspaceEditor(WorldWindow wwd, Airspace originalShape)
    {
        if (wwd == null)
        {
            String msg = Logging.getMessage("nullValue.WorldWindow");
            Logging.logger().log(java.util.logging.Level.SEVERE, msg);
            throw new IllegalArgumentException(msg);
        }

        if (originalShape == null)
        {
            String msg = Logging.getMessage("nullValue.Shape");
            Logging.logger().log(java.util.logging.Level.SEVERE, msg);
            throw new IllegalArgumentException(msg);
        }

        if (!(originalShape instanceof Movable2))
        {
            String msg = Logging.getMessage("generic.Movable2NotSupported");
            Logging.logger().log(java.util.logging.Level.SEVERE, msg);
            throw new IllegalArgumentException(msg);
        }

        this.wwd = wwd;
        this.shape = originalShape;
        this.originalAttributes = this.shape.getAttributes();

        this.controlPointLayer = new MarkerLayer();
        this.controlPointLayer.setKeepSeparated(false);
        this.controlPointLayer.setValue(AVKey.IGNORE, true);

        this.accessoryLayer = new RenderableLayer();
        this.accessoryLayer.setPickEnabled(false);
        this.accessoryLayer.setValue(AVKey.IGNORE, true);

        // Set up the Path for the rotation line.
        ShapeAttributes lineAttrs = new BasicShapeAttributes();
        lineAttrs.setOutlineMaterial(Material.GREEN);
        lineAttrs.setOutlineWidth(2);
        java.util.List<Position> lineLocations = new ArrayList<Position>(2);
        lineLocations.add(Position.ZERO);
        lineLocations.add(Position.ZERO);
        Path rotationLine = new Path(lineLocations);
        rotationLine.setFollowTerrain(true);
        rotationLine.setPathType(AVKey.GREAT_CIRCLE);
        rotationLine.setAltitudeMode(WorldWind.RELATIVE_TO_GROUND);
        rotationLine.setAttributes(lineAttrs);
        this.accessoryLayer.addRenderable(rotationLine);

        this.annotationLayer = new RenderableLayer();
        this.annotationLayer.setPickEnabled(false);
        this.annotationLayer.setValue(AVKey.IGNORE, true);

        this.annotation = new EditorAnnotation("");
        this.annotationLayer.addRenderable(this.annotation);

        this.shadowLayer = new RenderableLayer();
        this.shadowLayer.setPickEnabled(false);
        this.shadowLayer.setValue(AVKey.IGNORE, true);

        this.unitsFormat = new UnitsFormat();
        this.unitsFormat.setFormat(UnitsFormat.FORMAT_LENGTH, " %,12.3f %s");

        this.locationMarkerAttributes = new BasicMarkerAttributes(Material.BLUE, BasicMarkerShape.SPHERE, 0.7, 10, 0.1);
        this.sizeMarkerAttributes = new BasicMarkerAttributes(Material.CYAN, BasicMarkerShape.SPHERE, 0.7, 10, 0.1);
        this.angleMarkerAttributes = new BasicMarkerAttributes(Material.GREEN, BasicMarkerShape.SPHERE, 0.7, 10, 0.1);
    }

    /**
     * Indicates the units formatter associated with this editor.
     *
     * @return the units formatter associated with this editor.
     */
    public UnitsFormat getUnitsFormat()
    {
        return unitsFormat;
    }

    /**
     * Specifies the units formatter to use when creating editor annotations.
     *
     * @param unitsFormat the units formatter to use. A default is created if null is specified.
     */
    public void setUnitsFormat(UnitsFormat unitsFormat)
    {
        this.unitsFormat = unitsFormat != null ? unitsFormat : new UnitsFormat();
    }

    /**
     * Indicates the World Window associated with this editor.
     *
     * @return the World Window associated with this editor.
     */
    public WorldWindow getWwd()
    {
        return this.wwd;
    }

    /**
     * Indicates the shape associated with this editor.
     *
     * @return the shape associated with this editor.
     */
    public Airspace getShape()
    {
        return this.shape;
    }

    /**
     * Indicates whether this editor is armed.
     *
     * @return <code>true</code> if the editor is armed, otherwise <code>false</code>.
     */
    public boolean isArmed()
    {
        return this.armed;
    }

    /**
     * Arms or disarms the editor. When armed, the editor's shape is displayed with control points and other affordances
     * that indicate possible editing operations.
     *
     * @param armed <code>true</code> to arm the editor, <code>false</code> to disarm it and remove the control points
     *              and other affordances. This method must be called when the editor is no longer needed so that the
     *              editor may remove the resources it created when it was armed.
     */
    public void setArmed(boolean armed)
    {
        if (!this.armed && armed)
        {
            this.enable();
        }
        else if (this.armed && !armed)
        {
            this.disable();
        }

        this.armed = armed;
    }

    /**
     * Called by {@link #setArmed(boolean)} to create affordance resources, including the layers in which the
     * affordances are displayed.
     */
    protected void enable()
    {
        LayerList layers = this.wwd.getModel().getLayers();

        if (!layers.contains(this.controlPointLayer))
            layers.add(this.controlPointLayer);

        if (!this.controlPointLayer.isEnabled())
            this.controlPointLayer.setEnabled(true);

        if (!layers.contains(this.accessoryLayer))
            layers.add(this.accessoryLayer);

        if (!this.accessoryLayer.isEnabled())
            this.accessoryLayer.setEnabled(true);

        if (!layers.contains(this.annotationLayer))
            layers.add(this.annotationLayer);

        if (!layers.contains(this.shadowLayer))
            layers.add(0, this.shadowLayer);
        this.shadowLayer.setEnabled(true);

        if (this.shape instanceof TrackAirspace)
            this.determineTrackAdjacency();

        this.updateControlPoints();

        this.wwd.addSelectListener(this);
    }

    /**
     * Called by {@link #setArmed(boolean)} to destroy affordance resources, including the layers in which the
     * affordances are displayed.
     */
    protected void disable()
    {
        LayerList layers = this.wwd.getModel().getLayers();

        layers.remove(this.controlPointLayer);
        layers.remove(this.accessoryLayer);
        layers.remove(this.annotationLayer);
        layers.remove(this.shadowLayer);

        wwd.removeSelectListener(this);

        ((Component) this.wwd).setCursor(null);
    }

    /**
     * Determines and stores internally the adjacency of successive track legs. Called during editor arming.
     */
    protected void determineTrackAdjacency()
    {
        if (this.trackAdjacencyList == null)
            this.trackAdjacencyList = new ArrayList<Box>();
        else
            this.trackAdjacencyList.clear();

        TrackAirspace track = (TrackAirspace) this.shape;
        List<Box> legs = track.getLegs();
        for (int i = 1; i < legs.size(); i++)
        {
            boolean adjacent = track.mustJoinLegs(legs.get(i - 1), legs.get(i));
            if (adjacent)
                this.trackAdjacencyList.add(legs.get(i));
        }
    }

    public void selected(SelectEvent event)
    {
        if (event == null)
        {
            String msg = Logging.getMessage("nullValue.EventIsNull");
            Logging.logger().log(java.util.logging.Level.FINE, msg);
            throw new IllegalArgumentException(msg);
        }

        if (event.getEventAction().equals(SelectEvent.DRAG_END))
        {
            this.active = false;
            this.activeOperation = NONE;
            this.previousPosition = null;
            ((Component) this.wwd).setCursor(null);
            this.removeShadowShape();
            this.updateAnnotation(null);
        }
        else if (event.getEventAction().equals(SelectEvent.ROLLOVER))
        {
            if (!(this.wwd instanceof Component))
                return;

            // Update the cursor.
            Cursor cursor = null;
            if (this.activeOperation == MOVING)
                cursor = Cursor.getPredefinedCursor(Cursor.HAND_CURSOR);
            else if (this.activeOperation == SIZING)
                cursor = Cursor.getPredefinedCursor(Cursor.CROSSHAIR_CURSOR);
            else if (event.getTopObject() != null && event.getTopObject() == this.shape)
                cursor = Cursor.getPredefinedCursor(Cursor.HAND_CURSOR);
            else if (event.getTopObject() != null && event.getTopObject() instanceof Marker)
                cursor = Cursor.getPredefinedCursor(Cursor.CROSSHAIR_CURSOR);

            ((Component) this.wwd).setCursor(cursor);

            // Update the shape or control point annotation.
            if (this.activeOperation == MOVING && event.getTopObject() == this.shape)
                this.updateShapeAnnotation();
            else if (this.activeOperation == SIZING)
                this.updateAnnotation(this.currentSizingMarker);
            else if (event.getTopObject() != null && event.getTopObject() == this.shape)
                this.updateShapeAnnotation();
            else if (event.getTopObject() != null && event.getTopObject() instanceof ControlPointMarker)
                this.updateAnnotation((ControlPointMarker) event.getTopObject());
            else
                this.updateAnnotation(null);
        }
        else if (event.getEventAction().equals(SelectEvent.LEFT_PRESS))
        {
            this.active = true;
            PickedObjectList objectsUnderCursor = this.getWwd().getObjectsAtCurrentPosition();
            if (objectsUnderCursor != null)
            {
                PickedObject terrainObject = objectsUnderCursor.getTerrainObject();
                if (terrainObject != null)
                    this.previousPosition = terrainObject.getPosition();
            }
        }
        else if (event.getEventAction().equals(SelectEvent.DRAG))
        {
            if (!this.active)
                return;

            DragSelectEvent dragEvent = (DragSelectEvent) event;
            Object topObject = dragEvent.getTopObject();
            if (topObject == null)
                return;

            if (this.activeOperation == NONE) // drag is starting
                this.makeShadowShape();

            if (topObject == this.shape || this.activeOperation == MOVING)
            {
                this.activeOperation = MOVING;
                this.dragWholeShape(dragEvent);
                this.updateControlPoints();
                this.updateShapeAnnotation();
                event.consume();
            }
            else if (dragEvent.getTopPickedObject().getParentLayer() == this.controlPointLayer
                || this.activeOperation == SIZING)
            {
                this.activeOperation = SIZING;
                this.reshapeShape((ControlPointMarker) topObject);
                this.updateControlPoints();
                this.updateAnnotation(this.currentSizingMarker);
                event.consume();
            }

            this.wwd.redraw();
        }
    }

    /**
     * Creates the shape that will remain at the same location and is the same size as the shape to be edited.
     */
    protected void makeShadowShape()
    {
        Airspace shadowShape = this.doMakeShadowShape();
        if (shadowShape != null)
        {
            // Reduce the opacity of an opaque current shape so that the shadow shape is visible while editing
            // is performed.

            this.originalAttributes = this.shape.getAttributes();
            this.originalHighlightAttributes = this.shape.getHighlightAttributes();

            AirspaceAttributes editingHighlightAttributes = this.originalHighlightAttributes != null ?
                new BasicAirspaceAttributes(this.originalHighlightAttributes)
                : new BasicAirspaceAttributes(this.originalAttributes);
            if (editingHighlightAttributes.getInteriorOpacity() == 1)
                editingHighlightAttributes.setInteriorOpacity(0.7);

            this.shape.setAttributes(editingHighlightAttributes);
            this.shape.setHighlightAttributes(editingHighlightAttributes);

            this.shadowLayer.addRenderable(shadowShape);
        }
    }

    /**
     * Remove the shadow shape.
     */
    protected void removeShadowShape()
    {
        this.shadowLayer.removeAllRenderables();

        // Restore the original attributes.
        if (this.originalAttributes != null)
        {
            this.shape.setAttributes(this.originalAttributes);
            this.shape.setHighlightAttributes(this.originalHighlightAttributes);
        }
        this.originalAttributes = null;

        this.wwd.redraw();
    }

    /**
     * Creates and returns the stationary shape displayed during editing operations. Subclasses should override this
     * method to create shadow shapes appropriate to the editor's shape.
     *
     * @return the new shadow shape created, or null if the shape type is not recognized.
     */
    protected Airspace doMakeShadowShape()
    {
        if (this.shape instanceof Polygon)
            return new Polygon((Polygon) this.shape);
        else if (this.shape instanceof PartialCappedCylinder)
            return new PartialCappedCylinder((PartialCappedCylinder) this.shape);
        else if (this.shape instanceof CappedCylinder)
            return new CappedCylinder((CappedCylinder) this.shape);
        else if (this.shape instanceof Orbit)
            return new Orbit((Orbit) this.shape);
        else if (this.shape instanceof Route)
            return new Route((Route) this.shape);
        else if (this.shape instanceof Curtain)
            return new Curtain((Curtain) this.shape);
        else if (this.shape instanceof SphereAirspace)
            return new SphereAirspace((SphereAirspace) this.shape);
        else if (this.shape instanceof TrackAirspace)
            return new TrackAirspace((TrackAirspace) this.shape);

        return null;
    }

    /**
     * Performs shape-specific minor modifications to shapes after editing operation are performed. Some editing
     * operations cause positions that are originally identical to become slightly different and thereby disrupt the
     * original connectivity of the shape. This is the case for track-airspace legs, for instance. This method is called
     * just after editing operations are performed in order to give the editor a chance to reform connectivity or
     * otherwise modify the shape to retain its original properties. Subclasses should override this method if they are
     * aware of shapes other than those recognized by default and those shapes need such adjustment during editing.
     */
    protected void adjustShape()
    {
        if (this.shape instanceof TrackAirspace)
            this.adjustTrackShape();
    }

    /**
     * Restores adjacency of {@link gov.nasa.worldwind.render.airspaces.TrackAirspace} shapes. Called by {@link
     * #adjustShape()}.
     */
    protected void adjustTrackShape()
    {
        TrackAirspace track = (TrackAirspace) this.shape;

        List<Box> legs = track.getLegs();
        if (legs == null)
            return;

        // Start with the second leg and restore coincidence of the first leg position with that of the previous leg.
        for (int i = 1; i < legs.size(); i++)
        {
            Box leg = legs.get(i);

            if (this.trackAdjacencyList.contains(legs.get(i)))
            {
                leg.setLocations(legs.get(i - 1).getLocations()[1], leg.getLocations()[1]);
            }
        }
    }

    /**
     * Moves the entire shape according to a specified drag event.
     *
     * @param dragEvent the event initiating the move.
     */
    protected void dragWholeShape(DragSelectEvent dragEvent)
    {
        Movable2 dragObject = (Movable2) this.shape;

        View view = wwd.getView();
        Globe globe = wwd.getModel().getGlobe();

        // Compute ref-point position in screen coordinates.
        Position refPos = dragObject.getReferencePosition();
        if (refPos == null)
            return;

        Vec4 refPoint = globe.computePointFromPosition(refPos);
        Vec4 screenRefPoint = view.project(refPoint);

        // Compute screen-coord delta since last event.
        int dx = dragEvent.getPickPoint().x - dragEvent.getPreviousPickPoint().x;
        int dy = dragEvent.getPickPoint().y - dragEvent.getPreviousPickPoint().y;

        // Find intersection of screen coord ref-point with globe.
        double x = screenRefPoint.x + dx;
        double y = dragEvent.getMouseEvent().getComponent().getSize().height - screenRefPoint.y + dy - 1;
        Line ray = view.computeRayFromScreenPoint(x, y);
        Intersection inters[] = globe.intersect(ray, refPos.getElevation());

        if (inters != null)
        {
            // Intersection with globe. Move reference point to the intersection point.
            Position p = globe.computePositionFromPoint(inters[0].getIntersectionPoint());
            dragObject.moveTo(getWwd().getModel().getGlobe(), new Position(p, this.shape.getAltitudes()[0]));
        }

        this.adjustShape();
    }

    /**
     * Modifies the shape's location, size or rotation. This method is called when a control point is dragged.
     *
     * @param controlPoint the control point selected.
     */
    protected void reshapeShape(ControlPointMarker controlPoint)
    {
        this.currentSizingMarker = controlPoint;

        // If the terrain beneath the control point is null, then the user is attempting to drag the handle off the
        // globe. This is not a valid state for SurfaceImage, so we will ignore this action but keep the drag operation
        // in effect.
        PickedObjectList objectsUnderCursor = this.getWwd().getObjectsAtCurrentPosition();
        if (objectsUnderCursor == null)
            return;

        PickedObject terrainObject = this.wwd.getObjectsAtCurrentPosition().getTerrainObject();
        if (terrainObject == null)
            return;

        if (this.previousPosition == null)
        {
            this.previousPosition = terrainObject.getPosition();
            return;
        }

        this.doReshapeShape(controlPoint, terrainObject.getPosition());

        this.previousPosition = terrainObject.getPosition();

        this.adjustShape();
    }

    /**
     * Called by {@link #reshapeShape(gov.nasa.worldwind.util.AirspaceEditor.ControlPointMarker)} to perform the actual
     * shape modification. Subclasses should override this method if they provide editing for shapes other than those
     * supported by the basic editor.
     *
     * @param controlPoint    the control point selected.
     * @param terrainPosition the terrain position under the cursor.
     */
    protected void doReshapeShape(ControlPointMarker controlPoint, Position terrainPosition)
    {
        if (this.shape instanceof Polygon || this.shape instanceof Curtain)
            this.reshapePolygon(terrainPosition, controlPoint);
        else if (this.shape instanceof CappedCylinder)
            this.reshapeCappedCylinder(terrainPosition, controlPoint);
        else if (this.shape instanceof Orbit)
            this.reshapeOrbit(terrainPosition, controlPoint);
        else if (this.shape instanceof Route)
            this.reshapeRoute(terrainPosition, controlPoint);
        else if (this.shape instanceof SphereAirspace)
            this.reshapeSphere(terrainPosition, controlPoint);
        else if (this.shape instanceof TrackAirspace)
            this.reshapeTrack(terrainPosition, controlPoint);
    }

    /**
     * Updates the control points to the locations of the currently edited shape. Called each time a modification to the
     * shape is made. Subclasses should override this method to handle shape types not supported by the basic editor.
     */
    protected void updateControlPoints()
    {
        if (this.shape instanceof Polygon || this.shape instanceof Curtain)
            this.updatePolygonControlPoints();
        else if (this.shape instanceof PartialCappedCylinder)
            this.updatePartialCappedCylinderControlPoints();
        else if (this.shape instanceof CappedCylinder)
            this.updateCappedCylinderControlPoints();
        else if (this.shape instanceof Orbit)
            this.updateOrbitControlPoints();
        else if (this.shape instanceof Route)
            this.updateRouteControlPoints();
        else if (this.shape instanceof SphereAirspace)
            this.updateSphereControlPoints();
        else if (this.shape instanceof TrackAirspace)
            this.updateTrackControlPoints();
    }

    /**
     * Computes the appropriate altitude at which to place a control point at a specified location.
     *
     * @param location the location of the control point.
     *
     * @return the appropriate altitude at which to place the control point.
     */
    protected double computeControlPointAltitude(LatLon location)
    {
        double altitude = this.shape.getAltitudes()[1];

        if (this.shape.getAltitudeDatum()[1].equals(AVKey.ABOVE_GROUND_LEVEL))
        {
            LatLon refPos = this.shape.getGroundReference();
            if (refPos == null)
                refPos = location;
            altitude += getWwd().getModel().getGlobe().getElevation(refPos.getLatitude(), refPos.getLongitude());
        }

        return altitude;
    }

    /**
     * Updates the annotation indicating the edited shape's center. If the shape has no designated center, this method
     * prevents the annotation from displaying.
     */
    protected void updateShapeAnnotation()
    {
        LatLon center = this.getShapeCenter();

        if (center != null)
        {
            ControlPointMarker dummyMarker = new ControlPointMarker(new Position(center, 0),
                new BasicMarkerAttributes(), 0, ANNOTATION);
            this.updateAnnotation(dummyMarker);
        }
        else
        {
            this.updateAnnotation(null);
        }
    }

    /**
     * Returns the shape's center location, or null if it has no designated center.
     *
     * @return the shape's center location, or null if the shape has no designated center.
     */
    protected LatLon getShapeCenter()
    {
        LatLon center = null;

        if (this.shape instanceof CappedCylinder)
            center = ((CappedCylinder) this.shape).getCenter();
        else if (this.shape instanceof SphereAirspace)
            center = ((SphereAirspace) this.shape).getLocation();

        return center;
    }

    /**
     * Updates the annotation associated with a specified control point.
     *
     * @param controlPoint the control point.
     */
    protected void updateAnnotation(ControlPointMarker controlPoint)
    {
        if (controlPoint == null)
        {
            this.annotationLayer.setEnabled(false);
            return;
        }

        this.annotationLayer.setEnabled(true);
        this.annotation.setPosition(controlPoint.getPosition());

        String annotationText;
        if (controlPoint.size != null)
            annotationText = this.unitsFormat.length(null, controlPoint.size);
        else if (controlPoint.rotation != null)
            annotationText = this.unitsFormat.angle(null, controlPoint.rotation);
        else
            annotationText = this.unitsFormat.latLon2(controlPoint.getPosition());

        this.annotation.setText(annotationText);
    }

    /**
     * Updates the line designating the shape's central axis.
     *
     * @param centerPosition the shape's center location and altitude at which to place one of the line's end points.
     * @param controlPoint   the shape orientation control point.
     */
    protected void updateOrientationLine(Position centerPosition, Position controlPoint)
    {
        Path rotationLine = (Path) this.accessoryLayer.getRenderables().iterator().next();

        double cAltitude = centerPosition.getAltitude();
        double rAltitude = controlPoint.getAltitude();
        if (this.shape.getAltitudeDatum()[1].equals(AVKey.ABOVE_GROUND_LEVEL))
        {
            rotationLine.setAltitudeMode(WorldWind.RELATIVE_TO_GROUND);
            rotationLine.setFollowTerrain(true);

            cAltitude = 100 + centerPosition.getAltitude() - this.getWwd().getModel().getGlobe().getElevation(
                centerPosition.getLatitude(), centerPosition.getLongitude());
            rAltitude = 100 + controlPoint.getAltitude() - this.getWwd().getModel().getGlobe().getElevation(
                controlPoint.getLatitude(), controlPoint.getLongitude());
        }
        else
        {
            rotationLine.setAltitudeMode(WorldWind.ABSOLUTE);
            rotationLine.setFollowTerrain(false);
        }

        java.util.List<Position> linePositions = new ArrayList<Position>(2);
        linePositions.add(new Position(centerPosition, cAltitude));
        linePositions.add(new Position(controlPoint, rAltitude));
        rotationLine.setPositions(linePositions);
    }

    /**
     * Computes the Cartesian difference between two control points.
     *
     * @param previousLocation the location nof the previous control point.
     * @param currentLocation  the location of the current control point.
     *
     * @return the Cartesian difference between the two control points.
     */
    protected Vec4 computeControlPointDelta(LatLon previousLocation, LatLon currentLocation)
    {
        // Compute how much the specified control point moved.
        Vec4 terrainPoint = wwd.getModel().getGlobe().computeEllipsoidalPointFromLocation(currentLocation);
        Vec4 previousPoint = wwd.getModel().getGlobe().computeEllipsoidalPointFromLocation(previousLocation);

        return terrainPoint.subtract3(previousPoint);
    }

    /**
     * Add a specified increment to an angle and normalize the result to be between 0 and 360 degrees.
     *
     * @param originalHeading the base angle.
     * @param deltaHeading    the increment to add prior to normalizing.
     *
     * @return the normalized angle.
     */
    protected Angle normalizedHeading(Angle originalHeading, Angle deltaHeading)
    {
        final double twoPI = 2 * Math.PI;

        double newHeading = originalHeading.getRadians() + deltaHeading.getRadians();

        if (Math.abs(newHeading) > twoPI)
            newHeading = newHeading % twoPI;

        return Angle.fromRadians(newHeading >= 0 ? newHeading : newHeading + twoPI);
    }

    /**
     * Computes a control point location at the edge of a shape.
     *
     * @param center   the shape's center.
     * @param location a location that forms a line from the shape's center along the shape's axis. The returned
     *                 location is on the edge indicated by the cross product of a vector normal to the surface at the
     *                 specified center and a vector from the center to this location.
     * @param length   the distance of the edge from the shape's center.
     *
     * @return a location at the shape's edge at the same location along the shape's axis as the specified center
     * location.
     */
    protected Position computeEdgeLocation(LatLon center, LatLon location, double length)
    {
        Vec4 centerPoint = wwd.getModel().getGlobe().computeEllipsoidalPointFromLocation(center);
        Vec4 surfaceNormal = getWwd().getModel().getGlobe().computeEllipsoidalNormalAtLocation(
            center.getLatitude(), center.getLongitude());

        Vec4 point1 = getWwd().getModel().getGlobe().computeEllipsoidalPointFromLocation(location);
        Vec4 vecToLocation = point1.subtract3(centerPoint).normalize3();
        Vec4 vecToEdge = surfaceNormal.cross3(vecToLocation).normalize3().multiply3(length);

        LatLon edgeLocation = getWwd().getModel().getGlobe().computePositionFromEllipsoidalPoint(
            vecToEdge.add3(centerPoint));
        double edgeAltitude = this.computeControlPointAltitude(edgeLocation);

        return new Position(edgeLocation, edgeAltitude);
    }

    /**
     * Performs an edit for {@link gov.nasa.worldwind.render.airspaces.Polygon} shapes.
     *
     * @param controlPoint    the control point selected.
     * @param terrainPosition the terrain position under the cursor.
     */
    protected void reshapePolygon(Position terrainPosition, ControlPointMarker controlPoint)
    {
        Iterable<? extends LatLon> currentLocations = null;

        if (this.shape instanceof Polygon)
            currentLocations = ((Polygon) this.shape).getLocations();
        else if (this.shape instanceof Curtain)
            currentLocations = ((Curtain) this.shape).getLocations();

        if (currentLocations == null)
            return;

        // Assemble a local list of the polygon's locations.
        java.util.List<LatLon> locations = new ArrayList<LatLon>();
        for (LatLon location : currentLocations)
        {
            locations.add(location);
        }

        if (controlPoint.getPurpose().equals(ROTATION))
        {
            // Rotate the polygon.
            LatLon center = LatLon.getCenter(locations); // rotation axis
            Angle oldHeading = LatLon.greatCircleAzimuth(center, this.previousPosition);
            Angle deltaHeading = LatLon.greatCircleAzimuth(center, terrainPosition).subtract(oldHeading);
            this.currentHeading = this.normalizedHeading(this.currentHeading, deltaHeading);

            // Rotate the polygon's locations by the heading delta angle.
            for (int i = 0; i < locations.size(); i++)
            {
                LatLon location = locations.get(i);

                Angle heading = LatLon.greatCircleAzimuth(center, location);
                Angle distance = LatLon.greatCircleDistance(center, location);
                LatLon newLocation = LatLon.greatCircleEndPosition(center, heading.add(deltaHeading), distance);
                locations.set(i, newLocation);
            }
        }
        else // location change
        {
            // Compute the new location for the polygon location associated with the incoming control point.
            Vec4 delta = this.computeControlPointDelta(this.previousPosition, terrainPosition);
            Vec4 markerPoint = wwd.getModel().getGlobe().computeEllipsoidalPointFromLocation(
                new Position(controlPoint.getPosition(), 0));
            Position markerPosition = wwd.getModel().getGlobe().computePositionFromEllipsoidalPoint(
                markerPoint.add3(delta));

            // Update the polygon's locations.
            locations.set(controlPoint.getId(), markerPosition);
        }

        if (this.shape instanceof Polygon)
            ((Polygon) this.shape).setLocations(locations);
        else if (this.shape instanceof Curtain)
            ((Curtain) this.shape).setLocations(locations);
    }

    /**
     * Updates the control points and affordances for {@link gov.nasa.worldwind.render.airspaces.Polygon} shapes.
     */
    protected void updatePolygonControlPoints()
    {
        Iterable<? extends LatLon> currentLocations = null;

        if (this.shape instanceof Polygon)
            currentLocations = ((Polygon) this.shape).getLocations();
        else if (this.shape instanceof Curtain)
            currentLocations = ((Curtain) this.shape).getLocations();

        if (currentLocations == null)
            return;

        java.util.List<LatLon> locations = new ArrayList<LatLon>();
        for (LatLon location : currentLocations)
        {
            locations.add(location);
        }

        if (locations.size() < 2)
            return;

        LatLon polygonCenter = LatLon.getCenter(locations);
        double centerAltitude = this.computeControlPointAltitude(polygonCenter);
        Angle shapeRadius = LatLon.getAverageDistance(locations);
        Angle heading = this.currentHeading;
        LatLon rotationControlLocation = LatLon.greatCircleEndPosition(polygonCenter, heading, shapeRadius);
        double rotationControlAltitude = this.computeControlPointAltitude(rotationControlLocation);

        Iterable<Marker> markers = this.controlPointLayer.getMarkers();
        if (markers == null)
        {
            // Create control points for the polygon locations.
            ArrayList<Marker> controlPoints = new ArrayList<Marker>();
            int i = 0;
            for (LatLon location : locations)
            {
                double altitude = this.computeControlPointAltitude(location);
                Position cpPosition = new Position(location, altitude);
                controlPoints.add(new ControlPointMarker(cpPosition, this.locationMarkerAttributes, i++, LOCATION));
            }

            // Create a control point for the rotation control.
            Position cpPosition = new Position(rotationControlLocation, rotationControlAltitude);
            controlPoints.add(new ControlPointMarker(cpPosition, this.angleMarkerAttributes, i, ROTATION));

            this.controlPointLayer.setMarkers(controlPoints);
        }
        else
        {
            // Update the polygon's location control points.
            Iterator<Marker> markerIterator = markers.iterator();
            for (LatLon location : locations)
            {
                double altitude = this.computeControlPointAltitude(location);
                markerIterator.next().setPosition(new Position(location, altitude));
            }

            // Update the polygon's rotation control point.
            markerIterator.next().setPosition(new Position(rotationControlLocation, rotationControlAltitude));
        }

        // Update the heading annotation.
        Iterator<Marker> markerIterator = this.controlPointLayer.getMarkers().iterator();
        for (LatLon ignored : locations)
        {
            markerIterator.next();
        }
        ((ControlPointMarker) markerIterator.next()).rotation = heading;

        // Update the rotation orientation line.
        this.updateOrientationLine(new Position(polygonCenter, centerAltitude),
            new Position(rotationControlLocation, rotationControlAltitude));
    }

    /**
     * Performs an edit for {@link gov.nasa.worldwind.render.airspaces.CappedCylinder} shapes.
     *
     * @param controlPoint    the control point selected.
     * @param terrainPosition the terrain position under the cursor.
     */
    protected void reshapeCappedCylinder(Position terrainPosition, ControlPointMarker controlPoint)
    {
        CappedCylinder cylinder = (CappedCylinder) this.shape;
        double[] radii = cylinder.getRadii();

        Vec4 centerPoint = wwd.getModel().getGlobe().computeEllipsoidalPointFromLocation(cylinder.getCenter());
        Vec4 markerPoint = wwd.getModel().getGlobe().computeEllipsoidalPointFromLocation(controlPoint.getPosition());
        Vec4 vMarker = markerPoint.subtract3(centerPoint).normalize3();

        Vec4 delta = this.computeControlPointDelta(this.previousPosition, terrainPosition);
        if (controlPoint.getPurpose().equals(OUTER_RADIUS))
            radii[1] += delta.dot3(vMarker);
        else if (controlPoint.getPurpose().equals(INNER_RADIUS))
            radii[0] += delta.dot3(vMarker);

        if (radii[0] >= 0 && radii[1] > 0 && radii[0] < radii[1])
            cylinder.setRadii(radii[0], radii[1]);

        if (this.shape instanceof PartialCappedCylinder)
        {
            Angle oldHeading = LatLon.greatCircleAzimuth(cylinder.getCenter(), this.previousPosition);
            Angle deltaHeading = LatLon.greatCircleAzimuth(cylinder.getCenter(), terrainPosition).subtract(oldHeading);

            Angle[] azimuths = ((PartialCappedCylinder) cylinder).getAzimuths();
            if (controlPoint.getPurpose().equals(LEFT_AZIMUTH))
                azimuths[0] = this.normalizedHeading(azimuths[0], deltaHeading);
            else if (controlPoint.getPurpose().equals(RIGHT_AZIMUTH))
                azimuths[1] = this.normalizedHeading(azimuths[1], deltaHeading);
            else if (controlPoint.getPurpose().equals(ROTATION))
            {
                this.currentHeading = this.normalizedHeading(this.currentHeading, deltaHeading);
                azimuths[0] = this.normalizedHeading(azimuths[0], deltaHeading);
                azimuths[1] = this.normalizedHeading(azimuths[1], deltaHeading);
            }

            ((PartialCappedCylinder) cylinder).setAzimuths(azimuths[0], azimuths[1]);
        }
    }

    /**
     * Updates the control points and affordances for {@link gov.nasa.worldwind.render.airspaces.CappedCylinder}
     * shapes.
     */
    protected void updateCappedCylinderControlPoints()
    {
        CappedCylinder cylinder = (CappedCylinder) this.shape;
        double[] radii = cylinder.getRadii();
        boolean hasInnerRadius = radii[0] > 0;

        LatLon outerRadiusLocation = LatLon.greatCircleEndPosition(cylinder.getCenter(), Angle.fromDegrees(90),
            Angle.fromRadians(radii[1] / this.wwd.getModel().getGlobe().getEquatorialRadius()));
        LatLon innerRadiusLocation = LatLon.greatCircleEndPosition(cylinder.getCenter(), Angle.fromDegrees(90),
            Angle.fromRadians(radii[0] / this.wwd.getModel().getGlobe().getEquatorialRadius()));

        double outerRadiusAltitude = this.computeControlPointAltitude(outerRadiusLocation);
        double innerRadiusAltitude = this.computeControlPointAltitude(innerRadiusLocation);

        Iterable<Marker> markers = this.controlPointLayer.getMarkers();
        if (markers == null)
        {
            java.util.List<Marker> markerList = new ArrayList<Marker>(1);
            Position cpPosition = new Position(outerRadiusLocation, outerRadiusAltitude);
            markerList.add(new ControlPointMarker(cpPosition, this.sizeMarkerAttributes, 0, OUTER_RADIUS));
            if (hasInnerRadius)
            {
                cpPosition = new Position(innerRadiusLocation, innerRadiusAltitude);
                markerList.add(new ControlPointMarker(cpPosition, this.sizeMarkerAttributes, 1, INNER_RADIUS));
            }
            this.controlPointLayer.setMarkers(markerList);
        }
        else
        {
            Iterator<Marker> markerIterator = markers.iterator();
            markerIterator.next().setPosition(new Position(outerRadiusLocation, outerRadiusAltitude));
            if (hasInnerRadius)
                markerIterator.next().setPosition(new Position(innerRadiusLocation, innerRadiusAltitude));
        }

        Iterator<Marker> markerIterator = this.controlPointLayer.getMarkers().iterator();
        ((ControlPointMarker) markerIterator.next()).size = radii[1];
        if (hasInnerRadius)
            ((ControlPointMarker) markerIterator.next()).size = radii[0];
    }

    /**
     * Updates the control points and affordances for {@link gov.nasa.worldwind.render.airspaces.PartialCappedCylinder}
     * shapes.
     */
    protected void updatePartialCappedCylinderControlPoints()
    {
        PartialCappedCylinder cylinder = (PartialCappedCylinder) this.shape;

        double[] radii = cylinder.getRadii();
        boolean hasInnerRadius = radii[0] > 0;
        double averageRadius = 0.5 * (radii[0] + radii[1]);

        Angle[] azimuths = cylinder.getAzimuths();

        LatLon outerRadiusLocation = LatLon.greatCircleEndPosition(cylinder.getCenter(), azimuths[1],
            Angle.fromRadians(radii[1] / this.wwd.getModel().getGlobe().getEquatorialRadius()));
        LatLon innerRadiusLocation = LatLon.greatCircleEndPosition(cylinder.getCenter(), azimuths[1],
            Angle.fromRadians(radii[0] / this.wwd.getModel().getGlobe().getEquatorialRadius()));

        LatLon leftAzimuthLocation = LatLon.greatCircleEndPosition(cylinder.getCenter(), azimuths[0],
            Angle.fromRadians(averageRadius / this.wwd.getModel().getGlobe().getEquatorialRadius()));
        LatLon rightAzimuthLocation = LatLon.greatCircleEndPosition(cylinder.getCenter(), azimuths[1],
            Angle.fromRadians(averageRadius / this.wwd.getModel().getGlobe().getEquatorialRadius()));

        double outerRadiusAltitude = this.computeControlPointAltitude(outerRadiusLocation);
        double innerRadiusAltitude = this.computeControlPointAltitude(innerRadiusLocation);
        double rightAzimuthAltitude = this.computeControlPointAltitude(rightAzimuthLocation);
        double leftAzimuthAltitude = this.computeControlPointAltitude(leftAzimuthLocation);

        LatLon rotationControlLocation = LatLon.greatCircleEndPosition(cylinder.getCenter(), this.currentHeading,
            Angle.fromRadians(1.2 * radii[1] / this.wwd.getModel().getGlobe().getEquatorialRadius()));
        double rotationControlAltitude = this.computeControlPointAltitude(rotationControlLocation);

        Iterable<Marker> markers = this.controlPointLayer.getMarkers();
        if (markers == null)
        {
            java.util.List<Marker> markerList = new ArrayList<Marker>(1);
            Position cpPosition = new Position(outerRadiusLocation, outerRadiusAltitude);
            markerList.add(new ControlPointMarker(cpPosition, this.sizeMarkerAttributes, 0, OUTER_RADIUS));
            if (hasInnerRadius)
            {
                cpPosition = new Position(innerRadiusLocation, innerRadiusAltitude);
                markerList.add(
                    new ControlPointMarker(cpPosition, this.sizeMarkerAttributes, 1, INNER_RADIUS));
            }

            cpPosition = new Position(leftAzimuthLocation, leftAzimuthAltitude);
            markerList.add(
                new ControlPointMarker(cpPosition, this.angleMarkerAttributes, 2, LEFT_AZIMUTH));
            cpPosition = new Position(rightAzimuthLocation, rightAzimuthAltitude);
            markerList.add(
                new ControlPointMarker(cpPosition, this.angleMarkerAttributes, 3, RIGHT_AZIMUTH));

            cpPosition = new Position(rotationControlLocation, rotationControlAltitude);
            markerList.add(new ControlPointMarker(cpPosition, this.angleMarkerAttributes, 4, ROTATION));

            this.controlPointLayer.setMarkers(markerList);
        }
        else
        {
            Iterator<Marker> markerIterator = markers.iterator();
            markerIterator.next().setPosition(new Position(outerRadiusLocation, outerRadiusAltitude));
            if (hasInnerRadius)
                markerIterator.next().setPosition(new Position(innerRadiusLocation, rightAzimuthAltitude));
            markerIterator.next().setPosition(new Position(leftAzimuthLocation, leftAzimuthAltitude));
            markerIterator.next().setPosition(new Position(rightAzimuthLocation, rightAzimuthAltitude));

            markerIterator.next().setPosition(new Position(rotationControlLocation, rotationControlAltitude));
        }

        Iterator<Marker> markerIterator = this.controlPointLayer.getMarkers().iterator();
        ((ControlPointMarker) markerIterator.next()).size = radii[1];
        if (hasInnerRadius)
            ((ControlPointMarker) markerIterator.next()).size = radii[0];

        ((ControlPointMarker) markerIterator.next()).rotation = azimuths[0];
        ((ControlPointMarker) markerIterator.next()).rotation = azimuths[1];

        ((ControlPointMarker) markerIterator.next()).rotation = this.currentHeading;

        // Update the rotation orientation line.
        double centerAltitude = this.computeControlPointAltitude(cylinder.getCenter());
        this.updateOrientationLine(new Position(cylinder.getCenter(), centerAltitude),
            new Position(rotationControlLocation, rotationControlAltitude));
    }

    /**
     * Performs an edit for {@link gov.nasa.worldwind.render.airspaces.SphereAirspace} shapes.
     *
     * @param controlPoint    the control point selected.
     * @param terrainPosition the terrain position under the cursor.
     */
    protected void reshapeSphere(Position terrainPosition, ControlPointMarker controlPoint)
    {
        SphereAirspace sphere = (SphereAirspace) this.shape;
        double radius = sphere.getRadius();

        Vec4 centerPoint = wwd.getModel().getGlobe().computeEllipsoidalPointFromLocation(sphere.getLocation());
        Vec4 markerPoint = wwd.getModel().getGlobe().computeEllipsoidalPointFromLocation(controlPoint.getPosition());
        Vec4 vMarker = markerPoint.subtract3(centerPoint).normalize3();

        Vec4 delta = this.computeControlPointDelta(this.previousPosition, terrainPosition);
        if (controlPoint.getPurpose().equals(OUTER_RADIUS))
            radius += delta.dot3(vMarker);

        if (radius > 0)
            sphere.setRadius(radius);
    }

    /**
     * Updates the control points and affordances for {@link gov.nasa.worldwind.render.airspaces.SphereAirspace}
     * shapes.
     */
    protected void updateSphereControlPoints()
    {
        SphereAirspace sphere = (SphereAirspace) this.shape;
        double radius = sphere.getRadius();

        LatLon radiusLocation = LatLon.greatCircleEndPosition(sphere.getLocation(), Angle.fromDegrees(90),
            Angle.fromRadians(radius / this.wwd.getModel().getGlobe().getEquatorialRadius()));

        double radiusAltitude = this.computeControlPointAltitude(radiusLocation);

        Iterable<Marker> markers = this.controlPointLayer.getMarkers();
        if (markers == null)
        {
            java.util.List<Marker> markerList = new ArrayList<Marker>(1);
            Position cpPosition = new Position(radiusLocation, radiusAltitude);
            markerList.add(new ControlPointMarker(cpPosition, this.sizeMarkerAttributes, 0, OUTER_RADIUS));
            this.controlPointLayer.setMarkers(markerList);
        }
        else
        {
            Iterator<Marker> markerIterator = markers.iterator();
            markerIterator.next().setPosition(new Position(radiusLocation, radiusAltitude));
        }

        Iterator<Marker> markerIterator = this.controlPointLayer.getMarkers().iterator();
        ((ControlPointMarker) markerIterator.next()).size = radius;
    }

    /**
     * Performs an edit for {@link gov.nasa.worldwind.render.airspaces.Orbit} shapes.
     *
     * @param controlPoint    the control point selected.
     * @param terrainPosition the terrain position under the cursor.
     */
    protected void reshapeOrbit(Position terrainPosition, ControlPointMarker controlPoint)
    {
        Orbit orbit = (Orbit) this.shape;
        LatLon[] locations = orbit.getLocations();
        double width = orbit.getWidth();

        LatLon center = LatLon.interpolateGreatCircle(0.5, locations[0], locations[1]);
        Vec4 centerPoint = wwd.getModel().getGlobe().computeEllipsoidalPointFromLocation(center);

        Vec4 markerPoint = wwd.getModel().getGlobe().computeEllipsoidalPointFromLocation(
            new Position(controlPoint.getPosition(), 0));

        if (controlPoint.getPurpose().equals(RIGHT_WIDTH))
        {
            Vec4 delta = this.computeControlPointDelta(this.previousPosition, terrainPosition);
            Vec4 vMarker = markerPoint.subtract3(centerPoint).normalize3();
            orbit.setWidth(width + delta.dot3(vMarker));
        }
        else if (controlPoint.getPurpose().equals(ROTATION))
        {
            Angle oldHeading = LatLon.greatCircleAzimuth(center, this.previousPosition);
            Angle deltaHeading = LatLon.greatCircleAzimuth(center, terrainPosition).subtract(oldHeading);

            for (int i = 0; i < 2; i++)
            {
                Angle heading = LatLon.greatCircleAzimuth(center, locations[i]);
                Angle distance = LatLon.greatCircleDistance(center, locations[i]);
                locations[i] = LatLon.greatCircleEndPosition(center, heading.add(deltaHeading), distance);
            }
            orbit.setLocations(locations[0], locations[1]);
        }
        else // location change
        {
            Vec4 delta = this.computeControlPointDelta(this.previousPosition, terrainPosition);
            Position markerPosition = wwd.getModel().getGlobe().computePositionFromEllipsoidalPoint(
                markerPoint.add3(delta));
            locations[controlPoint.getId()] = markerPosition;
            orbit.setLocations(locations[0], locations[1]);
        }
    }

    /**
     * Updates the control points and affordances for {@link gov.nasa.worldwind.render.airspaces.Orbit} shapes.
     */
    protected void updateOrbitControlPoints()
    {
        Orbit orbit = (Orbit) this.shape;
        LatLon[] locations = orbit.getLocations();
        double width = orbit.getWidth();

        double location0Altitude = this.computeControlPointAltitude(locations[0]);
        double location1Altitude = this.computeControlPointAltitude(locations[1]);

        Angle orbitHeading = LatLon.greatCircleAzimuth(locations[0], locations[1]);

        LatLon center = LatLon.interpolateGreatCircle(0.5, locations[0], locations[1]);
        double centerAltitude = this.computeControlPointAltitude(center);
        Position widthPosition = this.computeEdgeLocation(center, locations[0], 0.5 * orbit.getWidth());

        Angle distance = LatLon.greatCircleDistance(center, locations[0]);
        LatLon rotationControlLocation = LatLon.greatCircleEndPosition(center, Angle.fromDegrees(orbitHeading.degrees),
            Angle.fromRadians(distance.radians + 1.2 * width / this.wwd.getModel().getGlobe().getEquatorialRadius()));
        double rotationControlAltitude = this.computeControlPointAltitude(rotationControlLocation);

        Iterable<Marker> markers = this.controlPointLayer.getMarkers();
        if (markers == null)
        {
            java.util.List<Marker> markerList = new ArrayList<Marker>(1);
            Position cpPosition = new Position(locations[0], location0Altitude);
            markerList.add(new ControlPointMarker(cpPosition, this.locationMarkerAttributes, 0, LOCATION));
            cpPosition = new Position(locations[1], location1Altitude);
            markerList.add(new ControlPointMarker(cpPosition, this.locationMarkerAttributes, 1, LOCATION));

            cpPosition = new Position(widthPosition, widthPosition.getAltitude());
            markerList.add(new ControlPointMarker(cpPosition, this.sizeMarkerAttributes, 2, RIGHT_WIDTH));

            cpPosition = new Position(rotationControlLocation, rotationControlAltitude);
            markerList.add(new ControlPointMarker(cpPosition, this.angleMarkerAttributes, 3, ROTATION));

            this.controlPointLayer.setMarkers(markerList);
        }
        else
        {
            Iterator<Marker> markerIterator = markers.iterator();
            markerIterator.next().setPosition(new Position(locations[0], location0Altitude));
            markerIterator.next().setPosition(new Position(locations[1], location1Altitude));
            markerIterator.next().setPosition(new Position(widthPosition, widthPosition.getAltitude()));
            markerIterator.next().setPosition(new Position(rotationControlLocation, rotationControlAltitude));
        }

        Iterator<Marker> markerIterator = this.controlPointLayer.getMarkers().iterator();
        markerIterator.next();
        markerIterator.next();
        ((ControlPointMarker) markerIterator.next()).size = width;
        ((ControlPointMarker) markerIterator.next()).rotation = this.normalizedHeading(orbitHeading, Angle.ZERO);

        this.updateOrientationLine(new Position(center, centerAltitude),
            new Position(rotationControlLocation, rotationControlAltitude));
    }

    /**
     * Performs an edit for {@link gov.nasa.worldwind.render.airspaces.Route} shapes.
     *
     * @param controlPoint    the control point selected.
     * @param terrainPosition the terrain position under the cursor.
     */
    protected void reshapeRoute(Position terrainPosition, ControlPointMarker controlPoint)
    {
        Route route = (Route) this.shape;

        java.util.List<LatLon> locations = new ArrayList<LatLon>();
        for (LatLon ll : route.getLocations())
        {
            locations.add(ll);
        }

        if (controlPoint.getPurpose().equals(ROTATION))
        {
            LatLon center = LatLon.getCenter(locations);
            Angle oldHeading = LatLon.greatCircleAzimuth(center, this.previousPosition);
            Angle deltaHeading = LatLon.greatCircleAzimuth(center, terrainPosition).subtract(oldHeading);
            this.currentHeading = this.normalizedHeading(this.currentHeading, deltaHeading);

            for (int i = 0; i < locations.size(); i++)
            {
                LatLon location = locations.get(i);

                Angle heading = LatLon.greatCircleAzimuth(center, location);
                Angle distance = LatLon.greatCircleDistance(center, location);
                LatLon newLocation = LatLon.greatCircleEndPosition(center, heading.add(deltaHeading), distance);
                locations.set(i, newLocation);
            }
            route.setLocations(locations);
        }
        else if (controlPoint.getPurpose().equals(LEFT_WIDTH) || controlPoint.getPurpose().equals(RIGHT_WIDTH))
        {
            LatLon legCenter = LatLon.interpolateGreatCircle(0.5, locations.get(0), locations.get(1));
            Vec4 centerPoint = wwd.getModel().getGlobe().computeEllipsoidalPointFromLocation(legCenter);
            Vec4 markerPoint = wwd.getModel().getGlobe().computeEllipsoidalPointFromLocation(
                new Position(controlPoint.getPosition(), 0));
            Vec4 vMarker = markerPoint.subtract3(centerPoint).normalize3();
            Vec4 delta = this.computeControlPointDelta(this.previousPosition, terrainPosition);
            route.setWidth(route.getWidth() + delta.dot3(vMarker));
        }
        else // location change
        {
            Vec4 delta = this.computeControlPointDelta(this.previousPosition, terrainPosition);
            Vec4 markerPoint = wwd.getModel().getGlobe().computeEllipsoidalPointFromLocation(
                new Position(controlPoint.getPosition(), 0));
            Position markerPosition = wwd.getModel().getGlobe().computePositionFromEllipsoidalPoint(
                markerPoint.add3(delta));

            locations.set(controlPoint.getId(), markerPosition);
            route.setLocations(locations);
        }
    }

    /**
     * Updates the control points and affordances for {@link gov.nasa.worldwind.render.airspaces.Route} shapes.
     */
    protected void updateRouteControlPoints()
    {
        Route route = (Route) this.shape;

        if (route.getLocations() == null)
            return;

        java.util.List<LatLon> locations = new ArrayList<LatLon>();
        for (LatLon location : route.getLocations())
        {
            locations.add(location);
        }

        if (locations.size() < 2)
            return;

        LatLon legCenter = LatLon.interpolateGreatCircle(0.5, locations.get(0), locations.get(1));
        Position leftWidthPosition = this.computeEdgeLocation(legCenter, locations.get(1), 0.5 * route.getWidth());
        Position rightWidthPosition = this.computeEdgeLocation(legCenter, locations.get(0), 0.5 * route.getWidth());

        LatLon center = LatLon.getCenter(locations);
        double centerAltitude = this.computeControlPointAltitude(center);
        Angle averageDistance = LatLon.getAverageDistance(locations);
        LatLon rotationLocation = LatLon.greatCircleEndPosition(center, this.currentHeading, averageDistance);
        double rotationAltitude = this.computeControlPointAltitude(rotationLocation);

        Iterable<Marker> markers = this.controlPointLayer.getMarkers();
        if (markers == null)
        {
            ArrayList<Marker> controlPoints = new ArrayList<Marker>();
            int i = 0;
            for (LatLon cpPosition : locations)
            {
                double altitude = this.computeControlPointAltitude(cpPosition);
                Position position = new Position(cpPosition, altitude);
                controlPoints.add(new ControlPointMarker(position, this.locationMarkerAttributes, i++, LOCATION));
            }

            Position position = new Position(leftWidthPosition, leftWidthPosition.getAltitude());
            controlPoints.add(new ControlPointMarker(position, this.sizeMarkerAttributes, i++, RIGHT_WIDTH));
            position = new Position(rightWidthPosition, rightWidthPosition.getAltitude());
            controlPoints.add(new ControlPointMarker(position, this.sizeMarkerAttributes, i++, LEFT_WIDTH));

            position = new Position(rotationLocation, rotationAltitude);
            controlPoints.add(new ControlPointMarker(position, this.angleMarkerAttributes, i, ROTATION));

            this.controlPointLayer.setMarkers(controlPoints);
        }
        else
        {
            Iterator<Marker> markerIterator = markers.iterator();
            for (LatLon cpPosition : locations)
            {
                double altitude = this.computeControlPointAltitude(cpPosition);
                markerIterator.next().setPosition(new Position(cpPosition, altitude));
            }

            markerIterator.next().setPosition(new Position(leftWidthPosition, leftWidthPosition.getAltitude()));
            markerIterator.next().setPosition(new Position(rightWidthPosition, rightWidthPosition.getAltitude()));
            markerIterator.next().setPosition(new Position(rotationLocation, rotationAltitude));
        }

        Iterator<Marker> markerIterator = this.controlPointLayer.getMarkers().iterator();
        for (LatLon ignored : locations) // skip over the locations to get to the width and rotation control points
        {
            markerIterator.next();
        }
        ((ControlPointMarker) markerIterator.next()).size = route.getWidth();
        ((ControlPointMarker) markerIterator.next()).size = route.getWidth();
        ((ControlPointMarker) markerIterator.next()).rotation = this.currentHeading;

        this.updateOrientationLine(new Position(center, centerAltitude),
            new Position(rotationLocation, rotationAltitude));
    }

    /**
     * Performs an edit for {@link gov.nasa.worldwind.render.airspaces.TrackAirspace} shapes.
     *
     * @param controlPoint    the control point selected.
     * @param terrainPosition the terrain position under the cursor.
     */
    protected void reshapeTrack(Position terrainPosition, ControlPointMarker controlPoint)
    {
        TrackAirspace track = (TrackAirspace) this.shape;
        List<Box> legs = track.getLegs();

        if (controlPoint.getPurpose().equals(ROTATION))
        {
            List<LatLon> trackLocations = new ArrayList<LatLon>();
            for (Box leg : legs)
            {
                trackLocations.add(leg.getLocations()[0]);
                trackLocations.add(leg.getLocations()[1]);
            }
            LatLon center = LatLon.getCenter(trackLocations);
            Angle oldHeading = LatLon.greatCircleAzimuth(center, this.previousPosition);
            Angle deltaHeading = LatLon.greatCircleAzimuth(center, terrainPosition).subtract(oldHeading);
            this.currentHeading = this.normalizedHeading(this.currentHeading, deltaHeading);

            // Rotate all the legs.
            for (Box leg : legs)
            {
                LatLon[] locations = leg.getLocations();

                Angle heading = LatLon.greatCircleAzimuth(center, locations[0]);
                Angle distance = LatLon.greatCircleDistance(center, locations[0]);
                locations[0] = LatLon.greatCircleEndPosition(center, heading.add(deltaHeading), distance);

                heading = LatLon.greatCircleAzimuth(center, locations[1]);
                distance = LatLon.greatCircleDistance(center, locations[1]);
                locations[1] = LatLon.greatCircleEndPosition(center, heading.add(deltaHeading), distance);

                leg.setLocations(locations[0], locations[1]);
            }
        }
        else if (controlPoint.getPurpose().equals(LEFT_WIDTH) || controlPoint.getPurpose().equals(RIGHT_WIDTH))
        {
            Box leg = legs.get(controlPoint.getLeg());
            LatLon[] legLocations = leg.getLocations();

            LatLon legCenter = LatLon.interpolateGreatCircle(0.5, legLocations[0], legLocations[1]);
            Vec4 centerPoint = wwd.getModel().getGlobe().computeEllipsoidalPointFromLocation(legCenter);
            Vec4 markerPoint = wwd.getModel().getGlobe().computeEllipsoidalPointFromLocation(
                new Position(controlPoint.getPosition(), 0));
            Vec4 vMarker = markerPoint.subtract3(centerPoint).normalize3();

            double[] widths = leg.getWidths();
            double[] newWidths = new double[] {widths[0], widths[1]};
            Vec4 delta = this.computeControlPointDelta(this.previousPosition, terrainPosition);
            if (controlPoint.getPurpose().equals(LEFT_WIDTH))
                newWidths[0] += delta.dot3(vMarker);
            else
                newWidths[1] += delta.dot3(vMarker);

            if (newWidths[0] >= 0 && newWidths[1] >= 0)
            {
                leg.setWidths(newWidths[0], newWidths[1]);

                for (int i = controlPoint.getLeg() + 1; i < legs.size(); i++)
                {
                    if (this.trackAdjacencyList.contains(legs.get(i)))
                        legs.get(i).setWidths(newWidths[0], newWidths[1]);
                    else
                        break;
                }
            }
        }
        else
        {
            Vec4 delta = this.computeControlPointDelta(this.previousPosition, terrainPosition);
            Vec4 markerPoint = wwd.getModel().getGlobe().computeEllipsoidalPointFromLocation(
                new Position(controlPoint.getPosition(), 0));
            Position markerPosition = wwd.getModel().getGlobe().computePositionFromEllipsoidalPoint(
                markerPoint.add3(delta));

            Box leg = track.getLegs().get(controlPoint.getLeg());
            if (controlPoint.getId() == 0)
                leg.setLocations(markerPosition, leg.getLocations()[1]);
            else
                leg.setLocations(leg.getLocations()[0], markerPosition);
        }

        track.setLegs(new ArrayList<Box>(track.getLegs()));
    }

    /**
     * Updates the control points and affordances for {@link gov.nasa.worldwind.render.airspaces.TrackAirspace} shapes.
     */
    protected void updateTrackControlPoints()
    {
        TrackAirspace track = (TrackAirspace) this.shape;

        List<Box> legs = track.getLegs();
        if (legs == null)
            return;

        // Update the location control points.
        ArrayList<Marker> controlPoints = new ArrayList<Marker>();
        Iterable<Marker> markers = this.controlPointLayer.getMarkers();
        Iterator<Marker> markerIterator = markers != null ? markers.iterator() : null;
        for (int i = 0; i < legs.size(); i++)
        {
            Box leg = legs.get(i);
            LatLon[] legLocations = leg.getLocations();

            double altitude;

            if (markers == null)
            {
                if (!this.trackAdjacencyList.contains(leg))
                {
                    altitude = this.computeControlPointAltitude(legLocations[0]);
                    ControlPointMarker cp = new ControlPointMarker(new Position(legLocations[0], altitude),
                        this.locationMarkerAttributes, 0, i, LOCATION);
                    controlPoints.add(cp);
                }

                altitude = this.computeControlPointAltitude(legLocations[1]);
                ControlPointMarker cp = new ControlPointMarker(new Position(legLocations[1], altitude),
                    this.locationMarkerAttributes, 1, i, LOCATION);
                controlPoints.add(cp);
            }
            else
            {
                if (!this.trackAdjacencyList.contains(leg))
                {
                    altitude = this.computeControlPointAltitude(legLocations[0]);
                    markerIterator.next().setPosition(new Position(legLocations[0], altitude));
                }

                altitude = this.computeControlPointAltitude(legLocations[1]);
                markerIterator.next().setPosition(new Position(legLocations[1], altitude));
            }
        }

        // Update the width control points.
        for (int i = 0; i < legs.size(); i++)
        {
            Box leg = legs.get(i);
            if (!this.trackAdjacencyList.contains(leg))
            {
                LatLon[] legLocations = leg.getLocations();
                double[] widths = leg.getWidths();

                LatLon legCenter = LatLon.interpolateGreatCircle(0.5, legLocations[0], legLocations[1]);
                Position cwLPosition = this.computeEdgeLocation(legCenter, legLocations[1], widths[0]);
                Position cwRPosition = this.computeEdgeLocation(legCenter, legLocations[0], widths[1]);

                if (markers == null)
                {
                    Position cpPosition = new Position(cwLPosition, cwLPosition.getAltitude());
                    controlPoints.add(new ControlPointMarker(cpPosition, this.sizeMarkerAttributes, 2, i, LEFT_WIDTH));
                    cpPosition = new Position(cwRPosition, cwRPosition.getAltitude());
                    controlPoints.add(new ControlPointMarker(cpPosition, this.sizeMarkerAttributes, 3, i, RIGHT_WIDTH));
                }
                else
                {
                    //noinspection ConstantConditions
                    markerIterator.next().setPosition(new Position(cwLPosition, cwLPosition.getAltitude()));
                    markerIterator.next().setPosition(new Position(cwRPosition, cwRPosition.getAltitude()));
                }
            }
        }

        // Update the rotation control points.
        List<LatLon> trackLocations = new ArrayList<LatLon>();
        for (Box leg : legs)
        {
            trackLocations.add(leg.getLocations()[0]);
            trackLocations.add(leg.getLocations()[1]);
        }
        LatLon trackCenter = LatLon.getCenter(trackLocations);
        double trackCenterAltitude = this.computeControlPointAltitude(trackCenter);
        Angle trackRadius = LatLon.getAverageDistance(trackLocations);

        LatLon rotationLocation = LatLon.greatCircleEndPosition(trackCenter, this.currentHeading, trackRadius);
        double rotationAltitude = this.computeControlPointAltitude(rotationLocation);
        if (markers == null)
        {
            Position cpPosition = new Position(rotationLocation, rotationAltitude);
            controlPoints.add(new ControlPointMarker(cpPosition, this.angleMarkerAttributes, 4, ROTATION));
        }
        else
        {
            //noinspection ConstantConditions
            markerIterator.next().setPosition(new Position(rotationLocation, rotationAltitude));
        }

        if (markers == null)
            this.controlPointLayer.setMarkers(controlPoints);

        this.updateOrientationLine(new Position(trackCenter, trackCenterAltitude),
            new Position(rotationLocation, rotationAltitude));

        markers = this.controlPointLayer.getMarkers();
        for (Marker marker : markers)
        {
            ControlPointMarker cp = (ControlPointMarker) marker;

            if (cp.getId() == 2)
                cp.size = legs.get(cp.getLeg()).getWidths()[0];
            else if (cp.getId() == 3)
                cp.size = legs.get(cp.getLeg()).getWidths()[1];
            else if (cp.getId() == 4)
            {
                cp.rotation = this.currentHeading;
            }
        }
    }
}
