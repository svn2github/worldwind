/*
 * Copyright (C) 2012 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.ogc.collada;

import gov.nasa.worldwind.WorldWind;
import gov.nasa.worldwind.geom.*;
import gov.nasa.worldwind.ogc.collada.impl.*;
import gov.nasa.worldwind.render.*;
import gov.nasa.worldwind.terrain.Terrain;
import gov.nasa.worldwind.util.WWUtil;

import java.awt.*;
import java.util.*;
import java.util.List;

/**
 * Represents the Collada <i>Node</i> element and provides access to its contents.
 *
 * @author pabercrombie
 * @version $Id$
 */
public class ColladaNode extends ColladaAbstractObject implements ColladaRenderable
{
    public static class ColladaOrderedRenderable implements OrderedRenderable
    {
        protected ColladaNode node;
        protected double eyeDistance;
        protected Matrix renderMatrix;

        public ColladaOrderedRenderable(ColladaNode node, Matrix renderMatrix, double eyeDistance)
        {
            this.node = node;
            this.eyeDistance = eyeDistance;
            this.renderMatrix = renderMatrix;
        }

        public double getDistanceFromEye()
        {
            return this.eyeDistance;
        }

        public void pick(DrawContext dc, Point pickPoint)
        {
            for (ColladaTriangleMesh shape : this.node.getShapes())
            {
                shape.pick(dc, pickPoint, this.renderMatrix);
            }
        }

        public void render(DrawContext dc)
        {
            for (ColladaTriangleMesh shape : this.node.getShapes())
            {
                shape.render(dc, this.renderMatrix);
            }
        }
    }

    /**
     * Children of this node. Children may be ColladaNode (direct child of this node) or ColladaInstanceNode (reference
     * to a node elsewhere in the current document, or another document).
     */
    protected List<ColladaRenderable> children;

    /** Shapes used to render geometry in this node. */
    protected List<ColladaTriangleMesh> shapes;

    /** Transform matrix for this node. */
    protected Matrix matrix;

    public ColladaNode(String ns)
    {
        super(ns);
    }

    public ColladaInstanceGeometry getInstanceGeometry()
    {
        return (ColladaInstanceGeometry) this.getField("instance_geometry");
    }

    public void preRender(ColladaTraversalContext tc, DrawContext dc)
    {
        // Create shapes for this node, if necessary
        if (this.shapes == null && this.getInstanceGeometry() != null)
        {
            this.shapes = this.createShapes(this.getInstanceGeometry());
        }

        List<ColladaRenderable> children = this.getChildren();
        if (WWUtil.isEmpty(children))
            return;

        Matrix matrix = this.getMatrix();
        try
        {
            if (matrix != null)
            {
                tc.pushMatrix();
                tc.multiplyMatrix(matrix);
            }

            for (ColladaRenderable node : this.getChildren())
            {
                node.preRender(tc, dc);
            }
        }
        finally
        {
            if (matrix != null)
                tc.popMatrix();
        }
    }

    public void render(ColladaTraversalContext tc, DrawContext dc)
    {
        Matrix matrix = this.getMatrix();
        try
        {
            if (matrix != null)
            {
                tc.pushMatrix();
                tc.multiplyMatrix(matrix);
            }

            for (ColladaTriangleMesh shape : this.getShapes())
            {
                shape.render(dc);
            }

            for (ColladaRenderable node : this.getChildren())
            {
                node.render(tc, dc);
            }

            // Create a new object to represent this node as an ordered renderable. The node may
            // be rendered multiple times with different transform matrices, so we can't use the node
            // itself as the ordered renderable.
            double eyeDistance = this.computeEyeDistance(dc);
            OrderedRenderable or = new ColladaOrderedRenderable(this, tc.peekMatrix(), eyeDistance);
            dc.addOrderedRenderable(or);
        }
        finally
        {
            if (matrix != null)
                tc.popMatrix();
        }
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

    protected List<ColladaTriangleMesh> getShapes()
    {
        return this.shapes != null ? this.shapes : Collections.<ColladaTriangleMesh>emptyList();
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
            return null;

        String matrixAsString = matrix.getCharacters();
        String linesCleaned = matrixAsString.replaceAll("\n", " ");

        double[] doubles = this.parseDoubleArray(linesCleaned);

        this.matrix = Matrix.fromArray(doubles, 0, true);
        return this.matrix;
    }

    /**
     * Computes a model-coordinate point from a position, applying this shape's altitude mode.
     *
     * @param terrain  the terrain to compute a point relative to the globe's surface.
     * @param position the position to compute a point for.
     *
     * @return the model-coordinate point corresponding to the position and this shape's shape type.
     */
    protected Vec4 computePoint(Terrain terrain, Position position)
    {
        int altitudeMode = this.getRoot().getAltitudeMode();

        if (altitudeMode == WorldWind.CLAMP_TO_GROUND)
            return terrain.getSurfacePoint(position.getLatitude(), position.getLongitude(), 0d);
        else if (altitudeMode == WorldWind.RELATIVE_TO_GROUND)
            return terrain.getSurfacePoint(position);

        // Raise the shape to accommodate vertical exaggeration applied to the terrain.
        double height = position.getElevation() * terrain.getVerticalExaggeration();

        return terrain.getGlobe().computePointFromPosition(position, height);
    }

    /**
     * Computes the minimum distance between this shape and the eye point.
     * <p/>
     * A {@link gov.nasa.worldwind.render.AbstractShape.AbstractShapeData} must be current when this method is called.
     *
     * @param dc the current draw context.
     *
     * @return the minimum distance from the shape to the eye point.
     */
    protected double computeEyeDistance(DrawContext dc)
    {
        Vec4 eyePoint = dc.getView().getEyePoint();

        Vec4 refPt = this.computePoint(dc.getTerrain(), this.getRoot().getPosition());
        if (refPt != null)
            return refPt.distanceTo3(eyePoint);

        return 0;
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
