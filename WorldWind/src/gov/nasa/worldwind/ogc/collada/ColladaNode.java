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
    protected List<ColladaMeshShape> shapes;

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
            for (ColladaMeshShape shape : this.shapes)
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

    protected List<ColladaMeshShape> createShapes()
    {
        if (WWUtil.isEmpty(this.geometries))
            return Collections.emptyList();

        List<ColladaMeshShape> shapes = new ArrayList<ColladaMeshShape>();
        for (ColladaInstanceGeometry geometry : this.geometries)
        {
            this.createShapesForGeometry(geometry, shapes);
        }
        return shapes;
    }

    protected void createShapesForGeometry(ColladaInstanceGeometry geomInstance, List<ColladaMeshShape> shapes)
    {
        ColladaGeometry geometry = geomInstance.get();
        if (geometry == null)
            return;

        ColladaMesh mesh = geometry.getMesh();
        if (mesh == null)
            return;

        ColladaBindMaterial bindMaterial = geomInstance.getBindMaterial();

        ColladaRoot root = this.getRoot();
        Position position = root.getPosition();
        Angle heading = Angle.ZERO; // TODO
        Angle pitch = Angle.ZERO;
        Angle roll = Angle.ZERO;
        int altitudeMode = root.getAltitudeMode();

        List<ColladaTriangles> triangles = mesh.getTriangles();
        if (!WWUtil.isEmpty(triangles))
        {
            ColladaMeshShape newShape = ColladaMeshShape.createTriangleMesh(triangles, bindMaterial);

            newShape.setModelPosition(position);
            newShape.setHeading(heading);
            newShape.setPitch(heading);
            newShape.setRoll(heading);
            newShape.setAltitudeMode(altitudeMode);

            shapes.add(newShape);
        }

        List<ColladaLines> lines = mesh.getLines();
        if (!WWUtil.isEmpty(lines))
        {
            ColladaMeshShape newShape = ColladaMeshShape.createLineMesh(lines, bindMaterial);

            newShape.setModelPosition(position);
            newShape.setHeading(heading);
            newShape.setPitch(pitch);
            newShape.setRoll(roll);
            newShape.setAltitudeMode(altitudeMode);

            shapes.add(newShape);
        }
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
