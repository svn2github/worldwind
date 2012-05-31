/*
 * Copyright (C) 2012 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.ogc.collada;

/**
 * Represents the Collada <i>Profile_COMMON</i> element and provides access to its contents.
 *
 * @author pabercrombie
 * @version $Id$
 */
public class ColladaProfileCommon extends ColladaAbstractParamContainer
{
    public ColladaProfileCommon(String ns)
    {
        super(ns);
    }

    public ColladaTechnique getTechnique()
    {
        return (ColladaTechnique) this.getField("technique");
    }

    /** {@inheritDoc} */
    @Override
    public ColladaNewParam getParam(String sid)
    {
        ColladaNewParam param = super.getParam(sid);
        if (param != null)
            return param;

        ColladaTechnique technique = this.getTechnique();
        if (technique == null)
            return null;

        return technique.getParam(sid);
    }
}
