/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.ogc.wcs.wcs100;

import gov.nasa.worldwind.util.xml.StringListXMLEventParser;

import javax.xml.namespace.QName;
import java.util.List;

/**
 * @author tag
 * @version $Id$
 */
public class WCS100SupportedFormats extends StringListXMLEventParser
{
    public WCS100SupportedFormats(String namespaceURI)
    {
        super(namespaceURI, new QName(namespaceURI, "formats"));
    }

    public String getNativeFormat()
    {
        return (String) this.getField("nativeFormat");
    }

    List<String> getSupportedFormats()
    {
        return this.getStrings();
    }
}
