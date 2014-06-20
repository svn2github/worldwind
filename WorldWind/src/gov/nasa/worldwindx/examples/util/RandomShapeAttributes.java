/*
 * Copyright (C) 2012 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */
package gov.nasa.worldwindx.examples.util;

import gov.nasa.worldwind.render.*;
import gov.nasa.worldwind.util.WWUtil;

import java.awt.*;

/**
 * @author dcollins
 * @version $Id$
 */
public class RandomShapeAttributes
{
    protected int attrIndex = 0;
    protected PointPlacemarkAttributes[] pointAttrs;
    protected ShapeAttributes[] polylineAttrs;
    protected ShapeAttributes[] polygonAttrs;

    public RandomShapeAttributes()
    {
        this.initialize();
    }

    protected void initialize()
    {
        Color[] shapeColors = {
            new Color(255, 9, 84), // red
            new Color(255, 133, 0), // orange
            new Color(255, 198, 0), // yellow
            new Color(79, 213, 33), // green
            new Color(7, 152, 249), // blue
            new Color(193, 83, 220), // purple
        };

        this.pointAttrs = new PointPlacemarkAttributes[shapeColors.length];
        this.polylineAttrs = new ShapeAttributes[shapeColors.length];
        this.polygonAttrs = new ShapeAttributes[shapeColors.length];

        for (int i = 0; i < shapeColors.length; i++)
        {
            this.pointAttrs[i] = this.createPointAttributes(shapeColors[i]);
            this.polylineAttrs[i] = this.createPolylineAttributes(shapeColors[i]);
            this.polygonAttrs[i] = this.createPolygonAttributes(shapeColors[i]);
        }
    }

    public PointPlacemarkAttributes nextPointAttributes()
    {
        return this.pointAttrs[this.attrIndex++ % this.pointAttrs.length];
    }

    public ShapeAttributes nextPolylineAttributes()
    {
        return this.polylineAttrs[this.attrIndex++ % this.polylineAttrs.length];
    }

    public ShapeAttributes nextPolygonAttributes()
    {
        return this.polygonAttrs[this.attrIndex++ % this.polygonAttrs.length];
    }

    protected PointPlacemarkAttributes createPointAttributes(Color color)
    {
        PointPlacemarkAttributes attrs = new PointPlacemarkAttributes();
        attrs.setUsePointAsDefaultImage(true);
        attrs.setLineMaterial(new Material(color));
        attrs.setScale(7d);
        return attrs;
    }

    protected ShapeAttributes createPolylineAttributes(Color color)
    {
        ShapeAttributes attrs = new BasicShapeAttributes();
        attrs.setOutlineMaterial(new Material(color));
        attrs.setOutlineWidth(1.5);
        return attrs;
    }

    protected ShapeAttributes createPolygonAttributes(Color color)
    {
        ShapeAttributes attrs = new BasicShapeAttributes();
        attrs.setInteriorMaterial(new Material(color));
        attrs.setOutlineMaterial(new Material(WWUtil.makeColorDarker(color)));
        attrs.setInteriorOpacity(0.5);
        attrs.setOutlineWidth(1.5);
        return attrs;
    }
}
