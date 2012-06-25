/*
 * Copyright (C) 2012 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.ogc.collada;

/**
 * Represents the COLLADA <i>instance_geometry</i> element and provides access to its contents.
 *
 * @author pabercrombie
 * @version $Id$
 */
public class ColladaInstanceGeometry extends ColladaAbstractInstance<ColladaGeometry>
{
    public ColladaInstanceGeometry(String ns)
    {
        super(ns);
    }

    public ColladaBindMaterial getBindMaterial()
    {
        return (ColladaBindMaterial) this.getField("bind_material");
    }
}
