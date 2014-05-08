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
public class OWSServiceIdentification extends AbstractXMLEventParser
{
    protected Set<String> abstracts = new HashSet<String>(1);
    protected Set<String> accessConstraints = new HashSet<String>(1);
    protected Set<String> profiles = new HashSet<String>(1);
    protected Set<String> titles = new HashSet<String>(1);
    protected Set<String> serviceTypeVersions = new HashSet<String>(1);

    public OWSServiceIdentification(String namespaceURI)
    {
        super(namespaceURI);
    }

    public Set<String> getTitles()
    {
        return this.titles;
    }

    public Set<String> getAbstracts()
    {
        return this.abstracts;
    }

    public Set<String> getKeywords()
    {
        return ((StringSetXMLEventParser) this.getField("Keywords")).getStrings();
    }

    public String getServiceType()
    {
        return (String) this.getField("ServiceType");
    }

    public Set<String> getServiceTypeVersions()
    {
        return this.serviceTypeVersions;
    }

    public String getFees()
    {
        return (String) this.getField("Fees");
    }

    public Set<String> getAccessConstraints()
    {
        return this.accessConstraints;
    }

    public Set<String> getProfiles()
    {
        return this.profiles;
    }

    protected void doParseEventContent(XMLEventParserContext ctx, XMLEvent event, Object... args)
        throws XMLStreamException
    {
        if (ctx.isStartElement(event, "ServiceTypeVersion"))
        {
            String s = ctx.getStringParser().parseString(ctx, event);
            if (!WWUtil.isEmpty(s))
                this.serviceTypeVersions.add(s);
        }
        else if (ctx.isStartElement(event, "Abstract"))
        {
            String s = ctx.getStringParser().parseString(ctx, event);
            if (!WWUtil.isEmpty(s))
                this.abstracts.add(s);
        }
        else if (ctx.isStartElement(event, "AccessConstraints"))
        {
            String s = ctx.getStringParser().parseString(ctx, event);
            if (!WWUtil.isEmpty(s))
                this.accessConstraints.add(s);
        }
        else if (ctx.isStartElement(event, "Title"))
        {
            String s = ctx.getStringParser().parseString(ctx, event);
            if (!WWUtil.isEmpty(s))
                this.titles.add(s);
        }
        else if (ctx.isStartElement(event, "Profile"))
        {
            String s = ctx.getStringParser().parseString(ctx, event);
            if (!WWUtil.isEmpty(s))
                this.profiles.add(s);
        }
        else
        {
            super.doParseEventContent(ctx, event, args);
        }
    }
}
