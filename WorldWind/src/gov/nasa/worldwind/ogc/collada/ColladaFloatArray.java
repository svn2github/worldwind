/*
 * Copyright (C) 2012 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.ogc.collada;

import gov.nasa.worldwind.util.WWUtil;
import gov.nasa.worldwind.util.xml.XMLEventParserContext;

import javax.xml.stream.XMLStreamException;
import javax.xml.stream.events.XMLEvent;

/**
 * Represents the Collada <i>Float_Array</i> element and provides access to its contents.
 *
 * @author pabercrombie
 * @version $Id$
 */
public class ColladaFloatArray extends ColladaAbstractObject
{
    protected float[] floats;

    public ColladaFloatArray(String ns)
    {
        super(ns);
    }

    public float[] getFloats()
    {
        return this.floats;
    }

    @Override
    public Object parse(XMLEventParserContext ctx, XMLEvent event, Object... args) throws XMLStreamException
    {
        super.parse(ctx, event, args);

        if (this.hasField(CHARACTERS_CONTENT))
        {
            String s = (String) this.getField(CHARACTERS_CONTENT);
            if (!WWUtil.isEmpty(s))
                this.floats = this.parseFloats(s);

            // Don't need to keep string version of the floats
            this.removeField(CHARACTERS_CONTENT);
        }

        return this;
    }

    protected float[] parseFloats(String floatArrayString)
    {
        String[] arrayOfNumbers = floatArrayString.split(" ");
        float[] ary = new float[arrayOfNumbers.length];

        int i = 0;
        for (String s : arrayOfNumbers)
        {
            ary[i++] = Float.parseFloat(s);
        }

        return ary;
    }
}
