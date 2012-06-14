/*
 * Copyright (C) 2012 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.ogc.collada;

import gov.nasa.worldwind.util.Logging;

import java.nio.*;
import java.util.*;

/**
 * Base class for COLLADA geometry (lines and triangles).
 *
 * @author pabercrombie
 * @version $Id: ColladaAbstractGeometry.java 618 2012-06-01 17:35:11Z pabercrombie $
 */
public abstract class ColladaAbstractGeometry extends ColladaAbstractObject
{
    /**
     * Default semantic that identifies texture coordinates. Used the a file does not specify the semantic using a
     * <i>bind_vertex_input</i> element.
     */
    public static final String DEFAULT_TEX_COORD_SEMANTIC = "TEXCOORD";

    protected static final int COORDS_PER_VERTEX = 3;
    protected static final int TEX_COORDS_PER_VERTEX = 2;

    protected List<ColladaInput> inputs = new ArrayList<ColladaInput>();

    protected abstract int getVerticesPerShape();

    public ColladaAbstractGeometry(String ns)
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

    /**
     * Indicates the accessor for texture coordinates.
     *
     * @param semantic Semantic that identifies the texture coordinates. May be null, in which case the semantic
     *                 "TEXCOORD" is used.
     *
     * @return The texture coordinates accessor, or null if the accessor cannot be resolved.
     */
    public ColladaAccessor getTexCoordAccessor(String semantic)
    {
        if (semantic == null)
            semantic = DEFAULT_TEX_COORD_SEMANTIC;

        String sourceUri = null;
        for (ColladaInput input : this.getInputs())
        {
            if (semantic.equals(input.getSemantic()))
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
        if (buffer == null)
        {
            String msg = Logging.getMessage("nullValue.BufferIsNull");
            Logging.logger().severe(msg);
            throw new IllegalArgumentException(msg);
        }

        // TODO don't allocate temp buffers here

        ColladaAccessor accessor = this.getNormalAccessor();
        int normalCount = accessor.size();

        FloatBuffer normals = FloatBuffer.allocate(normalCount);
        accessor.fillBuffer(normals);

        int vertsPerShape = this.getVerticesPerShape();
        IntBuffer indices = IntBuffer.allocate(this.getCount() * vertsPerShape);
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

    public void getTextureCoordinates(FloatBuffer buffer, String semantic)
    {
        if (buffer == null)
        {
            String msg = Logging.getMessage("nullValue.BufferIsNull");
            Logging.logger().severe(msg);
            throw new IllegalArgumentException(msg);
        }

        // TODO don't allocate temp buffers here

        if (semantic == null)
            semantic = DEFAULT_TEX_COORD_SEMANTIC;

        ColladaAccessor accessor = this.getTexCoordAccessor(semantic);
        int count = accessor.size();

        FloatBuffer texCoords = FloatBuffer.allocate(count);
        accessor.fillBuffer(texCoords);

        int vertsPerShape = this.getVerticesPerShape();
        IntBuffer indices = IntBuffer.allocate(this.getCount() * vertsPerShape);
        this.getIndices(semantic, indices);

        indices.rewind();
        while (indices.hasRemaining())
        {
            int i = indices.get() * TEX_COORDS_PER_VERTEX;
            buffer.put(texCoords.get(i));
            buffer.put(texCoords.get(i + 1));
        }
    }

    public void getVertices(FloatBuffer buffer)
    {
        if (buffer == null)
        {
            String msg = Logging.getMessage("nullValue.BufferIsNull");
            Logging.logger().severe(msg);
            throw new IllegalArgumentException(msg);
        }

        // TODO don't allocate temp buffers here

        ColladaAccessor accessor = this.getVertexAccessor();
        int count = accessor.size();

        FloatBuffer vertexCoords = FloatBuffer.allocate(count);
        accessor.fillBuffer(vertexCoords);

        int vertsPerShape = this.getVerticesPerShape();

        IntBuffer indices = IntBuffer.allocate(this.getCount() * vertsPerShape);
        this.getIndices("VERTEX", indices);

        indices.rewind();
        while (indices.hasRemaining())
        {
            int i = indices.get() * COORDS_PER_VERTEX;
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

        int vertsPerShape = this.getVerticesPerShape();

        int sourcesStride = this.getInputs().size();
        for (int i = 0; i < this.getCount(); i++)
        {
            for (int j = 0; j < vertsPerShape; j++)
            {
                int index = i * (vertsPerShape * sourcesStride) + j * sourcesStride;
                buffer.put(intData[index + offset]);
            }
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
