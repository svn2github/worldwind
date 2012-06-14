/*
 * Copyright (C) 2012 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.ogc.collada;

/**
 * Represents the Collada <i>Texture</i> element and provides access to its contents.
 *
 * @author pabercrombie
 * @version $Id$
 */
public class ColladaTexture extends ColladaAbstractObject
{
    public ColladaTexture(String ns)
    {
        super(ns);
    }

    /**
     * Indicates the value of the <i>texture</i> attribute.
     *
     * @return The <i>texture</i> attribute, or null the attribute is not set.
     */
    public String getTexture()
    {
        return (String) this.getField("texture");
    }

    /**
     * Indicates the value of the <i>texcoord</i> attribute.
     *
     * @return The <i>texcoord</i> attribute, or null the attribute is not set.
     */
    public String getTexCoord()
    {
        return (String) this.getField("texcoord");
    }
}
