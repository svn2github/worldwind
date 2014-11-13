/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwindx.examples;

import gov.nasa.worldwind.WorldWind;
import gov.nasa.worldwind.avlist.AVKey;
import gov.nasa.worldwind.geom.*;
import gov.nasa.worldwind.layers.RenderableLayer;
import gov.nasa.worldwind.render.*;
import gov.nasa.worldwind.util.ContourBuilder;
import gov.nasa.worldwindx.examples.analytics.*;
import gov.nasa.worldwindx.examples.util.ExampleUtil;

import java.awt.*;
import java.util.*;
import java.util.List;

/**
 * @author dcollins
 * @version $Id$
 */
public class ContourBuilding extends ApplicationTemplate
{
    public static class AppFrame extends ApplicationTemplate.AppFrame
    {
        protected Sector gridSector;
        protected int gridWidth;
        protected int gridHeight;
        protected double[] gridValues;

        public AppFrame()
        {
            this.createGrid();

            RenderableLayer fieldLayer = new RenderableLayer();
            fieldLayer.setName("Grid Values");
            this.getWwd().getModel().getLayers().add(fieldLayer);
            this.addGridShapes(fieldLayer);

            RenderableLayer contourLayer = new RenderableLayer();
            contourLayer.setName("Contours");
            this.getWwd().getModel().getLayers().add(contourLayer);

            ContourBuilder cb = new ContourBuilder(this.gridWidth, this.gridHeight, this.gridValues);

            for (double value : Arrays.asList(0.083, 0.250, 0.416, 0.583, 0.75, 0.916))
            {
                List<List<Position>> contourList = cb.buildContourLines(value, this.gridSector, 0);
                this.addContourShapes(contourList, value, contourLayer);
            }
        }

        protected void createGrid()
        {
            this.gridSector = Sector.fromDegrees(20, 30, -110, -100);
            this.gridWidth = 60;
            this.gridHeight = 60;
            this.gridValues = ExampleUtil.readCommaDelimitedNumbers(
                "gov/nasa/worldwindx/examples/data/GridValues01_60x60.csv");
        }

        protected void addContourShapes(List<List<Position>> contourList, double value, RenderableLayer layer)
        {
            String text = this.textForValue(value);
            Color color = this.colorForValue(value, 1.0); // color for value at 100% brightness

            ShapeAttributes attrs = new BasicShapeAttributes();
            attrs.setOutlineMaterial(new Material(color));
            attrs.setOutlineWidth(2);

            for (List<Position> positions : contourList)
            {
                Path path = new Path(positions);
                path.setAttributes(attrs);
                path.setAltitudeMode(WorldWind.CLAMP_TO_GROUND);
                path.setFollowTerrain(true);
                path.setValue(AVKey.DISPLAY_NAME, text);
                layer.addRenderable(path);
            }
        }

        protected void addGridShapes(RenderableLayer layer)
        {
            ArrayList<AnalyticSurface.GridPointAttributes> pointAttrs =
                new ArrayList<AnalyticSurface.GridPointAttributes>();
            for (double value : this.gridValues)
            {
                Color color = this.colorForValue(value, 0.5); // color for value at 50% brightness
                pointAttrs.add(AnalyticSurface.createGridPointAttributes(value, color));
            }

            AnalyticSurfaceAttributes attrs = new AnalyticSurfaceAttributes();
            attrs.setDrawOutline(false);
            attrs.setDrawShadow(false);

            AnalyticSurface surface = new AnalyticSurface();
            surface.setSurfaceAttributes(attrs);
            surface.setSector(this.gridSector);
            surface.setDimensions(this.gridWidth, this.gridHeight);
            surface.setValues(pointAttrs);
            surface.setAltitudeMode(WorldWind.CLAMP_TO_GROUND);
            layer.addRenderable(surface);
        }

        protected Color colorForValue(double value, double brightness)
        {
            return Color.getHSBColor((float) value, 1.0f, (float) brightness); // use field value as hue
        }

        protected String textForValue(double value)
        {
            return String.format("%.0f%%", 100 * value); // use field value as percentage
        }
    }

    public static void main(String[] args)
    {
        start("World Wind Contour Building", AppFrame.class);
    }
}
