/*
 * Copyright (C) 2012 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.ogc.collada;

import gov.nasa.worldwind.render.Material;

import java.awt.*;

/**
 * Represents the Collada <i>Effect</i> element and provides access to its contents.
 *
 * @author pabercrombie
 * @version $Id$
 */
public class ColladaEffect extends ColladaAbstractParamContainer
{
    public ColladaEffect(String ns)
    {
        super(ns);
    }

    public ColladaProfileCommon getProfileCommon()
    {
        return (ColladaProfileCommon) this.getField("profile_COMMON");
    }

    public String getImageRef()
    {
        ColladaProfileCommon profile = this.getProfileCommon();
        if (profile == null)
            return null;

        ColladaTechnique technique = profile.getTechnique();
        if (technique == null)
            return null;

        ColladaAbstractShader shader = technique.getShader();
        if (shader == null)
            return null;

        ColladaTextureOrColor diffuse = shader.getDiffuse();
        if (diffuse == null)
            return null;

        ColladaTexture texture = diffuse.getTexture();
        if (texture == null)
            return null;

        String imageRef = this.getImageRef(texture);
        if (imageRef == null)
            return null;

        // imageRef identifiers an <image> element (may be external). This element will give us the filename.
        Object o = this.getRoot().resolveReference(imageRef);
        if (o instanceof ColladaImage)
            return ((ColladaImage) o).getInitFrom();

        return null;
    }

    protected String getImageRef(ColladaTexture texture)
    {
        String sid = texture.getTexture();

        ColladaNewParam param = this.getParam(sid);
        if (param == null)
            return null;

        ColladaSampler2D sampler = param.getSampler2D();
        if (sampler == null)
            return null;

        ColladaSource source = sampler.getSource();
        if (source == null)
            return null;

        sid = source.getCharacters();
        if (sid == null)
            return null;

        param = this.getParam(sid);
        if (param == null)
            return null;

        ColladaSurface surface = param.getSurface();
        if (surface != null)
            return surface.getInitFrom();

        return null;
    }

    public Material getMaterial()
    {
        ColladaProfileCommon profile = this.getProfileCommon();
        if (profile == null)
            return null;

        ColladaTechnique technique = profile.getTechnique();
        if (technique == null)
            return null;

        ColladaAbstractShader shader = technique.getShader();
        if (shader == null)
            return null;

        Color emission = null;
        Color ambient = null;
        Color diffuse = null;
        Color specular = null;

        ColladaTextureOrColor textureOrColor = shader.getEmission();
        if (textureOrColor != null)
            emission = textureOrColor.getColor();

        textureOrColor = shader.getAmbient();
        if (textureOrColor != null)
            ambient = textureOrColor.getColor();

        textureOrColor = shader.getSpecular();
        if (textureOrColor != null)
            specular = textureOrColor.getColor();

        textureOrColor = shader.getDiffuse();
        if (textureOrColor != null)
            diffuse = textureOrColor.getColor();

        // TODO what should be we do with materials that don't have Diffuse?
        if (diffuse == null)
            return null;

        if (emission == null)
            emission = new Color(0, 0, 0, diffuse.getAlpha());
        if (ambient == null)
            ambient = diffuse;
        if (specular == null)
            specular = new Color(255, 255, 255, diffuse.getAlpha());

        return new Material(specular, diffuse, ambient, emission, 1f);
    }

    /** {@inheritDoc} */
    @Override
    public ColladaNewParam getParam(String sid)
    {
        ColladaNewParam param = super.getParam(sid);
        if (param != null)
            return param;

        ColladaProfileCommon profile = this.getProfileCommon();
        if (profile == null)
            return null;

        return profile.getParam(sid);
    }
}
