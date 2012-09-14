/*
 * Copyright (C) 2012 DreamHammer.com
 */

package gov.nasa.worldwind.util.xml;

import gov.nasa.worldwind.util.WWUtil;

import java.io.IOException;

/**
 * @author tag
 * @version $Id$
 */
public class DoubleXMLEventParser extends AbstractXMLEventParser
{
    public DoubleXMLEventParser()
    {
    }

    public DoubleXMLEventParser(String namespaceUri)
    {
        super(namespaceUri);
    }

    public Object parse(XMLEventParserContext ctx, XMLEvent doubleEvent, Object... args)
        throws XMLParserException

    {
        String s = this.parseCharacterContent(ctx, doubleEvent);
        return s != null ? WWUtil.convertStringToDouble(s) : null;
    }

    public Double parseDouble(XMLEventParserContext ctx, XMLEvent doubleEvent, Object... args)
        throws IOException, XMLParserException

    {
        return (Double) this.parse(ctx, doubleEvent, args);
    }
}
