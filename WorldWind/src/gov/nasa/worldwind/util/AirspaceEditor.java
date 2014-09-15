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
import gov.nasa.worldwind.pick.PickedObject;
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
    protected String ANNOTATION = "gov.nasa.worldwind.airspaceditor.Annotation";
    protected String LOCATION = "gov.nasa.worldwind.airspaceditor.Location";
    protected String ROTATION = "gov.nasa.worldwind.airspaceditor.Rotation";
    protected String LEFT_WIDTH = "gov.nasa.worldwind.airspaceditor.LeftWidth";
    protected String RIGHT_WIDTH = "gov.nasa.worldwind.airspaceditor.RightWidth";
    protected String INNER_RADIUS = "gov.nasa.worldwind.airspaceditor.InnerRadius";
    protected String OUTER_RADIUS = "gov.nasa.worldwind.airspaceditor.OuterRadius";
    protected String LEFT_AZIMUTH = "gov.nasa.worldwind.airspaceditor.LeftAzimuth";
    protected String RIGHT_AZIMUTH = "gov.nasa.worldwind.airspaceditor.RightAzimuth";

    protected static class ControlPointMarker extends BasicMarker
    {
        protected int index;
        protected int leg;
        protected String purpose;
        protected Double size;
        protected Angle rotation;

        public ControlPointMarker(Position position, MarkerAttributes attrs, int index, String purpose)
        {
            super(position, attrs);
            this.index = index;
            this.purpose = purpose;
        }

        public ControlPointMarker(Position position, MarkerAttributes attrs, int index, int leg, String purpose)
        {
            this(position, attrs, index, purpose);

            this.leg = leg;
        }

        public int getIndex()
        {
            return this.index;
        }

        public int getLeg()
        {
            return leg;
        }

        public String getPurpose()
        {
            return this.purpose;
        }
    }

    protected static final int NONE = 0;
    protected static final int MOVING = 1;
    protected static final int SIZING = 2;

    protected final WorldWindow wwd;
    protected Airspace shape;
    protected MarkerLayer controlPointLayer;
    protected RenderableLayer accessoryLayer;
    protected RenderableLayer annotationLayer;
    protected RenderableLayer shadowLayer;
    protected EditorAnnotation annotation;
    protected UnitsFormat unitsFormat;

    protected boolean armed;

    protected boolean active;
    protected int activeOperation = NONE;
    protected Position previousPosition = null;
    protected ControlPointMarker currentSizingMarker;
    protected AirspaceAttributes originalAttributes;
    protected Angle currentHeading = Angle.ZERO;
    protected List<Box> trackAdjacencyList;

    public AirspaceEditor(WorldWindow wwd, Airspace originalShape)
    {
        if (wwd == null)
        {
            String msg = Logging.getMessage("nullValue.WorldWindow");
            Logging.logger().log(java.util.logging.Level.FINE, msg);
            throw new IllegalArgumentException(msg);
        }

        if (originalShape == null)
        {
            String msg = Logging.getMessage("nullValue.Shape");
            Logging.logger().log(java.util.logging.Level.FINE, msg);
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
    }

    public UnitsFormat getUnitsFormat()
    {
        return unitsFormat;
    }

    public void setUnitsFormat(UnitsFormat unitsFormat)
    {
        this.unitsFormat = unitsFormat != null ? unitsFormat : new UnitsFormat();
    }

    public WorldWindow getWwd()
    {
        return this.wwd;
    }

    public Airspace getAirspace()
    {
        return this.shape;
    }

    public boolean isArmed()
    {
        return this.armed;
    }

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
            this.markTrackAdjacency();

        this.updateControlPoints();

        this.wwd.addSelectListener(this);
    }

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

    protected void markTrackAdjacency()
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
            this.removeShadow();
            this.updateAnnotation(null);
        }
        else if (event.getEventAction().equals(SelectEvent.ROLLOVER))
        {
            if (!(this.wwd instanceof Component))
                return;

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
            PickedObject terrainObject = this.wwd.getObjectsAtCurrentPosition().getTerrainObject();
            if (terrainObject != null)
                this.previousPosition = terrainObject.getPosition();
        }
        else if (event.getEventAction().equals(SelectEvent.DRAG))
        {
            if (!this.active)
                return;

            DragSelectEvent dragEvent = (DragSelectEvent) event;
            Object topObject = dragEvent.getTopObject();
            if (topObject == null)
                return;

            if (this.activeOperation == NONE)
                this.makeShadow();

            if (topObject == this.shape || this.activeOperation == MOVING)
            {
                this.activeOperation = MOVING;
                this.dragWholeShape(dragEvent, topObject);
                this.updateControlPoints();
                this.updateShapeAnnotation();
                event.consume();
            }
            else if (dragEvent.getTopPickedObject().getParentLayer() == this.controlPointLayer
                || this.activeOperation == SIZING)
            {
                this.activeOperation = SIZING;
                this.resizeShape(topObject);
                this.updateControlPoints();
                this.updateAnnotation(this.currentSizingMarker);
                event.consume();
            }

            this.wwd.redraw();
        }
    }

    protected void makeShadow()
    {
        Airspace shadowShape = this.makeShadowShape();
        if (shadowShape != null)
        {
            // Set up to keep the shape highlighted during editing but with a reduced opacity.
//            this.originalAttributes = this.shape.getAttributes();

            AirspaceAttributes editingHighlightAttributes = new BasicAirspaceAttributes(this.originalAttributes);
            if (this.originalAttributes.getInteriorOpacity() == 1)
                editingHighlightAttributes.setInteriorOpacity(0.7);
            this.shape.setAttributes(editingHighlightAttributes);

            this.shadowLayer.addRenderable(shadowShape);
        }
    }

    protected void removeShadow()
    {
        this.shadowLayer.removeAllRenderables();
//        if (this.originalAttributes != null)
        this.shape.setAttributes(this.originalAttributes);
//        this.originalAttributes = null;
        this.wwd.redraw();
    }

    protected Airspace makeShadowShape()
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

    protected void adjustShape()
    {
        if (this.shape instanceof TrackAirspace)
            this.adjustTrackShape();
    }

    protected void adjustTrackShape()
    {
        TrackAirspace track = (TrackAirspace) this.shape;

        List<Box> legs = track.getLegs();
        if (legs == null)
            return;

        for (int i = 1; i < legs.size(); i++)
        {
            Box leg = legs.get(i);

            if (this.trackAdjacencyList.contains(legs.get(i)))
            {
                leg.setLocations(legs.get(i - 1).getLocations()[1], leg.getLocations()[1]);
            }
        }
    }

    protected void dragWholeShape(DragSelectEvent dragEvent, Object topObject)
    {
        if (!(topObject instanceof Movable))
            return;

        Movable2 dragObject = (Movable2) topObject;

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

    protected void resizeShape(Object topObject)
    {
        if (!(topObject instanceof ControlPointMarker))
            return;

        this.currentSizingMarker = (ControlPointMarker) topObject;

        // If the terrain beneath the control point is null, then the user is attempting to drag the handle off the
        // globe. This is not a valid state for SurfaceImage, so we will ignore this action but keep the drag operation
        // in effect.
        PickedObject terrainObject = this.wwd.getObjectsAtCurrentPosition().getTerrainObject();
        if (terrainObject == null)
            return;

        if (this.previousPosition == null)
        {
            this.previousPosition = terrainObject.getPosition();
            return;
        }

        if (this.shape instanceof Polygon || this.shape instanceof Curtain)
            this.reshapePolygon(terrainObject.getPosition(), (ControlPointMarker) topObject);
        else if (this.shape instanceof CappedCylinder)
            this.reshapeCappedCylinder(terrainObject.getPosition(), (ControlPointMarker) topObject);
        else if (this.shape instanceof Orbit)
            this.reshapeOrbit(terrainObject.getPosition(), (ControlPointMarker) topObject);
        else if (this.shape instanceof Route)
            this.reshapeRoute(terrainObject.getPosition(), (ControlPointMarker) topObject);
        else if (this.shape instanceof SphereAirspace)
            this.reshapeSphere(terrainObject.getPosition(), (ControlPointMarker) topObject);
        else if (this.shape instanceof TrackAirspace)
            this.reshapeTrack(terrainObject.getPosition(), (ControlPointMarker) topObject);

        this.previousPosition = terrainObject.getPosition();

        this.adjustShape();
    }

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

    protected void reshapePolygon(Position terrainPosition, ControlPointMarker controlPoint)
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

        // Compute how much the specified control point moved.
        Vec4 terrainPoint = wwd.getModel().getGlobe().computeEllipsoidalPointFromLocation(terrainPosition);
        Vec4 previousPoint = wwd.getModel().getGlobe().computeEllipsoidalPointFromLocation(this.previousPosition);
        Vec4 delta = terrainPoint.subtract3(previousPoint);

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
            Vec4 markerPoint = wwd.getModel().getGlobe().computeEllipsoidalPointFromLocation(
                new Position(controlPoint.getPosition(), 0));
            Position markerPosition = wwd.getModel().getGlobe().computePositionFromEllipsoidalPoint(
                markerPoint.add3(delta));

            // Update the polygon's locations.
            locations.set(controlPoint.getIndex(), markerPosition);
        }

        if (this.shape instanceof Polygon)
            ((Polygon) this.shape).setLocations(locations);
        else if (this.shape instanceof Curtain)
            ((Curtain) this.shape).setLocations(locations);
    }

    protected void reshapeCappedCylinder(Position terrainPosition, ControlPointMarker controlPoint)
    {
        CappedCylinder cylinder = (CappedCylinder) this.shape;
        double[] radii = cylinder.getRadii();

        Vec4 terrainPoint = wwd.getModel().getGlobe().computeEllipsoidalPointFromLocation(terrainPosition);
        Vec4 previousPoint = wwd.getModel().getGlobe().computeEllipsoidalPointFromLocation(this.previousPosition);
        Vec4 delta = terrainPoint.subtract3(previousPoint);

        Vec4 centerPoint = wwd.getModel().getGlobe().computeEllipsoidalPointFromLocation(cylinder.getCenter());
        Vec4 markerPoint = wwd.getModel().getGlobe().computeEllipsoidalPointFromLocation(controlPoint.getPosition());
        Vec4 vMarker = markerPoint.subtract3(centerPoint).normalize3();

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

    protected void reshapeSphere(Position terrainPosition, ControlPointMarker controlPoint)
    {
        SphereAirspace sphere = (SphereAirspace) this.shape;
        double radius = sphere.getRadius();

        Vec4 terrainPoint = wwd.getModel().getGlobe().computeEllipsoidalPointFromLocation(terrainPosition);
        Vec4 previousPoint = wwd.getModel().getGlobe().computeEllipsoidalPointFromLocation(this.previousPosition);
        Vec4 delta = terrainPoint.subtract3(previousPoint);

        Vec4 centerPoint = wwd.getModel().getGlobe().computeEllipsoidalPointFromLocation(sphere.getLocation());
        Vec4 markerPoint = wwd.getModel().getGlobe().computeEllipsoidalPointFromLocation(controlPoint.getPosition());
        Vec4 vMarker = markerPoint.subtract3(centerPoint).normalize3();

        if (controlPoint.getPurpose().equals(OUTER_RADIUS))
            radius += delta.dot3(vMarker);

        if (radius > 0)
            sphere.setRadius(radius);
    }

    protected void reshapeOrbit(Position terrainPosition, ControlPointMarker controlPoint)
    {
        Orbit orbit = (Orbit) this.shape;
        LatLon[] locations = orbit.getLocations();
        double width = orbit.getWidth();

        Vec4 terrainPoint = wwd.getModel().getGlobe().computeEllipsoidalPointFromLocation(terrainPosition);
        Vec4 previousPoint = wwd.getModel().getGlobe().computeEllipsoidalPointFromLocation(this.previousPosition);
        Vec4 delta = terrainPoint.subtract3(previousPoint);

        LatLon center = LatLon.interpolateGreatCircle(0.5, locations[0], locations[1]);
        Vec4 centerPoint = wwd.getModel().getGlobe().computeEllipsoidalPointFromLocation(center);

        Vec4 markerPoint = wwd.getModel().getGlobe().computeEllipsoidalPointFromLocation(
            new Position(controlPoint.getPosition(), 0));

        if (controlPoint.getPurpose().equals(RIGHT_WIDTH))
        {
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
            Position markerPosition = wwd.getModel().getGlobe().computePositionFromEllipsoidalPoint(
                markerPoint.add3(delta));
            locations[controlPoint.getIndex()] = markerPosition;
            orbit.setLocations(locations[0], locations[1]);
        }
    }

    protected void reshapeRoute(Position terrainPosition, ControlPointMarker controlPoint)
    {
        Route route = (Route) this.shape;

        java.util.List<LatLon> locations = new ArrayList<LatLon>();
        for (LatLon ll : route.getLocations())
        {
            locations.add(ll);
        }

        Vec4 terrainPoint = wwd.getModel().getGlobe().computeEllipsoidalPointFromLocation(terrainPosition);
        Vec4 previousPoint = wwd.getModel().getGlobe().computeEllipsoidalPointFromLocation(this.previousPosition);
        Vec4 delta = terrainPoint.subtract3(previousPoint);

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
            route.setWidth(route.getWidth() + delta.dot3(vMarker));
        }
        else // location change
        {
            Vec4 markerPoint = wwd.getModel().getGlobe().computeEllipsoidalPointFromLocation(
                new Position(controlPoint.getPosition(), 0));
            Position markerPosition = wwd.getModel().getGlobe().computePositionFromEllipsoidalPoint(
                markerPoint.add3(delta));

            locations.set(controlPoint.getIndex(), markerPosition);
            route.setLocations(locations);
        }
    }

    protected void reshapeTrack(Position terrainPosition, ControlPointMarker controlPoint)
    {
        TrackAirspace track = (TrackAirspace) this.shape;
        List<Box> legs = track.getLegs();

        Vec4 terrainPoint = wwd.getModel().getGlobe().computeEllipsoidalPointFromLocation(terrainPosition);
        Vec4 previousPoint = wwd.getModel().getGlobe().computeEllipsoidalPointFromLocation(this.previousPosition);
        Vec4 delta = terrainPoint.subtract3(previousPoint);

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
            Vec4 markerPoint = wwd.getModel().getGlobe().computeEllipsoidalPointFromLocation(
                new Position(controlPoint.getPosition(), 0));
            Position markerPosition = wwd.getModel().getGlobe().computePositionFromEllipsoidalPoint(
                markerPoint.add3(delta));

            Box leg = track.getLegs().get(controlPoint.getLeg());
            if (controlPoint.getIndex() == 0)
                leg.setLocations(markerPosition, leg.getLocations()[1]);
            else
                leg.setLocations(leg.getLocations()[0], markerPosition);
        }

        track.setLegs(new ArrayList<Box>(track.getLegs()));
    }

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
            MarkerAttributes markerAttrs =
                new BasicMarkerAttributes(Material.BLUE, BasicMarkerShape.SPHERE, 0.7, 10, 0.1);

            ArrayList<Marker> controlPoints = new ArrayList<Marker>();
            int i = 0;
            for (LatLon location : locations)
            {
                double altitude = this.computeControlPointAltitude(location);
                controlPoints.add(new ControlPointMarker(new Position(location, altitude), markerAttrs, i++,
                    LOCATION));
            }

            // Create a control point for the rotation control.
            markerAttrs = new BasicMarkerAttributes(Material.GREEN, BasicMarkerShape.SPHERE, 0.7, 10, 0.1);
            controlPoints.add(
                new ControlPointMarker(new Position(rotationControlLocation, rotationControlAltitude), markerAttrs, i,
                    ROTATION));

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

    protected void updateCappedCylinderControlPoints()
    {
        CappedCylinder cylinder = (CappedCylinder) this.shape;
        double[] radii = cylinder.getRadii();
        boolean hasInnerRadius = radii[0] > 0;

        LatLon coPosition = LatLon.greatCircleEndPosition(cylinder.getCenter(), Angle.fromDegrees(90),
            Angle.fromRadians(radii[1] / this.wwd.getModel().getGlobe().getEquatorialRadius()));
        LatLon ciPosition = LatLon.greatCircleEndPosition(cylinder.getCenter(), Angle.fromDegrees(90),
            Angle.fromRadians(radii[0] / this.wwd.getModel().getGlobe().getEquatorialRadius()));

        double coAltitude = this.computeControlPointAltitude(coPosition);
        double ciAltitude = this.computeControlPointAltitude(ciPosition);

        Iterable<Marker> markers = this.controlPointLayer.getMarkers();
        if (markers == null)
        {
            MarkerAttributes markerAttrs =
                new BasicMarkerAttributes(Material.CYAN, BasicMarkerShape.SPHERE, 0.7, 10, 0.1);

            java.util.List<Marker> markerList = new ArrayList<Marker>(1);
            markerList.add(new ControlPointMarker(new Position(coPosition, coAltitude), markerAttrs, 0,
                OUTER_RADIUS));
            if (hasInnerRadius)
                markerList.add(new ControlPointMarker(new Position(ciPosition, ciAltitude), markerAttrs, 1,
                    INNER_RADIUS));
            this.controlPointLayer.setMarkers(markerList);
        }
        else
        {
            Iterator<Marker> markerIterator = markers.iterator();
            markerIterator.next().setPosition(new Position(coPosition, coAltitude));
            if (hasInnerRadius)
                markerIterator.next().setPosition(new Position(ciPosition, ciAltitude));
        }

        Iterator<Marker> markerIterator = this.controlPointLayer.getMarkers().iterator();
        ((ControlPointMarker) markerIterator.next()).size = radii[1];
        if (hasInnerRadius)
            ((ControlPointMarker) markerIterator.next()).size = radii[0];
    }

    protected void updatePartialCappedCylinderControlPoints()
    {
        PartialCappedCylinder cylinder = (PartialCappedCylinder) this.shape;

        double[] radii = cylinder.getRadii();
        boolean hasInnerRadius = radii[0] > 0;
        double averageRadius = 0.5 * (radii[0] + radii[1]);

        Angle[] azimuths = cylinder.getAzimuths();

        LatLon coPosition = LatLon.greatCircleEndPosition(cylinder.getCenter(), azimuths[1],
            Angle.fromRadians(radii[1] / this.wwd.getModel().getGlobe().getEquatorialRadius()));
        LatLon ciPosition = LatLon.greatCircleEndPosition(cylinder.getCenter(), azimuths[1],
            Angle.fromRadians(radii[0] / this.wwd.getModel().getGlobe().getEquatorialRadius()));

        LatLon cLPosition = LatLon.greatCircleEndPosition(cylinder.getCenter(), azimuths[0],
            Angle.fromRadians(averageRadius / this.wwd.getModel().getGlobe().getEquatorialRadius()));
        LatLon cRPosition = LatLon.greatCircleEndPosition(cylinder.getCenter(), azimuths[1],
            Angle.fromRadians(averageRadius / this.wwd.getModel().getGlobe().getEquatorialRadius()));

        double coAltitude = this.computeControlPointAltitude(coPosition);
        double ciAltitude = this.computeControlPointAltitude(ciPosition);
        double cRAltitude = this.computeControlPointAltitude(cRPosition);
        double cLAltitude = this.computeControlPointAltitude(cLPosition);

        LatLon rotationControlLocation = LatLon.greatCircleEndPosition(cylinder.getCenter(), this.currentHeading,
            Angle.fromRadians(1.2 * radii[1] / this.wwd.getModel().getGlobe().getEquatorialRadius()));
        double rotationControlAltitude = this.computeControlPointAltitude(rotationControlLocation);

        Iterable<Marker> markers = this.controlPointLayer.getMarkers();
        if (markers == null)
        {
            MarkerAttributes markerAttrs =
                new BasicMarkerAttributes(Material.CYAN, BasicMarkerShape.SPHERE, 0.7, 10, 0.1);

            java.util.List<Marker> markerList = new ArrayList<Marker>(1);
            markerList.add(new ControlPointMarker(new Position(coPosition, coAltitude), markerAttrs, 0,
                OUTER_RADIUS));
            if (hasInnerRadius)
                markerList.add(new ControlPointMarker(new Position(ciPosition, ciAltitude), markerAttrs, 1,
                    INNER_RADIUS));

            markerAttrs =
                new BasicMarkerAttributes(Material.GREEN, BasicMarkerShape.SPHERE, 0.7, 10, 0.1);
            markerList.add(new ControlPointMarker(new Position(cLPosition, cLAltitude), markerAttrs, 2,
                LEFT_AZIMUTH));
            markerList.add(new ControlPointMarker(new Position(cRPosition, cRAltitude), markerAttrs, 3,
                RIGHT_AZIMUTH));

            markerList.add(
                new ControlPointMarker(new Position(rotationControlLocation, rotationControlAltitude), markerAttrs, 4,
                    ROTATION));

            this.controlPointLayer.setMarkers(markerList);
        }
        else
        {
            Iterator<Marker> markerIterator = markers.iterator();
            markerIterator.next().setPosition(new Position(coPosition, coAltitude));
            if (hasInnerRadius)
                markerIterator.next().setPosition(new Position(ciPosition, cRAltitude));
            markerIterator.next().setPosition(new Position(cLPosition, cLAltitude));
            markerIterator.next().setPosition(new Position(cRPosition, cRAltitude));

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

    protected void updateSphereControlPoints()
    {
        SphereAirspace sphere = (SphereAirspace) this.shape;
        double radius = sphere.getRadius();

        LatLon cpPosition = LatLon.greatCircleEndPosition(sphere.getLocation(), Angle.fromDegrees(90),
            Angle.fromRadians(radius / this.wwd.getModel().getGlobe().getEquatorialRadius()));

        double cpAltitude = this.computeControlPointAltitude(cpPosition);

        Iterable<Marker> markers = this.controlPointLayer.getMarkers();
        if (markers == null)
        {
            MarkerAttributes markerAttrs =
                new BasicMarkerAttributes(Material.CYAN, BasicMarkerShape.SPHERE, 0.7, 10, 0.1);

            java.util.List<Marker> markerList = new ArrayList<Marker>(1);
            markerList.add(new ControlPointMarker(new Position(cpPosition, cpAltitude), markerAttrs, 0,
                OUTER_RADIUS));
            this.controlPointLayer.setMarkers(markerList);
        }
        else
        {
            Iterator<Marker> markerIterator = markers.iterator();
            markerIterator.next().setPosition(new Position(cpPosition, cpAltitude));
        }

        Iterator<Marker> markerIterator = this.controlPointLayer.getMarkers().iterator();
        ((ControlPointMarker) markerIterator.next()).size = radius;
    }

    protected void updateOrbitControlPoints()
    {
        Orbit orbit = (Orbit) this.shape;
        LatLon[] locations = orbit.getLocations();
        double width = orbit.getWidth();

        double c0Altitude = this.computeControlPointAltitude(locations[0]);
        double c1Altitude = this.computeControlPointAltitude(locations[1]);
        double cwAltitude = 0.5 * (c0Altitude + c1Altitude);

        Angle orbitHeading = LatLon.greatCircleAzimuth(locations[0], locations[1]);
        LatLon center = LatLon.interpolateGreatCircle(0.5, locations[0], locations[1]);
        double centerAltitude = this.computeControlPointAltitude(center);
        LatLon cwLocation = LatLon.greatCircleEndPosition(center, Angle.fromDegrees(90 + orbitHeading.degrees),
            Angle.fromRadians(0.5 * width / this.wwd.getModel().getGlobe().getEquatorialRadius()));
        Angle length = LatLon.greatCircleDistance(center, locations[0]);
        LatLon crLocation = LatLon.greatCircleEndPosition(center, Angle.fromDegrees(orbitHeading.degrees),
            Angle.fromRadians(length.radians + 1.2 * width / this.wwd.getModel().getGlobe().getEquatorialRadius()));

        Iterable<Marker> markers = this.controlPointLayer.getMarkers();
        if (markers == null)
        {
            MarkerAttributes markerAttrs =
                new BasicMarkerAttributes(Material.BLUE, BasicMarkerShape.SPHERE, 0.7, 10, 0.1);

            java.util.List<Marker> markerList = new ArrayList<Marker>(1);
            markerList.add(new ControlPointMarker(new Position(locations[0], c0Altitude), markerAttrs, 0,
                LOCATION));
            markerList.add(new ControlPointMarker(new Position(locations[1], c1Altitude), markerAttrs, 1,
                LOCATION));

            markerAttrs = new BasicMarkerAttributes(Material.CYAN, BasicMarkerShape.SPHERE, 0.7, 10, 0.1);
            markerList.add(new ControlPointMarker(new Position(cwLocation, cwAltitude), markerAttrs, 2,
                RIGHT_WIDTH));

            markerAttrs = new BasicMarkerAttributes(Material.GREEN, BasicMarkerShape.SPHERE, 0.7, 10, 0.1);
            markerList.add(new ControlPointMarker(new Position(crLocation, cwAltitude), markerAttrs, 3,
                ROTATION));

            this.controlPointLayer.setMarkers(markerList);
        }
        else
        {
            Iterator<Marker> markerIterator = markers.iterator();
            markerIterator.next().setPosition(new Position(locations[0], c0Altitude));
            markerIterator.next().setPosition(new Position(locations[1], c1Altitude));
            markerIterator.next().setPosition(new Position(cwLocation, cwAltitude));
            markerIterator.next().setPosition(new Position(crLocation, cwAltitude));
        }

        Iterator<Marker> markerIterator = this.controlPointLayer.getMarkers().iterator();
        markerIterator.next();
        markerIterator.next();
        ((ControlPointMarker) markerIterator.next()).size = width;
        ((ControlPointMarker) markerIterator.next()).rotation = this.normalizedHeading(orbitHeading, Angle.ZERO);

        this.updateOrientationLine(new Position(center, centerAltitude), new Position(crLocation, cwAltitude));
    }

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

        Angle legHeading = LatLon.greatCircleAzimuth(locations.get(0), locations.get(1));
        LatLon legCenter = LatLon.interpolateGreatCircle(0.5, locations.get(0), locations.get(1));

        Angle cRHeading = legHeading.add(Angle.POS90);
        LatLon cwRLocation = LatLon.greatCircleEndPosition(legCenter, cRHeading,
            Angle.fromRadians((0.5 * route.getWidth()) / this.wwd.getModel().getGlobe().getEquatorialRadius()));
        double cwRAltitude = this.computeControlPointAltitude(cwRLocation);

        Angle cLHeading = legHeading.subtract(Angle.POS90);
        LatLon cwLLocation = LatLon.greatCircleEndPosition(legCenter, cLHeading,
            Angle.fromRadians((0.5 * route.getWidth()) / this.wwd.getModel().getGlobe().getEquatorialRadius()));
        double cwLAltitude = this.computeControlPointAltitude(cwLLocation);

        LatLon center = LatLon.getCenter(locations);
        double centerAltitude = this.computeControlPointAltitude(center);
        Angle distance = LatLon.getAverageDistance(locations);
        Angle routeHeading = this.currentHeading;
        LatLon crLocation = LatLon.greatCircleEndPosition(center, routeHeading, distance);
        double crAltitude = this.computeControlPointAltitude(crLocation);

        Iterable<Marker> markers = this.controlPointLayer.getMarkers();
        if (markers == null)
        {
            MarkerAttributes markerAttrs =
                new BasicMarkerAttributes(Material.BLUE, BasicMarkerShape.SPHERE, 0.7, 10, 0.1);

            ArrayList<Marker> controlPoints = new ArrayList<Marker>();
            int i = 0;
            for (LatLon cpPosition : locations)
            {
                double altitude = this.computeControlPointAltitude(cpPosition);
                controlPoints.add(new ControlPointMarker(new Position(cpPosition, altitude), markerAttrs, i++,
                    LOCATION));
            }

            markerAttrs = new BasicMarkerAttributes(Material.CYAN, BasicMarkerShape.SPHERE, 0.7, 10, 0.1);
            controlPoints.add(new ControlPointMarker(new Position(cwRLocation, cwRAltitude), markerAttrs, i++,
                RIGHT_WIDTH));
            controlPoints.add(new ControlPointMarker(new Position(cwLLocation, cwLAltitude), markerAttrs, i++,
                LEFT_WIDTH));

            markerAttrs = new BasicMarkerAttributes(Material.GREEN, BasicMarkerShape.SPHERE, 0.7, 10, 0.1);
            controlPoints.add(new ControlPointMarker(new Position(crLocation, crAltitude), markerAttrs, i,
                ROTATION));

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

            markerIterator.next().setPosition(new Position(cwRLocation, cwRAltitude));
            markerIterator.next().setPosition(new Position(cwLLocation, cwLAltitude));
            markerIterator.next().setPosition(new Position(crLocation, crAltitude));
        }

        Iterator<Marker> markerIterator = this.controlPointLayer.getMarkers().iterator();
        for (LatLon ignored : locations)
        {
            markerIterator.next();
        }
        ((ControlPointMarker) markerIterator.next()).size = route.getWidth();
        ((ControlPointMarker) markerIterator.next()).size = route.getWidth();
        ((ControlPointMarker) markerIterator.next()).rotation = routeHeading;

        this.updateOrientationLine(new Position(center, centerAltitude), new Position(crLocation, crAltitude));
    }

    protected void updateTrackControlPoints()
    {
        TrackAirspace track = (TrackAirspace) this.shape;

        List<Box> legs = track.getLegs();
        if (legs == null)
            return;

        MarkerAttributes locationAttrs =
            new BasicMarkerAttributes(Material.BLUE, BasicMarkerShape.SPHERE, 0.7, 10, 0.1);

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
                        locationAttrs, 0, i, LOCATION);
                    controlPoints.add(cp);
                }

                altitude = this.computeControlPointAltitude(legLocations[1]);
                ControlPointMarker cp = new ControlPointMarker(new Position(legLocations[1], altitude),
                    locationAttrs, 1, i, LOCATION);
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

        MarkerAttributes sizeAttrs =
            new BasicMarkerAttributes(Material.CYAN, BasicMarkerShape.SPHERE, 0.7, 10, 0.1);

        for (int i = 0; i < legs.size(); i++)
        {
            Box leg = legs.get(i);
            if (!this.trackAdjacencyList.contains(leg))
            {
                LatLon[] legLocations = leg.getLocations();
                double[] widths = leg.getWidths();

                Angle legHeading = LatLon.greatCircleAzimuth(legLocations[0], legLocations[1]);
                LatLon legCenter = LatLon.interpolateGreatCircle(0.5, legLocations[0], legLocations[1]);

                Angle cwLHeading = legHeading.subtract(Angle.POS90);
                LatLon cwLLocation = LatLon.greatCircleEndPosition(legCenter, cwLHeading,
                    Angle.fromRadians(widths[0] / this.wwd.getModel().getGlobe().getEquatorialRadius()));
                double cwLAltitude = this.computeControlPointAltitude(cwLLocation);

                Angle cwRHeading = legHeading.add(Angle.POS90);
                LatLon cwRLocation = LatLon.greatCircleEndPosition(legCenter, cwRHeading,
                    Angle.fromRadians(widths[1] / this.wwd.getModel().getGlobe().getEquatorialRadius()));
                double cwRAltitude = this.computeControlPointAltitude(cwRLocation);

                if (markers == null)
                {
                    controlPoints.add(new ControlPointMarker(new Position(cwLLocation, cwLAltitude), sizeAttrs, 2, i,
                        LEFT_WIDTH));
                    controlPoints.add(new ControlPointMarker(new Position(cwRLocation, cwRAltitude), sizeAttrs, 3, i,
                        RIGHT_WIDTH));
                }
                else
                {
                    //noinspection ConstantConditions
                    markerIterator.next().setPosition(new Position(cwLLocation, cwLAltitude));
                    markerIterator.next().setPosition(new Position(cwRLocation, cwRAltitude));
                }
            }
        }

        List<LatLon> trackLocations = new ArrayList<LatLon>();
        for (Box leg : legs)
        {
            trackLocations.add(leg.getLocations()[0]);
            trackLocations.add(leg.getLocations()[1]);
        }
        LatLon trackCenter = LatLon.getCenter(trackLocations);
        double trackCenterAltitude = this.computeControlPointAltitude(trackCenter);
        Angle trackRadius = LatLon.getAverageDistance(trackLocations);

        LatLon crLocation = LatLon.greatCircleEndPosition(trackCenter, this.currentHeading, trackRadius);
        double crAltitude = this.computeControlPointAltitude(crLocation);
        if (markers == null)
        {
            MarkerAttributes rotationAttrs = new BasicMarkerAttributes(Material.GREEN, BasicMarkerShape.SPHERE,
                0.7, 10, 0.1);
            controlPoints.add(new ControlPointMarker(new Position(crLocation, crAltitude), rotationAttrs, 4,
                ROTATION));
        }
        else
        {
            //noinspection ConstantConditions
            markerIterator.next().setPosition(new Position(crLocation, crAltitude));
        }

        this.updateOrientationLine(new Position(trackCenter, trackCenterAltitude),
            new Position(crLocation, crAltitude));

        if (markers == null)
            this.controlPointLayer.setMarkers(controlPoints);

        markers = this.controlPointLayer.getMarkers();
        for (Marker marker : markers)
        {
            ControlPointMarker cp = (ControlPointMarker) marker;

            if (cp.getIndex() == 2)
                cp.size = legs.get(cp.getLeg()).getWidths()[0];
            else if (cp.getIndex() == 3)
                cp.size = legs.get(cp.getLeg()).getWidths()[1];
            else if (cp.getIndex() == 4)
            {
                cp.rotation = this.currentHeading;
            }
        }
    }

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

    protected void updateShapeAnnotation()
    {
        LatLon center = null;

        if (this.shape instanceof CappedCylinder)
            center = ((CappedCylinder) this.shape).getCenter();

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

    protected void updateAnnotation(ControlPointMarker marker)
    {
        if (marker == null)
        {
            this.annotationLayer.setEnabled(false);
            return;
        }

        this.annotationLayer.setEnabled(true);
        this.annotation.setPosition(marker.getPosition());

        String annotationText;
        if (marker.size != null)
            annotationText = this.unitsFormat.length(null, marker.size);
        else if (marker.rotation != null)
            annotationText = this.unitsFormat.angle(null, marker.rotation);
        else
            annotationText = this.unitsFormat.latLon2(marker.getPosition());

        this.annotation.setText(annotationText);
    }

    protected void updateOrientationLine(Position centerPosition, Position cpPositionR)
    {
        Path rotationLine = (Path) this.accessoryLayer.getRenderables().iterator().next();

        double cAltitude = centerPosition.getAltitude();
        double rAltitude = cpPositionR.getAltitude();
        if (this.shape.getAltitudeDatum()[1].equals(AVKey.ABOVE_GROUND_LEVEL))
        {
            rotationLine.setAltitudeMode(WorldWind.RELATIVE_TO_GROUND);
            rotationLine.setFollowTerrain(true);

            cAltitude = 100 + centerPosition.getAltitude() - this.getWwd().getModel().getGlobe().getElevation(
                centerPosition.getLatitude(), centerPosition.getLongitude());
            rAltitude = 100 + cpPositionR.getAltitude() - this.getWwd().getModel().getGlobe().getElevation(
                cpPositionR.getLatitude(), cpPositionR.getLongitude());
        }
        else
        {
            rotationLine.setAltitudeMode(WorldWind.ABSOLUTE);
            rotationLine.setFollowTerrain(false);
        }

        java.util.List<Position> linePositions = new ArrayList<Position>(2);
        linePositions.add(new Position(centerPosition, cAltitude));
        linePositions.add(new Position(cpPositionR, rAltitude));
        rotationLine.setPositions(linePositions);
    }

    protected Angle normalizedHeading(Angle originalHeading, Angle deltaHeading)
    {
        final double twoPI = 2 * Math.PI;

        double newHeading = originalHeading.getRadians() + deltaHeading.getRadians();

        if (Math.abs(newHeading) > twoPI)
            newHeading = newHeading % twoPI;

        return Angle.fromRadians(newHeading >= 0 ? newHeading : newHeading + twoPI);
    }
}
