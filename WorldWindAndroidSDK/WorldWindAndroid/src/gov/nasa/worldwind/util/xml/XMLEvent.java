/*
 * Copyright (C) 2012 DreamHammer.com
 */

package gov.nasa.worldwind.util.xml;

import gov.nasa.worldwind.avlist.*;
import org.xmlpull.v1.XmlPullParser;

import javax.xml.namespace.QName;

/**
 * @author tag
 * @version $Id$
 */
public class XMLEvent
{
    protected int eventType;
    protected XmlPullParser xpp;

    public XMLEvent(int eventType, XmlPullParser pullParser)
    {
        this.eventType = eventType;
        this.xpp = pullParser;
    }

    public int getLineNumber()
    {
        return this.xpp.getLineNumber();
    }

    public boolean isStartElement()
    {
        return this.eventType == XmlPullParser.START_TAG;
    }

    public boolean isEndElement()
    {
        return this.eventType == XmlPullParser.END_TAG;
    }

    public boolean isCharacters()
    {
        return this.eventType == XmlPullParser.TEXT;
    }

    public boolean isWhiteSpace()
    {
        return this.isCharacters() && (this.getData() == null || this.getData().trim().length() == 0);
    }

    public QName getName()
    {
        return new QName(this.xpp.getNamespace(), xpp.getName());
    }

    public String getData()
    {
        return this.xpp.getText();
    }

    public AVList getAttributes()
    {
        if (this.xpp.getAttributeCount() == 0)
            return null;

        AVListImpl avList = new AVListImpl();

        for (int i = 0; i < this.xpp.getAttributeCount(); i++)
        {
            avList.setValue(this.xpp.getAttributeName(i), this.xpp.getAttributeValue(i));
        }

        return avList;
    }
}
