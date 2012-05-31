/*
 * Copyright (C) 2012 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.ogc.collada;

/**
 * Represents the Collada <i>Asset</i> element and provides access to its contents.
 *
 * @author pabercrombie
 * @version $Id$
 */
public class ColladaAsset extends ColladaAbstractObject
{
    public ColladaAsset(String ns)
    {
        super(ns);
    }

    public ColladaUnit getUnit()
    {
        return (ColladaUnit) this.getField("unit");
    }
}
