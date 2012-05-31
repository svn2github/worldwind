/*
 * Copyright (C) 2012 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.ogc.collada;

/**
 * Represents the Collada <i>Technique</i> element and provides access to its contents.
 *
 * @author pabercrombie
 * @version $Id$
 */
public class ColladaTechnique extends ColladaAbstractParamContainer
{
    public ColladaTechnique(String ns)
    {
        super(ns);
    }

    public ColladaAbstractShader getShader()
    {
        Object o = this.getField("lambert");
        if (o != null)
            return (ColladaAbstractShader) o;

        o = this.getField("phong");
        if (o != null)
            return (ColladaAbstractShader) o;

        // TODO handle other shaders
        return null;
    }
}
