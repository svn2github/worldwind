/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwindx.examples;

import gov.nasa.worldwind.event.*;
import gov.nasa.worldwind.geom.*;
import gov.nasa.worldwind.layers.RenderableLayer;
import gov.nasa.worldwind.pick.PickedObject;
import gov.nasa.worldwind.render.*;
import gov.nasa.worldwind.util.SurfaceShapeEditor;

import java.awt.*;
import java.util.*;
import java.util.List;

/**
 * @author tag
 * @version $Id$
 */
public class SurfaceShapeEditing extends ApplicationTemplate
{
    public static class AppFrame extends ApplicationTemplate.AppFrame implements SelectListener
    {
        protected SurfaceShapeEditor editor;

        public AppFrame()
        {
            this.getWwd().addSelectListener(this);

            RenderableLayer layer = new RenderableLayer();

            ShapeAttributes attrs = new BasicShapeAttributes();
            attrs.setDrawInterior(true);
            attrs.setDrawOutline(true);
            attrs.setInteriorMaterial(new Material(Color.WHITE));
            attrs.setOutlineMaterial(new Material(Color.BLACK));
            attrs.setOutlineWidth(2);
            attrs.setInteriorOpacity(0.7);

            ShapeAttributes highlightAttrs = new BasicShapeAttributes(attrs);
            highlightAttrs.setOutlineMaterial(new Material(Color.RED));

            List<LatLon> locations = new ArrayList<LatLon>();
            locations.add(LatLon.fromDegrees(40, -121));
            locations.add(LatLon.fromDegrees(40, -120));
            locations.add(LatLon.fromDegrees(41, -120));
            locations.add(LatLon.fromDegrees(41, -121));
            SurfacePolygon polygon = new SurfacePolygon(attrs, locations);
            polygon.setHighlightAttributes(highlightAttrs);
            layer.addRenderable(polygon);

            locations = new ArrayList<LatLon>();
            locations.add(LatLon.fromDegrees(40, -119));
            locations.add(LatLon.fromDegrees(40, -118));
            locations.add(LatLon.fromDegrees(41, -118));
            locations.add(LatLon.fromDegrees(41, -119));
            SurfacePolyline polyline = new SurfacePolyline(attrs, locations);
            polyline.setHighlightAttributes(highlightAttrs);
            layer.addRenderable(polyline);

            SurfaceCircle circle = new SurfaceCircle(attrs, LatLon.fromDegrees(40.5, -116), 1e5);
            circle.setHighlightAttributes(highlightAttrs);
            layer.addRenderable(circle);

            SurfaceSquare square = new SurfaceSquare(attrs, LatLon.fromDegrees(40.5, -113), 1e5);
            square.setHeading(Angle.fromDegrees(30));
            square.setHighlightAttributes(highlightAttrs);
            layer.addRenderable(square);

            SurfaceQuad quad = new SurfaceQuad(attrs, LatLon.fromDegrees(40.5, -111), 1e5, 1e5);
            quad.setHeading(Angle.fromDegrees(30));
            quad.setHighlightAttributes(highlightAttrs);
            layer.addRenderable(quad);

            SurfaceEllipse ellipse = new SurfaceEllipse(attrs, LatLon.fromDegrees(40.5, -108), 1e5, 1.5e5);
            ellipse.setHeading(Angle.fromDegrees(30));
            ellipse.setHighlightAttributes(highlightAttrs);
            layer.addRenderable(ellipse);

            insertBeforePlacenames(getWwd(), layer);
        }

        @Override
        public void selected(SelectEvent event)
        {
            PickedObject topObject = event.getTopPickedObject();

            if (event.getEventAction().equals(SelectEvent.LEFT_PRESS))
            {
                if (topObject != null && topObject.getObject() instanceof SurfaceShape)
                {
                    if (this.editor == null)
                    {
                        this.editor = new SurfaceShapeEditor(getWwd(), (SurfaceShape) topObject.getObject());
                        this.editor.setArmed(true);
                        event.consume();
                    }
                    else if (this.editor.getSurfaceShape() != event.getTopObject())
                    {
                        this.editor.setArmed(false);
                        this.editor = new SurfaceShapeEditor(getWwd(), (SurfaceShape) topObject.getObject());
                        this.editor.setArmed(true);
                        event.consume();
                    }
                }
            }
        }
    }

    public static void main(String[] args)
    {
        ApplicationTemplate.start("World Wind Surface Shape Editing", SurfaceShapeEditing.AppFrame.class);
    }
}
