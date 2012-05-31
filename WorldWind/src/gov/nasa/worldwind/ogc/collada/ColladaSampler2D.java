/*
 * Copyright (C) 2012 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.ogc.collada;

/**
 * Represents the Collada <i>Sampler2D</i> element and provides access to its contents.
 *
 * @author pabercrombie
 * @version $Id$
 */
public class ColladaSampler2D extends ColladaAbstractObject
{
    public ColladaSampler2D(String ns)
    {
        super(ns);
    }

    public ColladaSource getSource()
    {
        return (ColladaSource) this.getField("source");
    }
}
