/*
 * Copyright (C) 2012 DreamHammer.com
 */

package gov.nasa.worldwind.kml;

/**
 * Represents the KML <i>LinearRing</i> element and provides access to its contents.
 *
 * @author tag
 * @version $Id$
 */
public class KMLLinearRing extends KMLLineString
{
    /**
     * Construct an instance.
     *
     * @param namespaceURI the qualifying namespace URI. May be null to indicate no namespace qualification.
     */
    public KMLLinearRing(String namespaceURI)
    {
        super(namespaceURI);
    }
}
