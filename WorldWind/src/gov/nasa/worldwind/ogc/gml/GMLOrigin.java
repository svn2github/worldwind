/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.ogc.gml;

import gov.nasa.worldwind.util.xml.AbstractXMLEventParser;

/**
 * @author tag
 * @version $Id$
 */
public class GMLOrigin extends AbstractXMLEventParser
{
    public GMLOrigin(String namespaceURI)
    {
        super(namespaceURI);
    }

    public GMLPos getPos()
    {
        return (GMLPos) this.getField("pos");
    }
}
