/*
 * Copyright (C) 2012 DreamHammer.com
 */

package gov.nasa.worldwind.kml;

import gov.nasa.worldwind.util.xml.AbstractXMLEventParser;

/**
 * Represents the KML <i>SimpleData</i> element and provides access to its contents.
 *
 * @author tag
 * @version $Id$
 */
public class KMLSimpleData extends AbstractXMLEventParser
{
    /**
     * Construct an instance.
     *
     * @param namespaceURI the qualifying namespace URI. May be null to indicate no namespace qualification.
     */
    public KMLSimpleData(String namespaceURI)
    {
        super(namespaceURI);
    }

    public String getName()
    {
        return (String) this.getField("name");
    }
}
