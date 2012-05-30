/*
 * Copyright (C) 2012 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.ogc.collada;

import java.util.*;

/**
 * Represents the Collada <i>Effect</i> element and provides access to its contents.
 *
 * @author pabercrombie
 * @version $Id$
 */
public class ColladaEffect extends ColladaAbstractObject
{
    protected List<ColladaNewParam> newParams = new ArrayList<ColladaNewParam>();

    public ColladaEffect(String ns)
    {
        super(ns);
    }

    public ColladaProfileCommon getProfileCommon()
    {
        return (ColladaProfileCommon) this.getField("profile_COMMON");
    }

    public List<ColladaNewParam> getNewParams()
    {
        return this.newParams;
    }

    public String getImageRef()
    {
        ColladaProfileCommon profile;
        ColladaTechnique technique = null;

        profile = this.getProfileCommon();
        if (profile != null)
            technique = profile.getTechnique();

        String imageRef = null;

        // Look for image ref in technique params.
        if (technique != null)
            imageRef = this.findImageRef(technique.getNewParams());

        if (imageRef == null)
        {
            // Look for image ref in profile_COMMON
            if (profile != null)
                imageRef = this.findImageRef(profile.getNewParams());

            // Look for image ref in effect params
            if (imageRef == null)
                imageRef = this.findImageRef(this.getNewParams());
        }

        return imageRef;
    }

    @Override
    public void setField(String keyName, Object value)
    {
        if ("newparam".equals(keyName))
        {
            this.newParams.add((ColladaNewParam) value);
        }
        else
        {
            super.setField(keyName, value);
        }
    }

    protected String findImageRef(List<ColladaNewParam> params)
    {
        for (ColladaNewParam param : params)
        {
            if (param.hasField("surface"))
            {
                ColladaSurface surface = (ColladaSurface) param.getField("surface");
                String imageRef = surface.getInitFrom();

                Object o = this.getRoot().resolveReference(imageRef);
                if (o instanceof ColladaImage)
                {
                    return ((ColladaImage) o).getInitFrom();
                }
            }
            else if (param.hasField("sampler2D"))
            {
                // TODO
            }
        }
        return null;
    }
}
