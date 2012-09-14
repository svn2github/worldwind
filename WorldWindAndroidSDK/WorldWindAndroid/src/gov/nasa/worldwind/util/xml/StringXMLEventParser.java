/*
 * Copyright (C) 2012 DreamHammer.com
 */

package gov.nasa.worldwind.util.xml;

/**
 * @author tag
 * @version $Id$
 */
public class StringXMLEventParser extends AbstractXMLEventParser
{
    public StringXMLEventParser()
    {
    }

    public StringXMLEventParser(String namespaceUri)
    {
        super(namespaceUri);
    }

    public Object parse(XMLEventParserContext ctx, XMLEvent stringEvent, Object... args)
        throws XMLParserException

    {
        String s = this.parseCharacterContent(ctx, stringEvent, args);
        return s != null ? s.trim() : null;
    }

    public String parseString(XMLEventParserContext ctx, XMLEvent stringEvent, Object... args)
        throws XMLParserException

    {
        return (String) this.parse(ctx, stringEvent, args);
    }
}
