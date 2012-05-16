/*
 * Copyright (C) 2012 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.ogc.collada;

import java.util.*;

/**
 * Represents the Collada <i>Library_Visual_Scenes</i> element and provides access to its contents.
 *
 * @author pabercrombie
 * @version $Id$
 */
public class ColladaLibraryVisualScenes extends ColladaAbstractObject
{
    protected List<ColladaVisualScene> scenes = new ArrayList<ColladaVisualScene>();

    public ColladaLibraryVisualScenes(String ns)
    {
        super(ns);
    }

    public List<ColladaVisualScene> getScenes()
    {
        return this.scenes;
    }

    @Override
    public void setField(String keyName, Object value)
    {
        if (keyName.equals("visual_scene"))
        {
            this.scenes.add((ColladaVisualScene) value);
        }
        else
        {
            super.setField(keyName, value);
        }
    }

    public ColladaVisualScene getSceneById(String id)
    {
        for (ColladaVisualScene scene : this.scenes)
        {
            if (scene.getField("id").equals(id))
            {
                return scene;
            }
        }

        return null;
    }
}
