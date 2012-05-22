/*
 * Copyright (C) 2012 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.ogc.collada;

import gov.nasa.worldwind.ogc.collada.impl.*;
import gov.nasa.worldwind.render.DrawContext;

/**
 * Represents the Collada <i>Instance_Visual_Scene</i> element and provides access to its contents.
 *
 * @author pabercrombie
 * @version $Id$
 */
public class ColladaInstanceVisualScene extends ColladaAbstractInstance<ColladaVisualScene> implements ColladaRenderable
{
    public ColladaInstanceVisualScene(String ns)
    {
        super(ns);
    }

    public void preRender(ColladaTraversalContext tc, DrawContext dc)
    {
        ColladaVisualScene instance = this.get();
        if (instance != null)
            instance.preRender(tc, dc);
    }

    public void render(ColladaTraversalContext tc, DrawContext dc)
    {
        ColladaVisualScene instance = this.get();
        if (instance != null)
            instance.render(tc, dc);
    }
}
