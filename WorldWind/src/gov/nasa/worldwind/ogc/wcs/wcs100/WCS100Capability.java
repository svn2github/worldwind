/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.ogc.wcs.wcs100;

import gov.nasa.worldwind.util.xml.AbstractXMLEventParser;

/**
 * @author tag
 * @version $Id$
 */
public class WCS100Capability extends AbstractXMLEventParser
{
    public WCS100Capability(String namespaceURI)
    {
        super(namespaceURI);
    }

    public WCS100Request getRequest()
    {
        return (WCS100Request) this.getField("Request");
    }

    public WCS100Exception getException()
    {
        return (WCS100Exception) this.getField("Exception");
    }
}
