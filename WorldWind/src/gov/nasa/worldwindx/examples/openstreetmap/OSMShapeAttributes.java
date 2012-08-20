/*
 * Copyright (C) 2012 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwindx.examples.openstreetmap;

import gov.nasa.worldwind.util.WWUtil;

import java.awt.*;

/**
 * Provides an attribute bundle for Open Street Map attributes. These attributes are specified via one or more
 * configuration files. They are mapped to World Wind shape attributes when shapes used to display nodes and ways are
 * created.
 *
 * @author tag
 * @version $Id$
 */
public class OSMShapeAttributes
{
    /** Way width. */
    protected double width;
    protected Color interiorColor;
    protected Color labelColor;
    protected Color markerColor;
    protected Color outlineColor;
    protected Font font;
    protected String iconPath;
    /**
     * The level determines the level of detail at which to show the OSM node or way. Higher levels are shown at lower
     * levels of detail, when the view is very close to the ground. The level field is consulted only during OSM data
     * caching. It is not used during OSM data display. Levels range from 0 to 7.
     */
    protected int level = OSMCacheBuilder.MAX_LEVEL; // default to highest resolution level

    /** Construct an instance with undefined values for all fields. */
    public OSMShapeAttributes()
    {
    }

    /**
     * Construct an instance with fields set to those of a specified instance.
     *
     * @param attributes an instance used to initialize the newly construced instance.
     */
    public OSMShapeAttributes(OSMShapeAttributes attributes)
    {
        this.copyFields(attributes);
    }

    protected void copyFields(OSMShapeAttributes attributes)
    {
        this.width = attributes.width;
        this.interiorColor = attributes.interiorColor;
        this.labelColor = attributes.labelColor;
        this.markerColor = attributes.markerColor;
        this.outlineColor = attributes.outlineColor;
        this.font = attributes.font;
        this.iconPath = attributes.iconPath;
        this.level = attributes.level;
    }

    /**
     * Construct an instance, assigning the fields specified by either default and parser-context fields.
     *
     * @param defaults  the defaults to use. If a field is not specified by the parser-context bundle, its value is
     *                  assigned the value in this argument's instance.
     * @param attribute a parser-context instance of an attribute bundle. Fields specified in this bundle are assigned
     *                  to the newly constructed attribute bundle.
     */
    public OSMShapeAttributes(OSMShapeAttributes defaults, OSMAttributesParserContext.Attribute attribute)
    {
        this.copyFields(defaults);

        if (attribute.getWidth() != null)
        {
            Double width = attribute.getWidth();
            if (width != null)
                this.width = width;
        }

        if (attribute.getInteriorColor() != null)
        {
            Color color = WWUtil.decodeColorRGBA(attribute.getInteriorColor());
            if (color != null)
                this.interiorColor = color;
        }

        if (attribute.getLabelColor() != null)
        {
            Color color = WWUtil.decodeColorRGBA(attribute.getLabelColor());
            if (color != null)
                this.labelColor = color;
        }

        if (attribute.getMarkerColor() != null)
        {
            Color color = WWUtil.decodeColorRGBA(attribute.getMarkerColor());
            if (color != null)
                this.markerColor = color;
        }

        if (attribute.getOutlineColor() != null)
        {
            Color color = WWUtil.decodeColorRGBA(attribute.getOutlineColor());
            if (color != null)
                this.outlineColor = color;
        }

        if (attribute.getFont() != null)
        {
            Font font = Font.decode(attribute.getFont());
            if (font != null)
                this.font = font;
        }

        if (attribute.getIconPath() != null)
        {
            this.iconPath = attribute.getIconPath();
        }

        if (attribute.getLevel() != null)
        {
            Integer level = attribute.getLevel();
            if (level != null)
                this.level = level;
        }
    }

    public double getWidth()
    {
        return width;
    }

    public void setWidth(double width)
    {
        this.width = width;
    }

    public Color getInteriorColor()
    {
        return interiorColor;
    }

    public void setInteriorColor(Color interiorColor)
    {
        this.interiorColor = interiorColor;
    }

    public Color getOutlineColor()
    {
        return outlineColor;
    }

    public void setOutlineColor(Color outlineColor)
    {
        this.outlineColor = outlineColor;
    }

    public Color getLabelColor()
    {
        return labelColor;
    }

    public void setLabelColor(Color labelColor)
    {
        this.labelColor = labelColor;
    }

    public Color getMarkerColor()
    {
        return markerColor;
    }

    public void setMarkerColor(Color markerColor)
    {
        this.markerColor = markerColor;
    }

    public Font getFont()
    {
        return font;
    }

    public void setFont(Font font)
    {
        this.font = font;
    }

    public String getIconPath()
    {
        return iconPath;
    }

    public void setIconPath(String iconPath)
    {
        this.iconPath = iconPath;
    }

    public int getLevel()
    {
        return level;
    }

    public void setLevel(int level)
    {
        this.level = level;
    }

    @Override
    public boolean equals(Object o)
    {
        if (this == o)
            return true;
        if (o == null || getClass() != o.getClass())
            return false;

        OSMShapeAttributes that = (OSMShapeAttributes) o;

        if (level != that.level)
            return false;
        if (Double.compare(that.width, width) != 0)
            return false;
        if (font != null ? !font.equals(that.font) : that.font != null)
            return false;
        if (iconPath != null ? !iconPath.equals(that.iconPath) : that.iconPath != null)
            return false;
        if (interiorColor != null ? !interiorColor.equals(that.interiorColor) : that.interiorColor != null)
            return false;
        if (labelColor != null ? !labelColor.equals(that.labelColor) : that.labelColor != null)
            return false;
        if (markerColor != null ? !markerColor.equals(that.markerColor) : that.markerColor != null)
            return false;
        if (outlineColor != null ? !outlineColor.equals(that.outlineColor) : that.outlineColor != null)
            return false;

        return true;
    }

    @Override
    public int hashCode()
    {
        int result;
        long temp;
        temp = width != +0.0d ? Double.doubleToLongBits(width) : 0L;
        result = (int) (temp ^ (temp >>> 32));
        result = 31 * result + (interiorColor != null ? interiorColor.hashCode() : 0);
        result = 31 * result + (labelColor != null ? labelColor.hashCode() : 0);
        result = 31 * result + (markerColor != null ? markerColor.hashCode() : 0);
        result = 31 * result + (outlineColor != null ? outlineColor.hashCode() : 0);
        result = 31 * result + (font != null ? font.hashCode() : 0);
        result = 31 * result + (iconPath != null ? iconPath.hashCode() : 0);
        result = 31 * result + level;
        return result;
    }
}
