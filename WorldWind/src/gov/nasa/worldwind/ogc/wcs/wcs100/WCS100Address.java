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
public class WCS100Address extends AbstractXMLEventParser
{
    public WCS100Address(String namespaceURI)
    {
        super(namespaceURI);
    }

    public String getDeliveryPoint()
    {
        return (String) this.getField("deliveryPoint");
    }

    public String getCity()
    {
        return (String) this.getField("city");
    }

    public String getAdministrativeArea()
    {
        return (String) this.getField("administrativeArea");
    }

    public String getPostalCode()
    {
        return (String) this.getField("postalCode");
    }

    public String getCountry()
    {
        return (String) this.getField("country");
    }

    public String getElectronicMailAddress()
    {
        return (String) this.getField("electronicMailAddress");
    }
}
