/*
 * Copyright (C) 2012 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.ogc.collada;

import gov.nasa.worldwind.ogc.collada.impl.*;
import gov.nasa.worldwind.render.DrawContext;

/**
 * @author pabercrombie
 * @version $Id$
 */
public class ColladaInstanceNode extends ColladaAbstractInstance<ColladaNode> implements ColladaRenderable
{
    public ColladaInstanceNode(String ns)
    {
        super(ns);
    }

    public void preRender(ColladaTraversalContext tc, DrawContext dc)
    {
        ColladaNode instance = this.get();
        if (instance != null)
            instance.preRender(tc, dc);
    }

    public void render(ColladaTraversalContext tc, DrawContext dc)
    {
        ColladaNode instance = this.get();
        if (instance != null)
            instance.render(tc, dc);
    }
}