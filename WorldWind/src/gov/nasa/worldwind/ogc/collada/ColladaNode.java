/*
 * Copyright (C) 2012 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.ogc.collada;

import gov.nasa.worldwind.geom.Angle;
import gov.nasa.worldwind.ogc.collada.impl.*;
import gov.nasa.worldwind.render.DrawContext;

import java.util.*;

/**
 * Represents the Collada <i>Node</i> element and provides access to its contents.
 *
 * @author pabercrombie
 * @version $Id$
 */
public class ColladaNode extends ColladaAbstractObject implements ColladaRenderable
{
    /**
     * Children of this node. Children may be ColladaNode (direct child of this node) or ColladaInstanceNode (reference
     * to a node elsewhere in the current document, or another document).
     */
    protected List<ColladaRenderable> children;

    /** Shapes used to render geometry in this node. */
    protected List<ColladaTriangleMesh> shapes;

    public ColladaNode(String ns)
    {
        super(ns);
    }

    public void preRender(ColladaTraversalContext tc, DrawContext dc)
    {
        if (this.children != null)
        {
            for (ColladaRenderable node : this.children)
            {
                node.preRender(tc, dc);
            }
        }
    }

    public void render(ColladaTraversalContext tc, DrawContext dc)
    {
        if (this.shapes == null && this.getInstanceGeometry() != null)
        {
            this.shapes = this.createShapes(this.getInstanceGeometry());
        }

        if (this.shapes != null)
        {
            for (ColladaTriangleMesh shape : this.shapes)
            {
                shape.render(dc);
            }
        }

        if (this.children != null)
        {
            for (ColladaRenderable node : this.children)
            {
                node.render(tc, dc);
            }
        }
    }

    public ColladaInstanceGeometry getInstanceGeometry()
    {
        return (ColladaInstanceGeometry) this.getField("instance_geometry");
    }

    protected List<ColladaTriangleMesh> createShapes(ColladaInstanceGeometry geomInstance)
    {
        ColladaGeometry geometry = geomInstance.get();
        if (geometry == null)
            return null;

        ColladaMesh mesh = geometry.getMesh();
        if (mesh == null)
            return null;

        ColladaBindMaterial bindMaterial = geomInstance.getBindMaterial();

        List<ColladaTriangleMesh> newShapes = new ArrayList<ColladaTriangleMesh>();
        for (ColladaTriangles triangle : mesh.getTriangles())
        {
            ColladaTriangleMesh shape = new ColladaTriangleMesh(triangle, bindMaterial);

            shape.setModelPosition(this.getRoot().getPosition());
            shape.setHeading(Angle.ZERO); // TODO
            shape.setPitch(Angle.ZERO);
            shape.setRoll(Angle.ZERO);
            shape.setAltitudeMode(this.getRoot().getAltitudeMode());

            newShapes.add(shape);
        }

        return newShapes;
    }

    @Override
    public void setField(String keyName, Object value)
    {
        if ("node".equals(keyName) || "instance_node".equals(keyName))
        {
            if (this.children == null)
                this.children = new ArrayList<ColladaRenderable>();

            this.children.add((ColladaRenderable) value);
        }
        else
        {
            super.setField(keyName, value);
        }
    }
}
