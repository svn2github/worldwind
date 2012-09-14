/*
 * Copyright (C) 2012 DreamHammer.com
 */

package gov.nasa.worldwind.kml;

/**
 * Represents the KML <i>LineStyle</i> element and provides access to its contents.
 *
 * @author tag
 * @version $Id$
 */
public class KMLLineStyle extends KMLAbstractColorStyle
{
    public KMLLineStyle(String namespaceURI)
    {
        super(namespaceURI);
    }

    public Double getWidth()
    {
        return (Double) this.getField("width");
    }
}
