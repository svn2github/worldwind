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
public class OWSAllowedValues extends AbstractXMLEventParser
{
    protected Set<String> values = new HashSet<String>(2);

    public OWSAllowedValues(String namespaceURI)
    {
        super(namespaceURI);
    }

    public Set<String> getValues()
    {
        return this.values;
    }

    protected void doParseEventContent(XMLEventParserContext ctx, XMLEvent event, Object... args)
        throws XMLStreamException
    {
        if (ctx.isStartElement(event, "Value"))
        {
            String s = ctx.getStringParser().parseString(ctx, event);
            if (!WWUtil.isEmpty(s))
                this.values.add(s);
        }
        else
        {
            super.doParseEventContent(ctx, event, args);
        }
    }
}
