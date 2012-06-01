/*
 * Copyright (C) 2012 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.ogc.collada;

import java.nio.*;
import java.util.*;

/**
 * Represents the Collada <i>Triangles</i> element and provides access to its contents.
 *
 * @author pabercrombie
 * @version $Id$
 */
public class ColladaTriangles extends ColladaAbstractObject
{
    protected List<ColladaInput> inputs = new ArrayList<ColladaInput>();

    public ColladaTriangles(String ns)
    {
        super(ns);
    }

    public List<ColladaInput> getInputs()
    {
        return this.inputs;
    }

    public int getCount()
    {
        return Integer.parseInt((String) this.getField("count"));
    }

    public String getMaterial()
    {
        return (String) this.getField("material");
    }

    public ColladaAccessor getVertexAccessor()
    {
        String vertexUri = null;
        for (ColladaInput input : this.getInputs())
        {
            if ("VERTEX".equals(input.getSemantic()))
            {
                vertexUri = input.getSource();
                break;
            }
        }

        if (vertexUri == null)
            return null;

        String positionUri = null;
        ColladaVertices vertices = (ColladaVertices) this.getRoot().resolveReference(vertexUri);
        for (ColladaInput input : vertices.getInputs())
        {
            if ("POSITION".equals(input.getSemantic()))
            {
                positionUri = input.getSource();
                break;
            }
        }

        if (positionUri == null)
            return null;

        ColladaSource source = (ColladaSource) this.getRoot().resolveReference(positionUri);
        return (source != null) ? source.getAccessor() : null;
    }

    public ColladaAccessor getNormalAccessor()
    {
        String sourceUri = null;
        for (ColladaInput input : this.getInputs())
        {
            if ("NORMAL".equals(input.getSemantic()))
            {
                sourceUri = input.getSource();
                break;
            }
        }

        if (sourceUri == null)
            return null;

        ColladaSource source = (ColladaSource) this.getRoot().resolveReference(sourceUri);
        return (source != null) ? source.getAccessor() : null;
    }

    public ColladaAccessor getTexCoordAccessor()
    {
        String sourceUri = null;
        for (ColladaInput input : this.getInputs())
        {
            if ("TEXCOORD".equals(input.getSemantic()))
            {
                sourceUri = input.getSource();
                break;
            }
        }

        if (sourceUri == null)
            return null;

        ColladaSource source = (ColladaSource) this.getRoot().resolveReference(sourceUri);
        return (source != null) ? source.getAccessor() : null;
    }

    public void getNormals(FloatBuffer buffer)
    {
        // TODO don't allocate temp buffers here

        ColladaAccessor accessor = this.getNormalAccessor();
        int normalCount = accessor.size();

        FloatBuffer normals = FloatBuffer.allocate(normalCount * 3);
        accessor.fillBuffer(normals);

        IntBuffer indices = IntBuffer.allocate(this.getCount() * 3);
        this.getIndices("NORMAL", indices);

        indices.rewind();
        while (indices.hasRemaining())
        {
            int i = indices.get();
            buffer.put(normals.get(i));
            buffer.put(normals.get(i + 1));
            buffer.put(normals.get(i + 2));
        }
    }

    public void getTextureCoordinates(FloatBuffer buffer)
    {
        // TODO don't allocate temp buffers here

        ColladaAccessor accessor = this.getTexCoordAccessor();
        int count = accessor.size();

        FloatBuffer texCoords = FloatBuffer.allocate(count * 2);
        accessor.fillBuffer(texCoords);

        IntBuffer indices = IntBuffer.allocate(this.getCount() * 3);
        this.getIndices("TEXCOORD", indices);

        indices.rewind();
        while (indices.hasRemaining())
        {
            int i = indices.get() * 2;
            buffer.put(texCoords.get(i));
            buffer.put(texCoords.get(i + 1));
        }
    }

    public void getVertices(FloatBuffer buffer)
    {
        // TODO don't allocate temp buffers here

        ColladaAccessor accessor = this.getVertexAccessor();
        int count = accessor.size();

        FloatBuffer vertexCoords = FloatBuffer.allocate(count * 3);
        accessor.fillBuffer(vertexCoords);

        IntBuffer indices = IntBuffer.allocate(this.getCount() * 3);
        this.getIndices("VERTEX", indices);

        indices.rewind();
        while (indices.hasRemaining())
        {
            int i = indices.get() * 3;
            buffer.put(vertexCoords.get(i));
            buffer.put(vertexCoords.get(i + 1));
            buffer.put(vertexCoords.get(i + 2));
        }
    }

    public void getVertexIndices(IntBuffer buffer)
    {
        this.getIndices("VERTEX", buffer);
    }

    protected void getIndices(String semantic, IntBuffer buffer)
    {
        ColladaInput input = null;
        for (ColladaInput in : this.getInputs())
        {
            if (semantic.equals(in.getSemantic()))
            {
                input = in;
                break;
            }
        }
        if (input == null)
            return;

        ColladaP primitives = (ColladaP) this.getField("p");

        int offset = input.getOffset();

        int[] intData = this.getIntArrayFromString((String) primitives.getField("CharactersContent"));

        int vertsPerTri = 3;

        int sourcesStride = this.getInputs().size();
        for (int i = 0; i < this.getCount(); i++)
        {
            int index1 = i * (vertsPerTri * sourcesStride);
            int index2 = index1 + sourcesStride;
            int index3 = index1 + (2 * sourcesStride);

            buffer.put(intData[index1 + offset]);
            buffer.put(intData[index2 + offset]);
            buffer.put(intData[index3 + offset]);
        }
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

    @Override
    public void setField(String keyName, Object value)
    {
        if (keyName.equals("input"))
        {
            this.inputs.add((ColladaInput) value);
        }
        else
        {
            super.setField(keyName, value);
        }
    }
}
