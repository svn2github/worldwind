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
public class WCS100DomainSet extends AbstractXMLEventParser
{
    public WCS100DomainSet(String namespaceURI)
    {
        super(namespaceURI);
    }

    public WCS100SpatialDomain getSpatialDomain()
    {
        return (WCS100SpatialDomain) this.getField("spatialDomain");
    }
}
