/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.ogc.ows;

import gov.nasa.worldwind.util.xml.AbstractXMLEventParser;

/**
 * @author tag
 * @version $Id$
 */
public class OWSWGS84BoundingBox extends AbstractXMLEventParser
{
    public OWSWGS84BoundingBox(String namespaceURI)
    {
        super(namespaceURI);
    }

    public String getLowerCorner()
    {
        return (String) this.getField("LowerCorner");
    }

    public String getUpperCorner()
    {
        return (String) this.getField("UpperCorner");
    }
}
