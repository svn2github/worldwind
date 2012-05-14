/*
 * Copyright (C) 2012 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.ogc.collada;

import java.util.*;

/**
 * Represents the Collada <i>Mesh</i> element and provides access to its contents.
 *
 * @author pabercrombie
 * @version $Id$
 */
public class ColladaMesh extends ColladaAbstractObject
{
    protected List<ColladaSource> sources = new ArrayList<ColladaSource>();
    protected List<ColladaTriangles> triangles = new ArrayList<ColladaTriangles>();
    protected List<ColladaVertices> vertices = new ArrayList<ColladaVertices>();

    public ColladaMesh(String ns)
    {
        super(ns);
    }

    public List<ColladaSource> getSources()
    {
        return this.sources;
    }

    public List<ColladaTriangles> getTriangles()
    {
        return this.triangles;
    }

    public List<ColladaVertices> getVertices()
    {
        return this.vertices;
    }

    @Override
    public void setField(String keyName, Object value)
    {
        if (keyName.equals("vertices"))
        {
            this.vertices.add((ColladaVertices) value);
        }
        else if (keyName.equals("source"))
        {
            this.sources.add((ColladaSource) value);
        }
        else if (keyName.equals("triangles"))
        {
            this.triangles.add((ColladaTriangles) value);
        }
        else
        {
            super.setField(keyName, value);
        }
    }

    @Override
    public Object getField(String keyName)
    {
        if (keyName.equals("source"))
        {
            return this.sources.get(0);
        }
        else if (keyName.equals("triangles"))
        {
            return this.triangles.get(0);
        }
        else
        {
            return super.getField(keyName);
        }
    }
}
