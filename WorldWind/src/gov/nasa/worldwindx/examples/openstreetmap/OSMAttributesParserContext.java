/*
 * Copyright (C) 2012 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwindx.examples.openstreetmap;

import gov.nasa.worldwind.util.xml.*;

import javax.xml.namespace.QName;

/**
 * A parser context for Open Street Map configuration attributes. Used by {@link OSMShapeFactory}.
 *
 * @author tag
 * @version $Id$
 */
public class OSMAttributesParserContext extends BasicXMLEventParserContext
{
    public final static String MIME_TYPE = "application/worldwind-osm-attribute.xml";
    public final static String NAMESPACE = "http://gov.nasa.worldwind.openstreetmap.attributes/1.0";

    public static class OSMAttributeObject extends AbstractXMLEventParser
    {
        public OSMAttributeObject(String namespaceURI)
        {
            super(namespaceURI);
        }

        public String getFeatureType()
        {
            return (String) this.getField("featureType");
        }

        public String getKey()
        {
            return (String) this.getField("key");
        }

        public String getValue()
        {
            return (String) this.getField("value");
        }

        public String getFlag()
        {
            return (String) this.getField("flag");
        }
    }

    public static class Exclusion extends OSMAttributeObject
    {
        public Exclusion(String namespaceURI)
        {
            super(namespaceURI);
        }
    }

    public static class Attribute extends OSMAttributeObject
    {
        public Attribute(String namespaceURI)
        {
            super(namespaceURI);
        }

        public String getLabelColor()
        {
            return (String) this.getField("labelColor");
        }

        public String getInteriorColor()
        {
            return (String) this.getField("interiorColor");
        }

        public String getOutlineColor()
        {
            return (String) this.getField("outlineColor");
        }

        public String getMarkerColor()
        {
            return (String) this.getField("markerColor");
        }

        public String getFont()
        {
            return (String) this.getField("font");
        }

        public String getIconPath()
        {
            return (String) this.getField("iconPath");
        }

        public Double getWidth()
        {
            return (Double) this.getField("width");
        }

        public Integer getLevel()
        {
            return (Integer) this.getField("level");
        }
    }

    public OSMAttributesParserContext()
    {
        this.initialize();
    }

    public OSMAttributesParserContext(OSMAttributesParserContext ctx)
    {
        super(ctx);
    }

    @Override
    public String getDefaultNamespaceURI()
    {
        return NAMESPACE;
    }

    protected static final String[] StringFields = new String[]
        {
            // Only element names, not attribute names, are needed here.
            "font",
            "iconPath",
            "interiorColor",
            "labelColor",
            "markerColor",
            "outlineColor",
        };

    protected void initialize()
    {
        super.initializeParsers();

        this.parsers.put(new QName(NAMESPACE, "exclude"), new Exclusion(NAMESPACE));
        this.parsers.put(new QName(NAMESPACE, "attribute"), new Attribute(NAMESPACE));

        this.addStringParsers(NAMESPACE, StringFields);
        this.addIntegerParsers(NAMESPACE, new String[] {"level"});
        this.addDoubleParsers(NAMESPACE, new String[] {"width"});
    }
}
