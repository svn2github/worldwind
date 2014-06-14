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
public class WCS100ResponsibleParty extends AbstractXMLEventParser
{
    public WCS100ResponsibleParty(String namespaceURI)
    {
        super(namespaceURI);
    }

    public String getIndividualName()
    {
        return (String) this.getField("individualName");
    }

    public String getOrganisationName()
    {
        return (String) this.getField("organisationName");
    }

    public String getPositionName()
    {
        return (String) this.getField("positionName");
    }

    public WCS100ContactInfo getContactInfo()
    {
        return (WCS100ContactInfo) this.getField("contactInfo");
    }
}
