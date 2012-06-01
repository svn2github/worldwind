/*
 * Copyright (C) 2012 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.ogc.collada;

import java.awt.*;

/**
 * Represents the Collada <i>Diffuse</i> element and provides access to its contents.
 *
 * @author pabercrombie
 * @version $Id$
 */
public class ColladaTextureOrColor extends ColladaAbstractObject
{
    public ColladaTextureOrColor(String ns)
    {
        super(ns);
    }

    public ColladaTexture getTexture()
    {
        return (ColladaTexture) this.getField("texture");
    }

    public Color getColor()
    {
        ColladaColor color = (ColladaColor) this.getField("color");
        if (color == null)
            return null;

        String colorString = color.getCharacters();
        float[] values = this.parseFloatArray(colorString);

        float r = values[0];
        float g = values[1];
        float b = values[2];
        float a = (values.length > 3) ? values[3] : 1.0f;

        return new Color(r, g, b, a);
    }

    protected float[] parseFloatArray(String floatArrayString)
    {
        String[] arrayOfNumbers = floatArrayString.trim().split("\\s+");
        float[] floats = new float[arrayOfNumbers.length];

        int i = 0;
        for (String s : arrayOfNumbers)
        {
            floats[i++] = Float.parseFloat(s);
        }

        return floats;
    }
}
