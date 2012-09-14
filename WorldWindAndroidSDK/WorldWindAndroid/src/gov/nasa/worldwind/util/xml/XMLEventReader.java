/*
 * Copyright (C) 2012 DreamHammer.com
 */

package gov.nasa.worldwind.util.xml;

import org.xmlpull.v1.*;

import java.io.IOException;

/**
 * @author tag
 * @version $Id$
 */
public class XMLEventReader
{
    protected XmlPullParser parser;

    public XMLEventReader(XmlPullParser parser)
    {
        this.parser = parser;
    }

    public XMLEvent nextEvent() throws XMLParserException
    {
        try
        {
            int eventType = this.parser.next();

            if (eventType == XmlPullParser.END_DOCUMENT)
                return null;

            return new XMLEvent(eventType, parser);
        }
        catch (IOException e)
        {
            throw new XMLParserException(e);
        }
        catch (XmlPullParserException e)
        {
            throw new XMLParserException(e);
        }
    }
}
