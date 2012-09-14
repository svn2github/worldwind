/*
 * Copyright (C) 2012 DreamHammer.com
 */

package gov.nasa.worldwind.util.xml;

import gov.nasa.worldwind.util.WWUtil;

/**
 * @author tag
 * @version $Id$
 */
public class IntegerXMLEventParser extends AbstractXMLEventParser
{
    public IntegerXMLEventParser()
    {
    }

    public IntegerXMLEventParser(String namespaceUri)
    {
        super(namespaceUri);
    }

    public Object parse(XMLEventParserContext ctx, XMLEvent integerEvent, Object... args)
        throws XMLParserException

    {
        String s = this.parseCharacterContent(ctx, integerEvent);
        return s != null ? WWUtil.convertStringToInteger(s) : null;
    }
}
