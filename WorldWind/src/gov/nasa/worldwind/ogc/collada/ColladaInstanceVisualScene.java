/*
 * Copyright (C) 2012 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.ogc.collada;

import gov.nasa.worldwind.render.DrawContext;

/**
 * Represents the Collada <i>Instance_Visual_Scene</i> element and provides access to its contents.
 *
 * @author pabercrombie
 * @version $Id$
 */
public class ColladaInstanceVisualScene extends ColladaAbstractObject
{
    public ColladaInstanceVisualScene(String ns)
    {
        super(ns);
    }

    public void render(DrawContext dc)
    {
        // TODO should go through root.resolve
        String url = (String) this.getField("url");

        // TODO cache resolved scene
        ColladaLibraryVisualScenes sceneLibrary = this.getRoot().getSceneLibrary();
        ColladaVisualScene scene = sceneLibrary.getSceneById(url.substring(1));

        if (scene != null)
        {
            scene.render(dc);
        }
    }
}
