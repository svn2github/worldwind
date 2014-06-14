/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.ogc.wcs.wcs100;

import gov.nasa.worldwind.util.WWUtil;
import gov.nasa.worldwind.util.xml.*;

import javax.xml.stream.XMLStreamException;
import javax.xml.stream.events.XMLEvent;
import java.util.*;

/**
 * @author tag
 * @version $Id$
 */
public class WCS100LonLatEnvelope extends AbstractXMLEventParser
{
    List<String> positions = new ArrayList<String>(2);
    List<String> timePositions = new ArrayList<String>(2);

    public WCS100LonLatEnvelope(String namespaceURI)
    {
        super(namespaceURI);
    }

    public String getSRSName()
    {
        return (String) this.getField("srsName");
    }

    public List<String> getPositions()
    {
        return this.positions;
    }

    protected void doParseEventContent(XMLEventParserContext ctx, XMLEvent event, Object... args)
        throws XMLStreamException
    {
        if (ctx.isStartElement(event, "pos"))
        {
            String s = ctx.getStringParser().parseString(ctx, event);
            if (!WWUtil.isEmpty(s))
                this.positions.add(s);
        }
        else if (ctx.isStartElement(event, "timePosition"))
        {
            String s = ctx.getStringParser().parseString(ctx, event);
            if (!WWUtil.isEmpty(s))
                this.timePositions.add(s);
        }
        else
        {
            super.doParseEventContent(ctx, event, args);
        }
    }
}
