/*
 * Copyright (C) 2012 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.ogc.collada;

/**
 * Represents the Collada <i>Effect</i> element and provides access to its contents.
 *
 * @author pabercrombie
 * @version $Id$
 */
// TODO handle params declared outside of profile_COMMON
public class ColladaEffect extends ColladaAbstractObject
{
    public ColladaEffect(String ns)
    {
        super(ns);
    }

    public ColladaProfileCommon getProfileCommon()
    {
        return (ColladaProfileCommon) this.getField("profile_COMMON");
    }
}
