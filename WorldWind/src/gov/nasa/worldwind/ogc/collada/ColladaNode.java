/*
 * Copyright (C) 2012 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.ogc.collada;

import gov.nasa.worldwind.WorldWind;
import gov.nasa.worldwind.geom.Angle;
import gov.nasa.worldwind.ogc.collada.impl.ColladaNodeShape;
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
    protected List<ColladaNodeShape> shapes;

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
            for (ColladaNodeShape shape : this.shapes)
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

    protected List<ColladaNodeShape> createShapes(ColladaInstanceGeometry geomInstance)
    {
        ColladaGeometry geometry = geomInstance.get();
        if (geometry == null)
            return null;

        List<ColladaNodeShape> newShapes = new ArrayList<ColladaNodeShape>();

        ColladaMesh mesh = geometry.getMesh();

        List<ColladaSource> sources = mesh.getSources();
        List<ColladaTriangles> triangles = mesh.getTriangles();
        List<ColladaVertices> vertices = mesh.getVertices();

        for (ColladaTriangles triangle : triangles)
        {
            ColladaNodeShape shape = new ColladaNodeShape();
            shape.setAltitudeMode(WorldWind.RELATIVE_TO_GROUND);
//            shape.setTexture(colladaRootFile, texture);

            shape.setModelPosition(this.getRoot().getPosition());
            shape.setHeading(Angle.ZERO); // TODO
            shape.setPitch(Angle.ZERO);
            shape.setRoll(Angle.ZERO);
            shape.setAltitudeMode(this.getRoot().getAltitudeMode());

            newShapes.add(shape);

            int count = Integer.parseInt((String) triangle.getField("count"));

            List<ColladaInput> inputs = triangle.getInputs();
            for (ColladaInput input : inputs)
            {
                String semantic = (String) input.getField("semantic");
                ColladaSource sourceForInput = getSourceFromInput(input, sources, vertices);
                int inputOffset = input.getOffset();

                float[] floatData = getFloatArrayFromString((String) ((ColladaFloatArray) sourceForInput.
                    getField("float_array")).getField("CharactersContent"));

                shape.addSource(semantic, inputOffset, floatData);
            }

            ColladaP elementsList = (ColladaP) triangle.getField("p");

            int[] intData = getIntArrayFromString((String) elementsList.getField("CharactersContent"));
            shape.setElements(count, intData);
        }

        return newShapes;
    }

    protected ColladaSource getSourceFromInput(ColladaInput input, List<ColladaSource> sources,
        List<ColladaVertices> inVertices)
    {
        String name = ((String) input.getField("source")).substring(1);

        for (ColladaVertices vertices : inVertices)           // probably need to have a usage object- since we arent preserving field "smeantic" in Vertices
        {
            if (vertices.getField("id").equals(name))
            {
                ColladaInput inputA = (ColladaInput) vertices.getField("input");
                name = ((String) inputA.getField("source")).substring(1);
                break;
            }
        }

        for (ColladaSource source : sources)
        {
            if (source.getField("id").equals(name))
            {
                return source;
            }
        }
        return null;
    }

    protected int[] getIntArrayFromString(String floatArrayString)
    {
        String[] arrayOfNumbers = floatArrayString.split(" ");
        int[] ints = new int[arrayOfNumbers.length];

        int i = 0;
        for (String s : arrayOfNumbers)
        {
            ints[i++] = Integer.parseInt(s);
        }

        return ints;
    }

    protected float[] getFloatArrayFromString(String floatArrayString)
    {
        String[] arrayOfNumbers = floatArrayString.split(" ");
        float[] floats = new float[arrayOfNumbers.length];

        int i = 0;
        for (String s : arrayOfNumbers)
        {
            floats[i++] = Float.parseFloat(s);
        }

        return floats;
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
