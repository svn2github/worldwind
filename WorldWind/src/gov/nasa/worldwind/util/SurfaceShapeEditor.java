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
import gov.nasa.worldwind.render.markers.*;
import gov.nasa.worldwind.terrain.SectorGeometryList;

import java.awt.*;
import java.util.*;

/**
 * @author tag
 * @version $Id$
 */
public class SurfaceShapeEditor implements SelectListener
{
    protected static final int NONE = 0;
    protected static final int MOVING = 1;
    protected static final int SIZING = 2;

    protected final WorldWindow wwd;
    protected SurfaceShape shape;
    protected MarkerLayer controlPointLayer;
    protected RenderableLayer accessoryLayer;
    protected RenderableLayer annotationLayer;
    protected EditorAnnotation annotation;
    protected boolean armed;

    protected boolean active;
    protected int activeOperation = NONE;
    protected Position previousPosition = null;
    protected ControlPointMarker currentSizingMarker;

    protected static class ControlPointMarker extends BasicMarker
    {
        protected int index;
        protected Double size;
        protected Angle rotation;

        public ControlPointMarker(Position position, MarkerAttributes attrs, int index)
        {
            super(position, attrs);
            this.index = index;
        }

        public int getIndex()
        {
            return this.index;
        }
    }

    public SurfaceShapeEditor(WorldWindow wwd, SurfaceShape shape)
    {
        if (wwd == null)
        {
            String msg = Logging.getMessage("nullValue.WorldWindow");
            Logging.logger().log(java.util.logging.Level.FINE, msg);
            throw new IllegalArgumentException(msg);
        }
        if (shape == null)
        {
            String msg = Logging.getMessage("nullValue.Shape");
            Logging.logger().log(java.util.logging.Level.FINE, msg);
            throw new IllegalArgumentException(msg);
        }

        this.wwd = wwd;
        this.shape = shape;

        this.controlPointLayer = new MarkerLayer();
        this.controlPointLayer.setOverrideMarkerElevation(true);
        this.controlPointLayer.setElevation(0);
        this.controlPointLayer.setKeepSeparated(false);

        this.accessoryLayer = new RenderableLayer();
        this.accessoryLayer.setPickEnabled(false);

        ShapeAttributes lineAttrs = new BasicShapeAttributes();
        lineAttrs.setOutlineMaterial(Material.GREEN);
        lineAttrs.setOutlineWidth(1);
        java.util.List<LatLon> lineLocations = new ArrayList<LatLon>(2);
        lineLocations.add(LatLon.ZERO);
        lineLocations.add(LatLon.ZERO);
        SurfacePolyline rotationLine = new SurfacePolyline(lineAttrs, lineLocations);
        this.accessoryLayer.addRenderable(rotationLine);

        this.annotationLayer = new RenderableLayer();
        this.annotationLayer.setPickEnabled(false);

        this.annotation = new EditorAnnotation("");
        this.annotationLayer.addRenderable(this.annotation);
    }

    public WorldWindow getWwd()
    {
        return this.wwd;
    }

    public SurfaceShape getSurfaceShape()
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

        this.updateControlPoints();

        this.wwd.addSelectListener(this);
    }

    protected void disable()
    {
        LayerList layers = this.wwd.getModel().getLayers();

        layers.remove(this.controlPointLayer);
        layers.remove(this.accessoryLayer);
        layers.remove(this.annotationLayer);

        wwd.removeSelectListener(this);

        ((Component) this.wwd).setCursor(null);
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

            if (this.activeOperation == MOVING)
                this.updateShapeAnnotation((SurfaceShape) event.getTopObject());
            else if (this.activeOperation == SIZING)
                this.updateAnnotation(this.currentSizingMarker);
            else if (event.getTopObject() != null && event.getTopObject() == this.shape)
                this.updateShapeAnnotation((SurfaceShape) event.getTopObject());
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

            if (topObject == this.shape || this.activeOperation == MOVING)
            {
                this.activeOperation = MOVING;
                this.dragWholeShape(dragEvent, topObject);
                this.updateControlPoints();
                this.updateShapeAnnotation((SurfaceShape) topObject);
                event.consume();
            }
            else if (dragEvent.getTopPickedObject().getParentLayer() == this.controlPointLayer
                || this.activeOperation == SIZING)
            {
                this.activeOperation = SIZING;
                this.resizeShape(topObject);
                this.updateControlPoints();
                event.consume();
            }
        }
    }

    protected void dragWholeShape(DragSelectEvent dragEvent, Object topObject)
    {
        if (!(topObject instanceof Movable))
            return;

        Movable dragObject = (Movable) topObject;

        View view = wwd.getView();
        Globe globe = wwd.getModel().getGlobe();

        // Compute ref-point position in screen coordinates. Since the shape implicitly follows the surface
        // geometry, we will override the reference elevation with the current surface elevation. This will improve
        // cursor tracking in areas where the elevations are far from zero.
        Position refPos = dragObject.getReferencePosition();
        if (refPos == null)
            return;

        double refElevation = this.computeSurfaceElevation(wwd, refPos);
        refPos = new Position(refPos, refElevation);
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
            dragObject.moveTo(p);
        }
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

        if (this.shape instanceof SurfacePolygon)
            this.reshapeSurfacePolygon(terrainObject.getPosition(), (ControlPointMarker) topObject);
        else if (this.shape instanceof SurfacePolyline)
            this.reshapeSurfacePolyline(terrainObject.getPosition(), (ControlPointMarker) topObject);
        else if (this.shape instanceof SurfaceCircle)
            this.reshapeSurfaceCircle(terrainObject.getPosition(), (ControlPointMarker) topObject);
        else if (this.shape instanceof SurfaceSquare)
            this.reshapeSurfaceSquare(terrainObject.getPosition(), (ControlPointMarker) topObject);
        else if (this.shape instanceof SurfaceQuad)
            this.reshapeSurfaceQuad(terrainObject.getPosition(), (ControlPointMarker) topObject);
        else if (this.shape instanceof SurfaceEllipse)
            this.reshapeSurfaceEllipse(terrainObject.getPosition(), (ControlPointMarker) topObject);

        this.previousPosition = terrainObject.getPosition();
    }

    protected void updateControlPoints()
    {
        if (this.shape instanceof SurfacePolygon || this.shape instanceof SurfacePolyline)
            this.updateSurfacePolygonControlPoints();
        else if (this.shape instanceof SurfaceCircle)
            this.updateSurfaceCircleControlPoints();
        else if (this.shape instanceof SurfaceSquare)
            this.updateSurfaceSquareControlPoints();
        else if (this.shape instanceof SurfaceQuad)
            this.updateSurfaceQuadControlPoints();
        else if (this.shape instanceof SurfaceEllipse)
            this.updateSurfaceEllipseControlPoints();
    }

    protected double computeSurfaceElevation(WorldWindow wwd, LatLon latLon)
    {
        SectorGeometryList sgl = wwd.getSceneController().getTerrain();
        if (sgl != null)
        {
            Vec4 point = sgl.getSurfacePoint(latLon.getLatitude(), latLon.getLongitude(), 0.0);
            if (point != null)
            {
                Position pos = wwd.getModel().getGlobe().computePositionFromPoint(point);
                return pos.getElevation();
            }
        }

        return wwd.getModel().getGlobe().getElevation(latLon.getLatitude(), latLon.getLongitude());
    }

    protected void reshapeSurfacePolygon(Position terrainPosition, ControlPointMarker controlPoint)
    {
        java.util.List<LatLon> locations = new ArrayList<LatLon>();
        for (LatLon ll : ((SurfacePolygon) this.shape).getLocations())
        {
            locations.add(ll);
        }

        Vec4 terrainPoint = wwd.getModel().getGlobe().computeEllipsoidalPointFromLocation(terrainPosition);
        Vec4 previousPoint = wwd.getModel().getGlobe().computeEllipsoidalPointFromLocation(this.previousPosition);
        Vec4 delta = terrainPoint.subtract3(previousPoint);

        Vec4 markerPoint = wwd.getModel().getGlobe().computeEllipsoidalPointFromLocation(controlPoint.getPosition());
        Position markerPosition = wwd.getModel().getGlobe().computePositionFromEllipsoidalPoint(
            markerPoint.add3(delta));

        locations.set(controlPoint.getIndex(), markerPosition);
        ((SurfacePolygon) this.shape).setLocations(locations);
    }

    protected void reshapeSurfacePolyline(Position terrainPosition, ControlPointMarker controlPoint)
    {
        java.util.List<LatLon> locations = new ArrayList<LatLon>();
        for (LatLon ll : ((SurfacePolyline) this.shape).getLocations())
        {
            locations.add(ll);
        }

        Vec4 terrainPoint = wwd.getModel().getGlobe().computeEllipsoidalPointFromLocation(terrainPosition);
        Vec4 previousPoint = wwd.getModel().getGlobe().computeEllipsoidalPointFromLocation(this.previousPosition);
        Vec4 delta = terrainPoint.subtract3(previousPoint);

        Vec4 markerPoint = wwd.getModel().getGlobe().computeEllipsoidalPointFromLocation(controlPoint.getPosition());
        Position markerPosition = wwd.getModel().getGlobe().computePositionFromEllipsoidalPoint(
            markerPoint.add3(delta));

        locations.set(controlPoint.getIndex(), markerPosition);
        ((SurfacePolyline) this.shape).setLocations(locations);
    }

    protected void reshapeSurfaceCircle(Position terrainPosition, ControlPointMarker controlPoint)
    {
        SurfaceCircle circle = (SurfaceCircle) this.shape;

        Vec4 terrainPoint = wwd.getModel().getGlobe().computeEllipsoidalPointFromLocation(terrainPosition);
        Vec4 previousPoint = wwd.getModel().getGlobe().computeEllipsoidalPointFromLocation(this.previousPosition);
        Vec4 delta = terrainPoint.subtract3(previousPoint);

        Vec4 centerPoint = wwd.getModel().getGlobe().computeEllipsoidalPointFromLocation(circle.getCenter());
        Vec4 markerPoint = wwd.getModel().getGlobe().computeEllipsoidalPointFromLocation(controlPoint.getPosition());
        Vec4 vMarker = markerPoint.subtract3(centerPoint).normalize3();

        double radius = circle.getRadius() + delta.dot3(vMarker);
        if (radius > 0)
            circle.setRadius(radius);
    }

    protected void reshapeSurfaceSquare(Position terrainPosition, ControlPointMarker controlPoint)
    {
        SurfaceSquare square = (SurfaceSquare) this.shape;

        Vec4 terrainPoint = wwd.getModel().getGlobe().computeEllipsoidalPointFromLocation(terrainPosition);
        Vec4 previousPoint = wwd.getModel().getGlobe().computeEllipsoidalPointFromLocation(this.previousPosition);
        Vec4 delta = terrainPoint.subtract3(previousPoint);

        Vec4 centerPoint = wwd.getModel().getGlobe().computeEllipsoidalPointFromLocation(square.getCenter());
        Vec4 markerPoint = wwd.getModel().getGlobe().computeEllipsoidalPointFromLocation(controlPoint.getPosition());
        Vec4 vMarker = markerPoint.subtract3(centerPoint);

        if (controlPoint.getIndex() == 0)
        {
            double size = square.getSize() + delta.dot3(vMarker.normalize3());
            if (size > 0)
                square.setSize(size);
        }
        else
        {
            double deltaAngle = this.computeHeadingDelta(centerPoint, previousPoint, terrainPoint, delta);
            square.setHeading(Angle.fromRadians(square.getHeading().getRadians() + deltaAngle));
        }
    }

    protected void reshapeSurfaceQuad(Position terrainPosition, ControlPointMarker controlPoint)
    {
        SurfaceQuad quad = (SurfaceQuad) this.shape;

        Vec4 terrainPoint = wwd.getModel().getGlobe().computeEllipsoidalPointFromLocation(terrainPosition);
        Vec4 previousPoint = wwd.getModel().getGlobe().computeEllipsoidalPointFromLocation(this.previousPosition);
        Vec4 delta = terrainPoint.subtract3(previousPoint);

        Vec4 centerPoint = wwd.getModel().getGlobe().computeEllipsoidalPointFromLocation(quad.getCenter());
        Vec4 markerPoint = wwd.getModel().getGlobe().computeEllipsoidalPointFromLocation(controlPoint.getPosition());
        Vec4 vMarker = markerPoint.subtract3(centerPoint).normalize3();

        if (controlPoint.getIndex() != 2)
        {
            double width = quad.getWidth() + (controlPoint.getIndex() == 0 ? delta.dot3(vMarker) : 0);
            double height = quad.getHeight() + (controlPoint.getIndex() == 1 ? delta.dot3(vMarker) : 0);
            if (width > 0 && height > 0)
                quad.setSize(width, height);
        }
        else
        {
            double deltaAngle = this.computeHeadingDelta(centerPoint, previousPoint, terrainPoint, delta);
            quad.setHeading(Angle.fromRadians(quad.getHeading().getRadians() + deltaAngle));
        }
    }

    protected void reshapeSurfaceEllipse(Position terrainPosition, ControlPointMarker controlPoint)
    {
        SurfaceEllipse ellipse = (SurfaceEllipse) this.shape;

        Vec4 terrainPoint = wwd.getModel().getGlobe().computeEllipsoidalPointFromLocation(terrainPosition);
        Vec4 previousPoint = wwd.getModel().getGlobe().computeEllipsoidalPointFromLocation(this.previousPosition);
        Vec4 delta = terrainPoint.subtract3(previousPoint);

        Vec4 centerPoint = wwd.getModel().getGlobe().computeEllipsoidalPointFromLocation(ellipse.getCenter());
        Vec4 markerPoint = wwd.getModel().getGlobe().computeEllipsoidalPointFromLocation(controlPoint.getPosition());
        Vec4 vMarker = markerPoint.subtract3(centerPoint).normalize3();

        if (controlPoint.getIndex() != 2)
        {
            double majorRadius = ellipse.getMajorRadius() + (controlPoint.getIndex() == 0 ? delta.dot3(vMarker) : 0);
            double minorRadius = ellipse.getMinorRadius() + (controlPoint.getIndex() == 1 ? delta.dot3(vMarker) : 0);
            if (majorRadius > 0 && minorRadius > 0)
                ellipse.setRadii(majorRadius, minorRadius);
        }
        else
        {
            double deltaAngle = this.computeHeadingDelta(centerPoint, previousPoint, terrainPoint, delta);
            ellipse.setHeading(Angle.fromRadians(ellipse.getHeading().getRadians() + deltaAngle));
        }

        this.updateAnnotation(controlPoint);
    }

    protected void updateSurfacePolygonControlPoints()
    {
        Iterable<? extends LatLon> corners = null;

        if (this.shape instanceof SurfacePolygon)
            corners = ((SurfacePolygon) this.shape).getLocations();
        else if (this.shape instanceof SurfacePolyline)
            corners = ((SurfacePolyline) this.shape).getLocations();

        if (corners == null)
            return;

        Iterable<Marker> markers = this.controlPointLayer.getMarkers();
        if (markers == null)
        {
            double d = LatLon.getAverageDistance(corners).radians * wwd.getModel().getGlobe().getRadius();
            MarkerAttributes markerAttrs =
                new BasicMarkerAttributes(Material.BLUE, BasicMarkerShape.SPHERE, 0.7, 10, 0.1, d / 30);

            ArrayList<Marker> controlPoints = new ArrayList<Marker>();
            int i = 0;
            for (LatLon corner : corners)
            {
                controlPoints.add(new ControlPointMarker(new Position(corner, 0), markerAttrs, i++));
            }

            this.controlPointLayer.setMarkers(controlPoints);
        }
        else
        {
            Iterator<Marker> markerIterator = markers.iterator();
            for (LatLon cpPosition : corners)
            {
                markerIterator.next().setPosition(new Position(cpPosition, 0));
            }
        }
    }

    protected void updateSurfaceCircleControlPoints()
    {
        SurfaceCircle circle = (SurfaceCircle) this.shape;

        LatLon cpPosition = LatLon.greatCircleEndPosition(circle.getCenter(), Angle.fromDegrees(90),
            Angle.fromRadians(circle.getRadius() / this.wwd.getModel().getGlobe().getEquatorialRadius()));

        Iterable<Marker> markers = this.controlPointLayer.getMarkers();
        if (markers == null)
        {
            MarkerAttributes markerAttrs =
                new BasicMarkerAttributes(Material.BLUE, BasicMarkerShape.SPHERE, 0.7, 10, 0.1,
                    0.1 * circle.getRadius());

            java.util.List<Marker> markerList = new ArrayList<Marker>(1);
            markerList.add(new ControlPointMarker(new Position(cpPosition, 0), markerAttrs, 0));
            this.controlPointLayer.setMarkers(markerList);
        }
        else
        {
            markers.iterator().next().setPosition(new Position(cpPosition, 0));
        }

        Iterator<Marker> markerIterator = this.controlPointLayer.getMarkers().iterator();
        ((ControlPointMarker) markerIterator.next()).size = circle.getRadius();
    }

    protected void updateSurfaceSquareControlPoints()
    {
        SurfaceSquare square = (SurfaceSquare) this.shape;

        LatLon cpPosition = LatLon.greatCircleEndPosition(square.getCenter(),
            Angle.fromDegrees(90 + square.getHeading().degrees),
            Angle.fromRadians(0.5 * square.getSize() / this.wwd.getModel().getGlobe().getEquatorialRadius()));

        LatLon cpPositionR = LatLon.greatCircleEndPosition(square.getCenter(),
            Angle.fromDegrees(square.getHeading().degrees),
            Angle.fromRadians(0.7 * square.getSize() / this.wwd.getModel().getGlobe().getEquatorialRadius()));

        Iterable<Marker> markers = this.controlPointLayer.getMarkers();
        if (markers == null)
        {
            MarkerAttributes markerAttrs =
                new BasicMarkerAttributes(Material.BLUE, BasicMarkerShape.SPHERE, 0.7, 10, 0.1, 0.1 * square.getSize());

            java.util.List<Marker> markerList = new ArrayList<Marker>(1);
            markerList.add(new ControlPointMarker(new Position(cpPosition, 0), markerAttrs, 0));

            markerAttrs =
                new BasicMarkerAttributes(Material.GREEN, BasicMarkerShape.SPHERE, 1, 10, 0.1,
                    0.1 * square.getSize());
            markerList.add(new ControlPointMarker(new Position(cpPositionR, 0), markerAttrs, 1));

            this.controlPointLayer.setMarkers(markerList);
        }
        else
        {
            Iterator<Marker> markerIterator = markers.iterator();
            markerIterator.next().setPosition(new Position(cpPosition, 0));
            markerIterator.next().setPosition(new Position(cpPositionR, 0));
        }

        Iterator<Marker> markerIterator = this.controlPointLayer.getMarkers().iterator();
        ((ControlPointMarker) markerIterator.next()).size = square.getSize();
        ((ControlPointMarker) markerIterator.next()).rotation = square.getHeading();

        this.updateRotationLine(square.getCenter(), cpPositionR);
    }

    protected void updateSurfaceQuadControlPoints()
    {
        SurfaceQuad quad = (SurfaceQuad) this.shape;

        LatLon cpPositionW = LatLon.greatCircleEndPosition(quad.getCenter(),
            Angle.fromDegrees(90 + quad.getHeading().degrees),
            Angle.fromRadians(0.5 * quad.getWidth() / this.wwd.getModel().getGlobe().getEquatorialRadius()));

        LatLon cpPositionH = LatLon.greatCircleEndPosition(quad.getCenter(),
            Angle.fromDegrees(quad.getHeading().degrees),
            Angle.fromRadians(0.5 * quad.getHeight() / this.wwd.getModel().getGlobe().getEquatorialRadius()));

        LatLon cpPositionR = LatLon.greatCircleEndPosition(quad.getCenter(),
            Angle.fromDegrees(quad.getHeading().degrees),
            Angle.fromRadians(0.7 * quad.getHeight() / this.wwd.getModel().getGlobe().getEquatorialRadius()));

        Iterable<Marker> markers = this.controlPointLayer.getMarkers();
        if (markers == null)
        {
            MarkerAttributes markerAttrs =
                new BasicMarkerAttributes(Material.BLUE, BasicMarkerShape.SPHERE, 0.7, 10, 0.1, 0.1 * quad.getWidth());

            java.util.List<Marker> markerList = new ArrayList<Marker>(2);
            markerList.add(new ControlPointMarker(new Position(cpPositionW, 0), markerAttrs, 0));
            this.controlPointLayer.setMarkers(markerList);
            markerList.add(new ControlPointMarker(new Position(cpPositionH, 0), markerAttrs, 1));

            markerAttrs =
                new BasicMarkerAttributes(Material.GREEN, BasicMarkerShape.SPHERE, 1, 10, 0.1, 0.1 * quad.getWidth());
            markerList.add(new ControlPointMarker(new Position(cpPositionR, 0), markerAttrs, 2));

            this.controlPointLayer.setMarkers(markerList);
        }
        else
        {
            Iterator<Marker> markerIterator = markers.iterator();
            markerIterator.next().setPosition(new Position(cpPositionW, 0));
            markerIterator.next().setPosition(new Position(cpPositionH, 0));
            markerIterator.next().setPosition(new Position(cpPositionR, 0));
        }

        Iterator<Marker> markerIterator = this.controlPointLayer.getMarkers().iterator();
        ((ControlPointMarker) markerIterator.next()).size = quad.getWidth();
        ((ControlPointMarker) markerIterator.next()).size = quad.getHeight();
        ((ControlPointMarker) markerIterator.next()).rotation = quad.getHeading();

        this.updateRotationLine(quad.getCenter(), cpPositionR);
    }

    protected void updateSurfaceEllipseControlPoints()
    {
        SurfaceEllipse ellipse = (SurfaceEllipse) this.shape;

        LatLon cpPositionW = LatLon.greatCircleEndPosition(ellipse.getCenter(),
            Angle.fromDegrees(90 + ellipse.getHeading().degrees),
            Angle.fromRadians(ellipse.getMajorRadius() / this.wwd.getModel().getGlobe().getEquatorialRadius()));

        LatLon cpPositionH = LatLon.greatCircleEndPosition(ellipse.getCenter(),
            Angle.fromDegrees(ellipse.getHeading().degrees),
            Angle.fromRadians(ellipse.getMinorRadius() / this.wwd.getModel().getGlobe().getEquatorialRadius()));

        LatLon cpPositionR = LatLon.greatCircleEndPosition(ellipse.getCenter(),
            Angle.fromDegrees(ellipse.getHeading().degrees),
            Angle.fromRadians(1.15 * ellipse.getMinorRadius() / this.wwd.getModel().getGlobe().getEquatorialRadius()));

        Iterable<Marker> markers = this.controlPointLayer.getMarkers();
        if (markers == null)
        {
            MarkerAttributes markerAttrs =
                new BasicMarkerAttributes(Material.BLUE, BasicMarkerShape.SPHERE, 0.7, 10, 0.1,
                    0.1 * ellipse.getMajorRadius());

            java.util.List<Marker> markerList = new ArrayList<Marker>(2);
            markerList.add(new ControlPointMarker(new Position(cpPositionW, 0), markerAttrs, 0));
            this.controlPointLayer.setMarkers(markerList);
            markerList.add(new ControlPointMarker(new Position(cpPositionH, 0), markerAttrs, 1));

            markerAttrs =
                new BasicMarkerAttributes(Material.GREEN, BasicMarkerShape.SPHERE, 1, 10, 0.1,
                    0.1 * ellipse.getMajorRadius());
            markerList.add(new ControlPointMarker(new Position(cpPositionR, 0), markerAttrs, 2));

            this.controlPointLayer.setMarkers(markerList);
        }
        else
        {
            Iterator<Marker> markerIterator = markers.iterator();
            markerIterator.next().setPosition(new Position(cpPositionW, 0));
            markerIterator.next().setPosition(new Position(cpPositionH, 0));
            markerIterator.next().setPosition(new Position(cpPositionR, 0));
        }

        Iterator<Marker> markerIterator = this.controlPointLayer.getMarkers().iterator();
        ((ControlPointMarker) markerIterator.next()).size = ellipse.getMajorRadius();
        ((ControlPointMarker) markerIterator.next()).size = ellipse.getMinorRadius();
        ((ControlPointMarker) markerIterator.next()).rotation = ellipse.getHeading();

        this.updateRotationLine(ellipse.getCenter(), cpPositionR);
    }

    protected void updateRotationLine(LatLon centerPosition, LatLon cpPositionR)
    {
        java.util.List<LatLon> lineLocations = new ArrayList<LatLon>(2);
        lineLocations.add(centerPosition);
        lineLocations.add(cpPositionR);
        SurfacePolyline rotationLine = (SurfacePolyline) this.accessoryLayer.getRenderables().iterator().next();
        rotationLine.setLocations(lineLocations);
    }

    protected void updateShapeAnnotation(SurfaceShape shape)
    {
        LatLon center = null;
        if (shape instanceof SurfaceEllipse)
            center = ((SurfaceEllipse) shape).getCenter();
        else if (shape instanceof SurfaceQuad)
            center = ((SurfaceQuad) shape).getCenter();

        if (center != null)
        {
            ControlPointMarker dummyMarker = new ControlPointMarker(new Position(center, 0),
                new BasicMarkerAttributes(), 0);
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

        Vec4 mcPoint = wwd.getModel().getGlobe().computePointFromLocation(marker.getPosition());
        Vec4 screenPoint = wwd.getView().project(mcPoint);
        this.annotation.setScreenPoint(new Point((int) screenPoint.x, (int) screenPoint.y));

        String annotationText = marker.getPosition().toString();
        if (marker.size != null)
            annotationText = marker.size.toString();
        else if (marker.rotation != null)
            annotationText = marker.rotation.toString();

        this.annotation.setText(annotationText);
    }

    protected double computeHeadingDelta(Vec4 centerPoint, Vec4 previousPoint, Vec4 terrainPoint, Vec4 delta)
    {
        Vec4 vP = previousPoint.subtract3(centerPoint);
        Vec4 vT = terrainPoint.subtract3(centerPoint);
        Vec4 cross = vT.cross3(vP);
        double sign = cross.z >= 0 ? -1 : 1;

        return sign * Math.atan2(delta.getLength3(), vP.getLength3());
    }

    public class EditorAnnotation extends ScreenAnnotation
    {
        private Point tooltipOffset = new Point(5, 5);

        /**
         * Create a tool tip using specified text.
         *
         * @param text the text to display in the tool tip.
         */
        public EditorAnnotation(String text)
        {
            super(text, new Point(0, 0)); // (0,0) is a dummy; the actual point is determined when rendering

            this.initializeAttributes();
        }

        protected void initializeAttributes()
        {
            this.attributes.setAdjustWidthToText(AVKey.SIZE_FIT_TEXT);
            this.attributes.setFrameShape(AVKey.SHAPE_RECTANGLE);
            this.attributes.setTextColor(Color.BLACK);
            this.attributes.setBackgroundColor(new Color(1f, 1f, 1f, 0.8f));
            this.attributes.setCornerRadius(5);
            this.attributes.setBorderColor(new Color(0xababab));
            this.attributes.setFont(Font.decode("Arial-PLAIN-12"));
            this.attributes.setTextAlign(AVKey.CENTER);
            this.attributes.setInsets(new Insets(5, 5, 5, 5));
        }

        protected int getOffsetX()
        {
            return this.tooltipOffset != null ? this.tooltipOffset.x : 0;
        }

        protected int getOffsetY()
        {
            return this.tooltipOffset != null ? this.tooltipOffset.y : 0;
        }

        @Override
        protected void doRenderNow(DrawContext dc)
        {
            this.getAttributes().setDrawOffset(
                new Point(this.getBounds(dc).width / 2 + this.getOffsetX(), this.getOffsetY()));
            this.setScreenPoint(this.adjustDrawPointToViewport(this.getScreenPoint(), this.getBounds(dc),
                dc.getView().getViewport()));

            super.doRenderNow(dc);
        }

        protected Point adjustDrawPointToViewport(Point point, Rectangle bounds, Rectangle viewport) // TODO
        {
            return point;
//            int x = point.x;
//            int y = (int) viewport.getHeight() - point.y - 1;
//
//            if (x + this.getOffsetX() + bounds.getWidth() > viewport.getWidth())
//                x = (int) (viewport.getWidth() - bounds.getWidth()) - 1 - this.getOffsetX();
//            else if (x < 0)
//                x = 0;
//
//            if (y + this.getOffsetY() + bounds.getHeight() > viewport.getHeight())
//                y = (int) (viewport.getHeight() - bounds.getHeight()) - 1 - this.getOffsetY();
//            else if (y < 0)
//                y = bounds.height;
//
//            return new java.awt.Point(x, y);
        }
    }
}
