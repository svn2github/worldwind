/*
 * Copyright (C) 2012 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.ogc.collada;

import gov.nasa.worldwind.geom.*;
import gov.nasa.worldwind.ogc.collada.impl.*;
import gov.nasa.worldwind.render.DrawContext;
import gov.nasa.worldwind.util.WWUtil;

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
    /** Geometries defined in this node. */
    protected List<ColladaInstanceGeometry> geometries;

    /** Shape used to render geometry in this node. */
    protected List<ColladaTriangleMesh> shapes;

    /** Transform matrix for this node. */
    protected Matrix matrix;

    public ColladaNode(String ns)
    {
        super(ns);
    }

    public void preRender(ColladaTraversalContext tc, DrawContext dc)
    {
        List<ColladaRenderable> children = this.getChildren();
        if (WWUtil.isEmpty(children))
            return;

        Matrix matrix = this.getMatrix();
        try
        {
            if (matrix != null && matrix != Matrix.IDENTITY)
            {
                tc.pushMatrix();
                tc.multiplyMatrix(matrix);
            }

            for (ColladaRenderable node : children)
            {
                node.preRender(tc, dc);
            }
        }
        finally
        {
            if (matrix != null && matrix != Matrix.IDENTITY)
                tc.popMatrix();
        }
    }

    public void render(ColladaTraversalContext tc, DrawContext dc)
    {
        // Create shapes for this node, if necessary
        if (this.shapes == null)
            this.shapes = this.createShapes();

        Matrix matrix = this.getMatrix();
        try
        {
            if (matrix != null && matrix != Matrix.IDENTITY)
            {
                tc.pushMatrix();
                tc.multiplyMatrix(matrix);
            }

            Matrix traversalMatrix = tc.peekMatrix();
            for (ColladaTriangleMesh shape : this.shapes)
            {
                shape.render(dc, traversalMatrix);
            }

            for (ColladaRenderable node : this.getChildren())
            {
                node.render(tc, dc);
            }
        }
        finally
        {
            if (matrix != null && matrix != Matrix.IDENTITY)
                tc.popMatrix();
        }
    }

    protected List<ColladaTriangleMesh> createShapes()
    {
        if (WWUtil.isEmpty(this.geometries))
            return Collections.emptyList();

        List<ColladaTriangleMesh> shapes = new ArrayList<ColladaTriangleMesh>();
        for (ColladaInstanceGeometry geometry : this.geometries)
        {
            ColladaTriangleMesh shape = this.createShape(geometry);
            if (shape != null)
                shapes.add(shape);
        }
        return shapes;
    }

    protected ColladaTriangleMesh createShape(ColladaInstanceGeometry geomInstance)
    {
        ColladaGeometry geometry = geomInstance.get();
        if (geometry == null)
            return null;

        ColladaMesh mesh = geometry.getMesh();
        if (mesh == null)
            return null;

        List<ColladaTriangles> triangles = mesh.getTriangles();
        if (WWUtil.isEmpty(triangles))
            return null;
        // TODO support lines geometry

        ColladaBindMaterial bindMaterial = geomInstance.getBindMaterial();

        ColladaTriangleMesh newShape = new ColladaTriangleMesh(triangles, bindMaterial);

        newShape.setModelPosition(this.getRoot().getPosition());
        newShape.setHeading(Angle.ZERO); // TODO
        newShape.setPitch(Angle.ZERO);
        newShape.setRoll(Angle.ZERO);
        newShape.setAltitudeMode(this.getRoot().getAltitudeMode());

        return newShape;
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
        else if ("instance_geometry".equals(keyName))
        {
            if (this.geometries == null)
                this.geometries = new ArrayList<ColladaInstanceGeometry>();

            this.geometries.add((ColladaInstanceGeometry) value);
        }
        else
        {
            super.setField(keyName, value);
        }
    }

    protected List<ColladaRenderable> getChildren()
    {
        return this.children != null ? this.children : Collections.<ColladaRenderable>emptyList();
    }

    protected Matrix getMatrix()
    {
        if (this.matrix != null)
            return this.matrix;

        // TODO a node can have more than one matrix
        ColladaMatrix matrix = (ColladaMatrix) this.getField("matrix");
        if (matrix == null)
        {
            // Set matrix to identity so that we won't look for it again.
            this.matrix = Matrix.IDENTITY;
            return this.matrix;
        }

        String matrixAsString = matrix.getCharacters();
        String linesCleaned = matrixAsString.replaceAll("\n", " ");

        double[] doubles = this.parseDoubleArray(linesCleaned);

        this.matrix = Matrix.fromArray(doubles, 0, true);
        return this.matrix;
    }

    protected double[] parseDoubleArray(String doubleArrayString)
    {
        String[] arrayOfNumbers = doubleArrayString.trim().split("\\s+");
        double[] doubles = new double[arrayOfNumbers.length];

        int i = 0;
        for (String s : arrayOfNumbers)
        {
            doubles[i++] = Double.parseDouble(s);
        }

        return doubles;
    }
}
