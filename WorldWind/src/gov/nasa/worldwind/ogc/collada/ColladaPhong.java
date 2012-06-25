/*
 * Copyright (C) 2012 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.ogc.collada;

/**
 * Represents the COLLADA <i>phong</i> shader element and provides access to its contents.
 *
 * @author pabercrombie
 * @version $Id$
 */
public class ColladaPhong extends ColladaAbstractShader
{
    /**
     * Construct an instance.
     *
     * @param ns the qualifying namespace URI. May be null to indicate no namespace qualification.
     */
    public ColladaPhong(String ns)
    {
        super(ns);
    }
}
