/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.util;

import javax.media.opengl.glu.*;
import java.nio.*;

/**
 * TODO: Combine these capabilities into PolygonTessellator with support for pattern used by ShapefileExtrudedPolygons.
 * TODO: Keep the combined class in package gov.nasa.worldwind.util.
 *
 * @author dcollins
 * @version $Id$
 */
public class PolygonTessellator2
{
    protected static class TessCallbackAdapter extends GLUtessellatorCallbackAdapter
    {
        @Override
        public void beginData(int type, Object userData)
        {
            ((PolygonTessellator2) userData).tessBegin(type);
        }

        @Override
        public void edgeFlagData(boolean boundaryEdge, Object userData)
        {
            ((PolygonTessellator2) userData).tessEdgeFlag(boundaryEdge);
        }

        @Override
        public void vertexData(Object vertexData, Object userData)
        {
            ((PolygonTessellator2) userData).tessVertex(vertexData);
        }

        @Override
        public void endData(Object userData)
        {
            ((PolygonTessellator2) userData).tessEnd();
        }

        @Override
        public void combineData(double[] coords, Object[] vertexData, float[] weight, Object[] outData, Object userData)
        {
            ((PolygonTessellator2) userData).tessCombine(coords, vertexData, weight, outData);
        }
    }

    protected GLUtessellator tess;
    protected FloatBuffer vertices = FloatBuffer.allocate(10);
    protected IntBuffer interiorIndices = IntBuffer.allocate(10);
    protected IntBuffer boundaryIndices = IntBuffer.allocate(10);
    protected Range polygonVertexRange = new Range(0, 0);
    protected int vertexStride = 3;
    protected boolean isBoundaryEdge;
    protected float[] vertex = new float[3];
    protected double[] coords = new double[3];

    public PolygonTessellator2()
    {
        this.tess = GLU.gluNewTess();
        TessCallbackAdapter callback = new TessCallbackAdapter();
        GLU.gluTessCallback(this.tess, GLU.GLU_TESS_BEGIN_DATA, callback);
        GLU.gluTessCallback(this.tess, GLU.GLU_TESS_EDGE_FLAG_DATA, callback);
        GLU.gluTessCallback(this.tess, GLU.GLU_TESS_VERTEX_DATA, callback);
        GLU.gluTessCallback(this.tess, GLU.GLU_TESS_END_DATA, callback);
        GLU.gluTessCallback(this.tess, GLU.GLU_TESS_COMBINE_DATA, callback);
    }

    public int getVertexCount()
    {
        return this.vertices.position() / this.vertexStride;
    }

    public int getVertexStride()
    {
        return this.vertexStride;
    }

    public void setVertexStride(int stride)
    {
        this.vertexStride = stride;
    }

    public FloatBuffer getVertices(FloatBuffer buffer)
    {
        int lim = this.vertices.limit();
        int pos = this.vertices.position();

        buffer.put((FloatBuffer) this.vertices.flip());

        this.vertices.limit(lim);
        this.vertices.position(pos);

        return buffer;
    }

    public int getInteriorIndexCount()
    {
        return this.interiorIndices.position();
    }

    public IntBuffer getInteriorIndices(IntBuffer buffer)
    {
        int lim = this.interiorIndices.limit();
        int pos = this.interiorIndices.position();

        buffer.put((IntBuffer) this.interiorIndices.flip());

        this.interiorIndices.limit(lim);
        this.interiorIndices.position(pos);

        return buffer;
    }

    public int getBoundaryIndexCount()
    {
        return this.boundaryIndices.position();
    }

    public IntBuffer getBoundaryIndices(IntBuffer buffer)
    {
        int lim = this.boundaryIndices.limit();
        int pos = this.boundaryIndices.position();

        buffer.put((IntBuffer) this.boundaryIndices.flip());

        this.boundaryIndices.limit(lim);
        this.boundaryIndices.position(pos);

        return buffer;
    }

    public Range getPolygonVertexRange()
    {
        return this.polygonVertexRange;
    }

    public void reset()
    {
        this.resetVertices();
        this.resetIndices();
    }

    public void resetVertices()
    {
        this.vertices.clear();
    }

    public void resetIndices()
    {
        this.interiorIndices.clear();
        this.boundaryIndices.clear();
    }

    public void setPolygonNormal(double x, double y, double z)
    {
        GLU.gluTessNormal(this.tess, x, y, z);
    }

    public void beginPolygon()
    {
        GLU.gluTessBeginPolygon(this.tess, this); // Use this as the polygon user data to enable callbacks.

        this.polygonVertexRange.location = this.vertices.position() / this.vertexStride;
        this.polygonVertexRange.length = 0;
    }

    public void beginContour()
    {
        GLU.gluTessBeginContour(this.tess);
    }

    public void addVertex(double x, double y, double z)
    {
        this.coords[0] = x;
        this.coords[1] = y;
        this.coords[2] = z;

        int index = this.putVertex(x, y, z);
        GLU.gluTessVertex(this.tess, this.coords, 0, index); // Associate the vertex with its index in the vertex array.
    }

    public void endContour()
    {
        GLU.gluTessEndContour(this.tess);
    }

    public void endPolygon()
    {
        GLU.gluTessEndPolygon(this.tess);

        this.polygonVertexRange.length = this.vertices.position() / this.vertexStride;
        this.polygonVertexRange.length -= this.polygonVertexRange.location;
    }

    @SuppressWarnings("UnusedParameters")
    protected void tessBegin(int type)
    {
        // Intentionally left blank.
    }

    protected void tessEdgeFlag(boolean boundaryEdge)
    {
        this.isBoundaryEdge = boundaryEdge;
    }

    protected void tessVertex(Object vertexData)
    {
        // Accumulate interior indices appropriate for use as GL_interiorIndices primitives. Based on the GLU
        // tessellator documentation we can assume that the tessellator is providing interiorIndices because it's
        // configured with the edgeFlag callback.
        int index = (Integer) vertexData;
        this.putInteriorIndex(index);

        // Accumulate outline indices appropriate for use as GL_boundaryIndices. The tessBoundaryEdge flag indicates
        // whether or not the triangle edge starting with the current vertex is a boundary edge.
        if ((this.boundaryIndices.position() % 2) == 1)
        {
            this.putBoundaryIndex(index);
        }
        if (this.isBoundaryEdge)
        {
            this.putBoundaryIndex(index);

            int interiorCount = this.interiorIndices.position();
            if (interiorCount > 0 && (interiorCount % 3) == 0)
            {
                int firstTriIndex = this.interiorIndices.get(interiorCount - 3);
                this.putBoundaryIndex(firstTriIndex);
            }
        }
    }

    protected void tessEnd()
    {
        // Intentionally left blank.
    }

    protected void tessCombine(double[] coords, Object[] vertexData, float[] weight, Object[] outData)
    {
        outData[0] = this.putVertex(coords[0], coords[1], coords[2]);

        // TODO: Implement a caller-specified combine callback to enable customizing the vertex data added.
    }

    protected int putVertex(double x, double y, double z)
    {
        this.vertex[0] = (float) x;
        this.vertex[1] = (float) y;
        this.vertex[2] = (float) z;

        int index = this.vertices.position() / this.vertexStride;

        if (this.vertices.remaining() < this.vertexStride)
        {
            int capacity = this.vertices.capacity() + this.vertices.capacity() / 2; // increase capacity by 50%
            FloatBuffer buffer = FloatBuffer.allocate(capacity);
            buffer.put((FloatBuffer) this.vertices.flip());
            buffer.put(this.vertex, 0, this.vertexStride);
            this.vertices = buffer;
        }
        else
        {
            this.vertices.put(this.vertex, 0, this.vertexStride);
        }

        return index;
    }

    protected void putInteriorIndex(int i)
    {
        if (!this.interiorIndices.hasRemaining())
        {
            int capacity = this.interiorIndices.capacity()
                + this.interiorIndices.capacity() / 2; // increase capacity by 50%
            IntBuffer buffer = IntBuffer.allocate(capacity);
            buffer.put((IntBuffer) this.interiorIndices.flip());
            buffer.put(i);
            this.interiorIndices = buffer;
        }
        else
        {
            this.interiorIndices.put(i);
        }
    }

    protected void putBoundaryIndex(int i)
    {
        if (!this.boundaryIndices.hasRemaining())
        {
            int capacity = this.boundaryIndices.capacity()
                + this.boundaryIndices.capacity() / 2; // increase capacity by 50%
            IntBuffer buffer = IntBuffer.allocate(capacity);
            buffer.put((IntBuffer) this.boundaryIndices.flip());
            buffer.put(i);
            this.boundaryIndices = buffer;
        }
        else
        {
            this.boundaryIndices.put(i);
        }
    }
}
