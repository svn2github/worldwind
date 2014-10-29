/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */
package gov.nasa.worldwindx.examples;

import gov.nasa.worldwind.avlist.AVKey;
import gov.nasa.worldwind.geom.*;
import gov.nasa.worldwind.globes.Globe;
import gov.nasa.worldwind.layers.RenderableLayer;
import gov.nasa.worldwind.render.*;
import gov.nasa.worldwind.util.ContourList;
import gov.nasa.worldwind.util.combine.ShapeCombiner;

/**
 * @author dcollins
 * @version $Id$
 */
public class ShapeCombining extends ApplicationTemplate
{
    public static class AppFrame extends ApplicationTemplate.AppFrame
    {
        public AppFrame()
        {
            ShapeAttributes attrs = new BasicShapeAttributes();
            attrs.setInteriorOpacity(0.5);
            attrs.setOutlineWidth(2);

            SurfaceCircle shape1 = new SurfaceCircle(attrs, LatLon.fromDegrees(50, -105), 500000);
            shape1.setValue(AVKey.DISPLAY_NAME, "Original");

            SurfaceCircle shape2 = new SurfaceCircle(attrs, LatLon.fromDegrees(50, -100), 500000);
            shape2.setValue(AVKey.DISPLAY_NAME, "Original");

            RenderableLayer originalLayer = new RenderableLayer();
            originalLayer.setName("Original");
            originalLayer.addRenderable(shape1);
            originalLayer.addRenderable(shape2);
            this.getWwd().getModel().getLayers().add(originalLayer);

            Globe globe = this.getWwd().getModel().getGlobe();
            double resolutionRadians = 10000 / globe.getRadius(); // 10km resolution
            ShapeCombiner shapeCombiner = new ShapeCombiner(globe, resolutionRadians);

            ContourList union = shapeCombiner.union(shape1, shape2);
            this.displayContours(union, "Union", Position.fromDegrees(-10, 0, 0));

            ContourList intersection = shapeCombiner.intersection(shape1, shape2);
            this.displayContours(intersection, "Intersection", Position.fromDegrees(-20, 0, 0));

            ContourList difference = shapeCombiner.difference(shape1, shape2);
            this.displayContours(difference, "Difference", Position.fromDegrees(-30, 0, 0));
        }

        protected void displayContours(ContourList contours, String displayName, Position offset)
        {
            ShapeAttributes attrs = new BasicShapeAttributes();
            attrs.setInteriorMaterial(Material.CYAN);
            attrs.setInteriorOpacity(0.5);
            attrs.setOutlineMaterial(Material.WHITE);
            attrs.setOutlineWidth(2);

            SurfaceMultiPolygon shape = new SurfaceMultiPolygon(attrs, contours);
            shape.setValue(AVKey.DISPLAY_NAME, displayName);
            shape.setPathType(AVKey.LINEAR);
            shape.move(offset);

            RenderableLayer layer = new RenderableLayer();
            layer.setName(displayName);
            layer.addRenderable(shape);
            this.getWwd().getModel().getLayers().add(layer);
        }
    }

    public static void main(String[] args)
    {
        start("World Wind Shape Combining", AppFrame.class);
    }
}
