/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.ogc.wcs.wcs100;

import gov.nasa.worldwind.util.xml.*;

/**
 * @author tag
 * @version $Id$
 */
public class WCS100ContactInfo extends AbstractXMLEventParser
{
    public WCS100ContactInfo(String namespaceURI)
    {
        super(namespaceURI);
    }

    public WCS100Phone getPhone()
    {
        return (WCS100Phone) this.getField("phone");
    }

    public WCS100Address getAddress()
    {
        return (WCS100Address) this.getField("address");
    }

    public AttributesOnlyXMLEventParser getOnlineResource()
    {
        return (AttributesOnlyXMLEventParser) this.getField("onlineResource");
    }
}
