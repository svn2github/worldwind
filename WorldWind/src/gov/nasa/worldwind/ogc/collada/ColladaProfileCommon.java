/*
 * Copyright (C) 2012 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.ogc.collada;

/**
 * Represents the COLLADA <i>profile_COMMON</i> element and provides access to its contents.
 *
 * @author pabercrombie
 * @version $Id$
 */
public class ColladaProfileCommon extends ColladaAbstractParamContainer
{
    /**
     * Construct an instance.
     *
     * @param ns the qualifying namespace URI. May be null to indicate no namespace qualification.
     */
    public ColladaProfileCommon(String ns)
    {
        super(ns);
    }

    /**
     * Indicates the <i>technique</i> field of this profile.
     *
     * @return The value of the <i>technique</i> field, or null if the field is not set.
     */
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
