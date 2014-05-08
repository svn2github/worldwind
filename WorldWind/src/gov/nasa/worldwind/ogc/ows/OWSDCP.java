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
public class OWSDCP extends AbstractXMLEventParser
{
    public OWSDCP(String namespaceURI)
    {
        super(namespaceURI);
    }

    public OWSHTTP getHTTP()
    {
        return (OWSHTTP) this.getField("HTTP");
    }
}
