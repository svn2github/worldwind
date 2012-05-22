/*
 * Copyright (C) 2012 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.ogc.collada;

import gov.nasa.worldwind.ogc.collada.impl.*;
import gov.nasa.worldwind.render.DrawContext;

import java.util.*;

/**
 * Represents the Collada <i>Visual_Scene</i> element and provides access to its contents.
 *
 * @author pabercrombie
 * @version $Id$
 */
public class ColladaVisualScene extends ColladaAbstractObject implements ColladaRenderable
{
    protected List<ColladaNode> nodes = new ArrayList<ColladaNode>();

    public ColladaVisualScene(String ns)
    {
        super(ns);
    }

    public List<ColladaNode> getNodes()
    {
        return this.nodes;
    }

    @Override
    public void setField(String keyName, Object value)
    {
        if (keyName.equals("node"))
        {
            this.nodes.add((ColladaNode) value);
        }
        else
        {
            super.setField(keyName, value);
        }
    }

    public void preRender(ColladaTraversalContext tc, DrawContext dc)
    {
        for (ColladaNode node : this.getNodes())
        {
            node.preRender(tc, dc);
        }
    }

    public void render(ColladaTraversalContext tc, DrawContext dc)
    {
        for (ColladaNode node : this.getNodes())
        {
            node.render(tc, dc);
        }
    }
}
