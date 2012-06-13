/*
 * Copyright (C) 2012 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.ogc.collada;

/**
 * Represents the Collada <i>Lines</i> element and provides access to its contents.
 *
 * @author pabercrombie
 * @version $Id$
 */
public class ColladaLines extends ColladaAbstractGeometry
{
    public ColladaLines(String ns)
    {
        super(ns);
    }

    @Override
    protected int getVerticesPerShape()
    {
        return 2;
    }
}
