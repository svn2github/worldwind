/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.ogc.wcs;

import gov.nasa.worldwind.ogc.ows.OWSWGS84BoundingBox;
import gov.nasa.worldwind.util.WWUtil;
import gov.nasa.worldwind.util.xml.*;

import javax.xml.stream.XMLStreamException;
import javax.xml.stream.events.XMLEvent;
import java.util.*;

/**
 * @author tag
 * @version $Id$
 */
public class WCSCoverageSummary extends AbstractXMLEventParser
{
    // TODO: metadata

    protected Set<String> abstracts = new HashSet<String>(1);
    protected Set<OWSWGS84BoundingBox> boundingBoxes = new HashSet<OWSWGS84BoundingBox>(1);
    protected Set<WCSCoverageSummary> coverageSummaries = new HashSet<WCSCoverageSummary>(1);
    protected Set<String> supportedCRSs = new HashSet<String>(1);
    protected Set<String> supportedFormats = new HashSet<String>(1);
    protected Set<String> titles = new HashSet<String>(1);

    public WCSCoverageSummary(String namespaceURI)
    {
        super(namespaceURI);
    }

    public Set<String> getAbstracts()
    {
        return this.abstracts;
    }

    public String getAbstract()
    {
        Iterator<String> iter = this.abstracts.iterator();

        return iter.hasNext() ? iter.next() : null;
    }

    public Set<OWSWGS84BoundingBox> getBoundingBoxes()
    {
        return this.boundingBoxes;
    }

    public OWSWGS84BoundingBox getBoundingBox()
    {
        Iterator<OWSWGS84BoundingBox> iter = this.boundingBoxes.iterator();

        return iter.hasNext() ? iter.next() : null;
    }

    public Set<WCSCoverageSummary> getCoverageSummaries()
    {
        return this.coverageSummaries;
    }

    public String getIdentifier()
    {
        return (String) this.getField("Identifier");
    }

    public Set<String> getKeywords()
    {
        return ((StringSetXMLEventParser) this.getField("Keywords")).getStrings();
    }

    public Set<String> getSupportedCRSs()
    {
        return this.supportedCRSs;
    }

    public Set<String> getSupportedFormats()
    {
        return this.supportedFormats;
    }

    public Set<String> getTitles()
    {
        return this.titles;
    }

    public String getTitle()
    {
        Iterator<String> iter = this.titles.iterator();

        return iter.hasNext() ? iter.next() : null;
    }

    protected void doParseEventContent(XMLEventParserContext ctx, XMLEvent event, Object... args)
        throws XMLStreamException
    {
        if (ctx.isStartElement(event, "Abstract"))
        {
            String s = ctx.getStringParser().parseString(ctx, event);
            if (!WWUtil.isEmpty(s))
                this.abstracts.add(s);
        }
        else if (ctx.isStartElement(event, "WGS84BoundingBox"))
        {
            XMLEventParser parser = this.allocate(ctx, event);
            if (parser != null)
            {
                Object o = parser.parse(ctx, event, args);
                if (o != null && o instanceof OWSWGS84BoundingBox)
                    this.boundingBoxes.add((OWSWGS84BoundingBox) o);
            }
        }
        else if (ctx.isStartElement(event, "CoverageSummary"))
        {
            XMLEventParser parser = this.allocate(ctx, event);
            if (parser != null)
            {
                Object o = parser.parse(ctx, event, args);
                if (o != null && o instanceof WCSCoverageSummary)
                    this.coverageSummaries.add((WCSCoverageSummary) o);
            }
        }
        else if (ctx.isStartElement(event, "SupportedCRS"))
        {
            String s = ctx.getStringParser().parseString(ctx, event);
            if (!WWUtil.isEmpty(s))
                this.supportedCRSs.add(s);
        }
        else if (ctx.isStartElement(event, "SupportedFormat"))
        {
            String s = ctx.getStringParser().parseString(ctx, event);
            if (!WWUtil.isEmpty(s))
                this.supportedFormats.add(s);
        }
        else if (ctx.isStartElement(event, "Title"))
        {
            String s = ctx.getStringParser().parseString(ctx, event);
            if (!WWUtil.isEmpty(s))
                this.titles.add(s);
        }
        else
        {
            super.doParseEventContent(ctx, event, args);
        }
    }
}
