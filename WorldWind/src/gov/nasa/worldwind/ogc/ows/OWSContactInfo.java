/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.ogc.ows;

import gov.nasa.worldwind.util.xml.*;

/**
 * @author tag
 * @version $Id$
 */
public class OWSContactInfo extends AbstractXMLEventParser
{
    public OWSContactInfo(String namespaceURI)
    {
        super(namespaceURI);
    }

    public String getHoursOfService()
    {
        return (String) this.getField("HoursOfService");
    }

    public String getContactInstructions()
    {
        return (String) this.getField("ContactInstructions");
    }

    public OWSAddress getAddress()
    {
        return (OWSAddress) this.getField("Address");
    }

    public OWSPhone getPhone()
    {
        return (OWSPhone) this.getField("Phone");
    }

    public String getOnlineResource()
    {
        AttributesOnlyXMLEventParser parser = (AttributesOnlyXMLEventParser) this.getField("OnlineResource");

        return parser != null ? (String) parser.getField("href") : null;
    }
}
