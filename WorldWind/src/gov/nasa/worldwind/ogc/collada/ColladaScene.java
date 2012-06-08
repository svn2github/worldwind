/*
 * Copyright (C) 2012 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.ogc.collada;

import gov.nasa.worldwind.ogc.collada.impl.*;
import gov.nasa.worldwind.render.DrawContext;

/**
 * Represents the Collada <i>Scene</i> element and provides access to its contents.
 *
 * @author pabercrombie
 * @version $Id$
 */
public class ColladaScene extends ColladaAbstractObject implements ColladaRenderable
{
    /** Flag to indicate that the scene has been fetched from the hash map. */
    protected boolean sceneFetched = false;
    protected ColladaInstanceVisualScene instanceVisualScene;

    public ColladaScene(String ns)
    {
        super(ns);
    }

    protected ColladaInstanceVisualScene getInstanceVisualScene()
    {
        if (!this.sceneFetched)
        {
            this.instanceVisualScene = (ColladaInstanceVisualScene) this.getField("instance_visual_scene");
            this.sceneFetched = true;
        }
        return this.instanceVisualScene;
    }

    public void preRender(ColladaTraversalContext tc, DrawContext dc)
    {
        ColladaInstanceVisualScene sceneInstance = this.getInstanceVisualScene();
        if (sceneInstance != null)
            sceneInstance.preRender(tc, dc);
    }

    public void render(ColladaTraversalContext tc, DrawContext dc)
    {
        ColladaInstanceVisualScene sceneInstance = this.getInstanceVisualScene();
        if (sceneInstance != null)
            sceneInstance.render(tc, dc);
    }
}
