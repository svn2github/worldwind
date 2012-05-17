/*
 * Copyright (C) 2012 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.ogc.collada;

/**
 * Represents the Collada <i>Geometry</i> element and provides access to its contents.
 *
 * @author pabercrombie
 * @version $Id$
 */
public class ColladaGeometry extends ColladaAbstractObject
{
    public ColladaGeometry(String ns)
    {
        super(ns);
    }

    public ColladaMesh getMesh()
    {
        return (ColladaMesh) this.getField("mesh");
    }
}
