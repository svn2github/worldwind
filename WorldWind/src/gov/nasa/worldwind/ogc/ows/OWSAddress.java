/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.ogc.ows;

import gov.nasa.worldwind.util.WWUtil;
import gov.nasa.worldwind.util.xml.*;

import javax.xml.stream.XMLStreamException;
import javax.xml.stream.events.XMLEvent;
import java.util.*;

/**
 * @author tag
 * @version $Id$
 */
public class OWSAddress extends AbstractXMLEventParser
{
    protected Set<String> deliveryPoints = new HashSet<String>(1);
    protected Set<String> postalCodes = new HashSet<String>(1);
    protected Set<String> countries = new HashSet<String>(1);
    protected Set<String> emails = new HashSet<String>(1);

    public OWSAddress(String namespaceURI)
    {
        super(namespaceURI);
    }

    public String getCity()
    {
        return (String) this.getField("City");
    }

    public String getAdministrativeArea()
    {
        return (String) this.getField("AdministrativeArea");
    }

    public Set<String> getDeliveryPoints()
    {
        return this.deliveryPoints;
    }

    public Set<String> getPostalCodes()
    {
        return this.postalCodes;
    }

    public Set<String> getCountries()
    {
        return this.countries;
    }

    public Set<String> getElectronicMailAddresses()
    {
        return this.emails;
    }

    protected void doParseEventContent(XMLEventParserContext ctx, XMLEvent event, Object... args)
        throws XMLStreamException
    {
        if (ctx.isStartElement(event, "DeliveryPoint"))
        {
            String s = ctx.getStringParser().parseString(ctx, event);
            if (!WWUtil.isEmpty(s))
                this.deliveryPoints.add(s);
        }
        else if (ctx.isStartElement(event, "PostalCode"))
        {
            String s = ctx.getStringParser().parseString(ctx, event);
            if (!WWUtil.isEmpty(s))
                this.postalCodes.add(s);
        }
        else if (ctx.isStartElement(event, "Country"))
        {
            String s = ctx.getStringParser().parseString(ctx, event);
            if (!WWUtil.isEmpty(s))
                this.countries.add(s);
        }
        else if (ctx.isStartElement(event, "ElectronicMailAddress"))
        {
            String s = ctx.getStringParser().parseString(ctx, event);
            if (!WWUtil.isEmpty(s))
                this.emails.add(s);
        }
        else
        {
            super.doParseEventContent(ctx, event, args);
        }
    }
}
