/*
 * Copyright (C) 2012 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.ogc.collada.impl;

import com.sun.opengl.util.BufferUtil;
import gov.nasa.worldwind.cache.GpuResourceCache;
import gov.nasa.worldwind.geom.*;
import gov.nasa.worldwind.render.*;
import gov.nasa.worldwind.terrain.Terrain;
import gov.nasa.worldwind.util.Logging;

import javax.media.opengl.GL;
import java.nio.*;
import java.util.*;

/**
 * @author pabercrombie
 * @version $Id$
 */
public class ColladaNodeShape extends AbstractGeneralShape
{
    /**
     * This class holds globe-specific data for this shape. It's managed via the shape-data cache in {@link
     * gov.nasa.worldwind.render.AbstractShape.AbstractShapeData}.
     */
    protected static class ShapeData extends AbstractGeneralShape.ShapeData
    {
        /**
         * Construct a cache entry for this shape.
         *
         * @param dc    the current draw context.
         * @param shape this shape.
         */
        public ShapeData(DrawContext dc, AbstractGeneralShape shape)
        {
            super(dc, shape);
        }

        protected Matrix renderMatrix;
        protected Vec4 referenceCenter;
    }

    static class SourceData
    {
        private float[] floatData;
        private int inputOffset;

        public SourceData(float[] floatData, int inputOffset)
        {
            this.floatData = floatData;
            this.inputOffset = inputOffset;
        }
    }

    // TODO: not sure sources is the best way to specify geometry
    protected Map<String, SourceData> sources = new HashMap<String, SourceData>();
    protected int[] elementsFromPElement;
    protected int numberOfElements;

    /**
     * The vertex data buffer for this shape data. The first half contains vertex coordinates, the second half contains
     * normals.
     */
    protected FloatBuffer coordBuffer;
    /** The slice of the <code>coordBuffer</code> that contains normals. */
    protected FloatBuffer normalBuffer;
    /** The index of the first normal in the <code>coordBuffer</code>. */
    protected int normalBufferPosition;
    /** The indices identifying the shape's vertices in the vertex buffer. */
    protected IntBuffer vertexIndexBuffer;

    public void addSource(String semantic, int inputOffset, float[] floatData)
    {
        this.sources.put(semantic, new SourceData(floatData, inputOffset));
    }

    public void setElements(int inNumberOfElements, int[] intData)
    {
        this.numberOfElements = inNumberOfElements;
        this.elementsFromPElement = intData;
    }

    @Override
    public List<Intersection> intersect(Line line, Terrain terrain) throws InterruptedException
    {
        return null; // TODO
    }

    @Override
    protected boolean mustApplyTexture(DrawContext dc)
    {
        return false; // TODO
    }

    @Override
    protected boolean doMakeOrderedRenderable(DrawContext dc)
    {
        // Do the minimum necessary to determine the model's reference point, extent and eye distance.
        this.createMinimalGeometry(dc, (ShapeData) this.getCurrent());

        // If the shape is less that a pixel in size, don't render it.
        // TODO compute model extent
//        if (this.getCurrent().getExtent() == null || dc.isSmall(this.getExtent(), 1))
//            return false;

        if (!this.intersectsFrustum(dc))
            return false;

        this.createFullGeometry(dc);

        return true;
    }

    @Override
    protected boolean isOrderedRenderableValid(DrawContext dc)
    {
        return this.coordBuffer != null;
    }

    @Override
    protected boolean mustApplyLighting(DrawContext dc, ShapeAttributes activeAttrs)
    {
        return super.mustApplyLighting(dc, activeAttrs) && this.sources.containsKey("NORMAL");
    }

    @Override
    protected boolean mustCreateNormals(DrawContext dc, ShapeAttributes activeAttrs)
    {
        return super.mustCreateNormals(dc, activeAttrs) && this.sources.containsKey("NORMAL");
    }

    @Override
    protected void doDrawOutline(DrawContext dc)
    {
        // Do nothing. All drawing is performed in doDrawInterior
    }

    @Override
    protected AbstractShapeData createCacheEntry(DrawContext dc)
    {
        return new ShapeData(dc, this);
    }

    @Override
    protected void doDrawInterior(DrawContext dc)
    {
        dc.getGL().glDisable(GL.GL_TEXTURE_2D);
        dc.getGL().glDisableClientState(GL.GL_TEXTURE_COORD_ARRAY);

        this.setModelViewMatrix(dc);

        if (this.shouldUseVBOs(dc))
        {
            int[] vboIds = this.getVboIds(dc);
            if (vboIds != null)
                this.doDrawInteriorVBO(dc, vboIds);
            else
                this.doDrawInteriorVA(dc);
        }
        else
        {
            this.doDrawInteriorVA(dc);
        }
    }

    protected void doDrawInteriorVA(DrawContext dc)
    {
        GL gl = dc.getGL();

        if (!dc.isPickingMode() && this.mustApplyLighting(dc) && this.normalBuffer != null)
            gl.glNormalPointer(GL.GL_FLOAT, 0, this.normalBuffer.rewind());

        FloatBuffer vb = this.coordBuffer;
        gl.glVertexPointer(3, GL.GL_FLOAT, 0, vb.rewind());

        IntBuffer ib = this.vertexIndexBuffer;
        gl.glDrawElements(GL.GL_TRIANGLES, ib.limit(), GL.GL_UNSIGNED_INT, ib.rewind());
    }

    protected void doDrawInteriorVBO(DrawContext dc, int[] vboIds)
    {
        GL gl = dc.getGL();

        gl.glBindBuffer(GL.GL_ARRAY_BUFFER, vboIds[0]);
        gl.glBindBuffer(GL.GL_ELEMENT_ARRAY_BUFFER, vboIds[1]);

        gl.glVertexPointer(3, GL.GL_FLOAT, 0, 0);

        if (!dc.isPickingMode() && this.mustApplyLighting(dc) && this.normalBuffer != null)
        {
            gl.glNormalPointer(GL.GL_FLOAT, 0, this.normalBufferPosition * BufferUtil.SIZEOF_FLOAT);
        }

        gl.glDrawElements(GL.GL_TRIANGLES, this.vertexIndexBuffer.limit(), GL.GL_UNSIGNED_INT, 0);

        gl.glBindBuffer(GL.GL_ARRAY_BUFFER, 0);
        gl.glBindBuffer(GL.GL_ELEMENT_ARRAY_BUFFER, 0);
    }

    /**
     * Called during drawing to set the modelview matrix to apply the correct position, scale and orientation for this
     * shape.
     *
     * @param dc the current DrawContext
     *
     * @throws IllegalArgumentException if draw context is null or the draw context GL is null
     */
    protected void setModelViewMatrix(DrawContext dc)
    {
        if (dc.getGL() == null)
        {
            String message = Logging.getMessage("nullValue.DrawingContextGLIsNull");
            Logging.logger().severe(message);
            throw new IllegalStateException(message);
        }

        Matrix matrix = dc.getView().getModelviewMatrix();
        matrix = matrix.multiply(this.computeRenderMatrix(dc));

        GL gl = dc.getGL();

        gl.glMatrixMode(GL.GL_MODELVIEW);

        double[] matrixArray = new double[16];
        matrix.toArray(matrixArray, 0, false);
        gl.glLoadMatrixd(matrixArray, 0);
    }

    /**
     * Compute enough geometry to determine this shape's extent, reference point and eye distance.
     * <p/>
     * A {@link gov.nasa.worldwind.render.AbstractShape.AbstractShapeData} must be current when this method is called.
     *
     * @param dc        the current draw context.
     * @param shapeData the current shape data for this shape.
     */
    protected void createMinimalGeometry(DrawContext dc, ShapeData shapeData)
    {
        Vec4 refPt = this.computeReferencePoint(dc.getTerrain());
        if (refPt == null)
            return;
        shapeData.setReferencePoint(refPt);

//        computeExtent(dc);  // TODO: compute the model's extent

        shapeData.setEyeDistance(this.computeEyeDistance(dc, shapeData));
        shapeData.setGlobeStateKey(dc.getGlobe().getGlobeStateKey(dc));
        shapeData.setVerticalExaggeration(dc.getVerticalExaggeration());
    }

    protected void createFullGeometry(DrawContext dc)
    {
        this.fillIndexBuffers();
        this.createGeometry(dc);

        if (this.mustCreateNormals(dc))
            this.createNormals();
        else
            this.normalBuffer = null;
    }

    protected void createGeometry(DrawContext dc)
    {
        // hard coded for sample data, move to loops and hashmaps
        SourceData vertexSource = this.sources.get("VERTEX");

        int size = vertexSource.floatData.length;
        if (this.mustCreateNormals(dc))
        {
            size += (this.numberOfElements * 3);
        }

        if (this.coordBuffer != null && this.coordBuffer.capacity() >= size)
            this.coordBuffer.clear();
        else
            this.coordBuffer = BufferUtil.newFloatBuffer(size);

        // Capture the position position at which normals buffer starts (in case there are normals)
        this.normalBufferPosition = vertexSource.floatData.length;

        this.coordBuffer.put(vertexSource.floatData);
    }

    protected void fillVBO(DrawContext dc)
    {
        GL gl = dc.getGL();
        ShapeData shapeData = (ShapeData) getCurrentData();

        int[] vboIds = (int[]) dc.getGpuResourceCache().get(shapeData.getVboCacheKey());
        if (vboIds == null)
        {
            int size = this.coordBuffer.limit() * BufferUtil.SIZEOF_FLOAT;
            size += this.vertexIndexBuffer.limit() * BufferUtil.SIZEOF_FLOAT;

            vboIds = new int[2];
            gl.glGenBuffers(vboIds.length, vboIds, 0);
            dc.getGpuResourceCache().put(shapeData.getVboCacheKey(), vboIds, GpuResourceCache.VBO_BUFFERS, size);
        }

        try
        {
            IntBuffer ib = this.vertexIndexBuffer;
            gl.glBindBuffer(GL.GL_ELEMENT_ARRAY_BUFFER, vboIds[1]);
            gl.glBufferData(GL.GL_ELEMENT_ARRAY_BUFFER, ib.limit() * BufferUtil.SIZEOF_FLOAT, ib.rewind(),
                GL.GL_DYNAMIC_DRAW);
        }
        finally
        {
            gl.glBindBuffer(GL.GL_ELEMENT_ARRAY_BUFFER, 0);
        }

        try
        {
            FloatBuffer vb = this.coordBuffer;
            gl.glBindBuffer(GL.GL_ARRAY_BUFFER, vboIds[0]);
            gl.glBufferData(GL.GL_ARRAY_BUFFER, vb.limit() * BufferUtil.SIZEOF_FLOAT, vb.rewind(), GL.GL_STATIC_DRAW);
        }
        finally
        {
            gl.glBindBuffer(GL.GL_ARRAY_BUFFER, 0);
        }
    }

    /** Create this shape's vertex normals. */
    protected void createNormals()
    {
        SourceData normalSource = this.sources.get("NORMAL");

        this.coordBuffer.position(this.normalBufferPosition);
        this.normalBuffer = this.coordBuffer.slice();

        int vertsPerTri = 3;
        int normalOffset = normalSource.inputOffset;

        float[] normals = normalSource.floatData;
        int sourcesStride = this.sources.size();
        for (int i = 0; i < this.numberOfElements; i++)
        {
            int index1 = i * (vertsPerTri * sourcesStride);
            int index2 = index1 + (sourcesStride);
            int index3 = index1 + (2 * sourcesStride);

            this.normalBuffer.put(normals[3 * this.elementsFromPElement[index1 + normalOffset]]);
            this.normalBuffer.put(normals[3 * this.elementsFromPElement[index2 + normalOffset]]);
            this.normalBuffer.put(normals[3 * this.elementsFromPElement[index3 + normalOffset]]);
        }
    }

    protected void fillIndexBuffers()
    {
        int vertsPerTri = 3;

        SourceData vertexSource = this.sources.get("VERTEX");

        int vertexOffset = (vertexSource != null) ? vertexSource.inputOffset : 0;
        if (vertexSource == null)
            return;

        int size = this.numberOfElements * vertsPerTri;
        if (this.vertexIndexBuffer == null || this.vertexIndexBuffer.capacity() < size)
            this.vertexIndexBuffer = BufferUtil.newIntBuffer(size);
        else
            this.vertexIndexBuffer.clear();

        int sourcesStride = this.sources.size();
        for (int i = 0; i < this.numberOfElements; i++)
        {
            int index1 = i * (vertsPerTri * sourcesStride);
            int index2 = index1 + (sourcesStride);
            int index3 = index1 + (2 * sourcesStride);

            this.vertexIndexBuffer.put(this.elementsFromPElement[index1 + vertexOffset]);
            this.vertexIndexBuffer.put(this.elementsFromPElement[index2 + vertexOffset]);
            this.vertexIndexBuffer.put(this.elementsFromPElement[index3 + vertexOffset]);
        }
    }

    /**
     * Computes this shape's reference center.
     *
     * @param dc the current draw context.
     *
     * @return the computed reference center, or null if it cannot be computed.
     */
    protected Vec4 computeReferenceCenter(DrawContext dc)
    {
        Position pos = this.getReferencePosition();
        if (pos == null)
            return null;

        return this.computePoint(dc.getTerrain(), pos);
    }

    /**
     * Computes the transform to use during rendering to orient the model.
     *
     * @param dc the current draw context
     *
     * @return the modelview transform for this shape.
     *
     * @throws IllegalArgumentException if draw context is null or the referencePoint is null
     */
    protected Matrix computeRenderMatrix(DrawContext dc)
    {
        ShapeData current = (ShapeData) this.getCurrent();

        // TODO cache this value
//        if (current.referenceCenter == null)
//        {
        current.referenceCenter = this.computeReferenceCenter(dc);
//        }
        Position refPosition = dc.getGlobe().computePositionFromPoint(current.referenceCenter);

        Matrix matrix = dc.getGlobe().computeSurfaceOrientationAtPosition(refPosition);

        if (current.renderMatrix == null)     // just cache my local stuff for now
        {
            Matrix matrixLocal = Matrix.IDENTITY;

            if (this.heading != null)
                matrixLocal = matrixLocal.multiply(Matrix.fromRotationZ(Angle.POS360.subtract(this.heading)));

            if (this.pitch != null)
                matrixLocal = matrixLocal.multiply(Matrix.fromRotationX(this.pitch));

            if (this.roll != null)
                matrixLocal = matrixLocal.multiply(Matrix.fromRotationY(this.roll));

            current.renderMatrix = matrixLocal;
        }

        matrix = matrix.multiply(current.renderMatrix);
        return matrix;
    }
}
