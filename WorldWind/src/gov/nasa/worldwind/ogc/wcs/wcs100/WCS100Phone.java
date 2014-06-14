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
public class WCS100Phone extends AbstractXMLEventParser
{
    public WCS100Phone(String namespaceURI)
    {
        super(namespaceURI);
    }

    public String getVoice()
    {
        return (String) this.getField("voice");
    }

    public String getFacsimile()
    {
        return (String) this.getField("facsimile");
    }
}
