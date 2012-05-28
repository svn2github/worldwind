/*
 * Copyright (C) 2012 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.ogc.collada;

/**
 * Represents the Collada <i>Surface</i> element and provides access to its contents.
 *
 * @author pabercrombie
 * @version $Id$
 */
public class ColladaSurface extends ColladaAbstractObject
{
    public ColladaSurface(String ns)
    {
        super(ns);
    }

    public String getInitFrom()
    {
        return (String) this.getField("init_from");
    }
}
