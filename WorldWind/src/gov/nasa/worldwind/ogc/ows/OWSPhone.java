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
public class OWSPhone extends AbstractXMLEventParser
{
    protected Set<String> voices = new HashSet<String>(1);
    protected Set<String> faxes = new HashSet<String>(1);

    public OWSPhone(String namespaceURI)
    {
        super(namespaceURI);
    }

    public Set<String> getVoices()
    {
        return this.voices;
    }

    public Set<String> getFacsimiles()
    {
        return this.faxes;
    }

    protected void doParseEventContent(XMLEventParserContext ctx, XMLEvent event, Object... args)
        throws XMLStreamException
    {
        if (ctx.isStartElement(event, "Voice"))
        {
            String s = ctx.getStringParser().parseString(ctx, event);
            if (!WWUtil.isEmpty(s))
                this.voices.add(s);
        }
        else if (ctx.isStartElement(event, "Facsimile"))
        {
            String s = ctx.getStringParser().parseString(ctx, event);
            if (!WWUtil.isEmpty(s))
                this.faxes.add(s);
        }
        else
        {
            super.doParseEventContent(ctx, event, args);
        }
    }
}
