/*
 * Copyright (C) 2012 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.ogc.collada.impl;

import com.sun.opengl.util.BufferUtil;
import gov.nasa.worldwind.cache.GpuResourceCache;
import gov.nasa.worldwind.geom.*;
import gov.nasa.worldwind.ogc.collada.*;
import gov.nasa.worldwind.render.*;
import gov.nasa.worldwind.terrain.Terrain;
import gov.nasa.worldwind.util.*;

import javax.media.opengl.GL;
import java.nio.FloatBuffer;
import java.util.List;

/**
 * @author pabercrombie
 * @version $Id$
 */
public class ColladaTriangleMesh extends AbstractGeneralShape
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

    protected static final int VERTS_PER_TRI = 3;
    protected static final int TEX_COORDS_PER_TRI = 2;
    protected static final int COORDS_PER_VERT = 3;

    /**
     * The vertex data buffer for this shape data. The first half contains vertex coordinates, the second half contains
     * normals.
     */
    // TODO use drawElements instead of drawArrays
    protected FloatBuffer coordBuffer;
    /** The slice of the <code>coordBuffer</code> that contains normals. */
    protected FloatBuffer normalBuffer;
    /** The index of the first normal in the <code>coordBuffer</code>. */
    protected int normalBufferPosition;
    /** Texture coordinates. */
    protected FloatBuffer textureCoordsBuffer;

    protected ColladaTriangles colladaGeometry;
    protected ColladaBindMaterial bindMaterial;

    protected WWTexture texture;

    /**
     * Create a triangle mesh shape.
     *
     * @param geometry COLLADA element that defines geometry for this shape.
     */
    public ColladaTriangleMesh(ColladaTriangles geometry, ColladaBindMaterial bindMaterial)
    {
        if (geometry == null)
        {
            String message = Logging.getMessage("nullValue.ObjectIsNull");
            Logging.logger().severe(message);
            throw new IllegalStateException(message);
        }

        this.colladaGeometry = geometry;
        this.bindMaterial = bindMaterial;
    }

    @Override
    public List<Intersection> intersect(Line line, Terrain terrain) throws InterruptedException
    {
        return null; // TODO
    }

    @Override
    protected boolean mustApplyTexture(DrawContext dc)
    {
        return this.colladaGeometry.getTexCoordAccessor() != null
            && this.getTexture() != null; // TODO determine if texture is available
    }

    protected String getTextureSource()
    {
        ColladaTechniqueCommon techniqueCommon = this.bindMaterial.getTechniqueCommon();
        if (techniqueCommon == null)
            return null;

        String materialSource = this.colladaGeometry.getMaterial();
        if (materialSource == null)
            return null;

        ColladaInstanceMaterial myMaterialInstance = null;
        for (ColladaInstanceMaterial material : techniqueCommon.getMaterials())
        {
            if (materialSource.equals(material.getSymbol()))
            {
                myMaterialInstance = material;
                break;
            }
        }

        if (myMaterialInstance == null)
            return null;

        // Attempt to resolve the instance. The material may not be immediately available.
        ColladaMaterial myMaterial = myMaterialInstance.get();
        if (myMaterial == null)
            return null;

        ColladaInstanceEffect myEffectInstance = myMaterial.getInstanceEffect();
        if (myEffectInstance == null)
            return null;

        // Attempt to resolve effect. The effect may not be immediately available.
        ColladaEffect myEffect = myEffectInstance.get();
        if (myEffect == null)
            return null;

        return myEffect.getImageRef();
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

        if (this.coordBuffer == null)
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
        return super.mustApplyLighting(dc, activeAttrs) && this.colladaGeometry.getNormalAccessor() != null;
    }

    @Override
    protected boolean mustCreateNormals(DrawContext dc, ShapeAttributes activeAttrs)
    {
        return super.mustCreateNormals(dc, activeAttrs) && this.colladaGeometry.getNormalAccessor() != null;
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

    /**
     * Indicates the texture applied to this shape.
     *
     * @return The texture that must be applied to the shape, or null if there is no texture, or the texture is not
     *         available.
     */
    protected WWTexture getTexture()
    {
        if (this.texture != null)
            return this.texture;

        String source = this.getTextureSource();
        if (source != null)
        {
            Object o = this.colladaGeometry.getRoot().resolveReference(source);
            if (o != null)
                this.texture = new LazilyLoadedTexture(o);
        }

        return this.texture;
    }

    @Override
    protected void doDrawInterior(DrawContext dc)
    {
        GL gl = dc.getGL();

        if (!dc.isPickingMode()
            && this.textureCoordsBuffer != null
            && this.getTexture().bind(dc)) // bind initiates retrieval
        {
            this.getTexture().applyInternalTransform(dc);

            gl.glEnable(GL.GL_TEXTURE_2D);
            gl.glEnableClientState(GL.GL_TEXTURE_COORD_ARRAY);

            gl.glTexCoordPointer(TEX_COORDS_PER_TRI, GL.GL_FLOAT, 0, this.textureCoordsBuffer.rewind());

            gl.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_WRAP_S, GL.GL_CLAMP_TO_BORDER);
            gl.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_WRAP_T, GL.GL_CLAMP_TO_BORDER);
        }
        else
        {
            dc.getGL().glDisable(GL.GL_TEXTURE_2D);
            gl.glDisableClientState(GL.GL_TEXTURE_COORD_ARRAY);
        }

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
        gl.glVertexPointer(VERTS_PER_TRI, GL.GL_FLOAT, 0, vb.rewind());

        gl.glDrawArrays(GL.GL_TRIANGLES, 0, this.colladaGeometry.getCount() * VERTS_PER_TRI);
    }

    protected void doDrawInteriorVBO(DrawContext dc, int[] vboIds)
    {
        GL gl = dc.getGL();

        gl.glBindBuffer(GL.GL_ARRAY_BUFFER, vboIds[0]);

        gl.glVertexPointer(VERTS_PER_TRI, GL.GL_FLOAT, 0, 0);

        if (!dc.isPickingMode() && this.mustApplyLighting(dc) && this.normalBuffer != null)
        {
            gl.glNormalPointer(GL.GL_FLOAT, 0, this.normalBufferPosition * BufferUtil.SIZEOF_FLOAT);
        }

        gl.glDrawArrays(GL.GL_TRIANGLES, 0, this.colladaGeometry.getCount() * VERTS_PER_TRI);

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
        this.createGeometry(dc);

        if (this.mustCreateNormals(dc))
            this.createNormals();
        else
            this.normalBuffer = null;

        if (this.mustApplyTexture(dc))
            this.createTexCoords();
        else
            this.textureCoordsBuffer = null;
    }

    protected void createGeometry(DrawContext dc)
    {
        int size = this.colladaGeometry.getCount() * VERTS_PER_TRI * COORDS_PER_VERT;

        // Capture the position at which normals buffer starts (in case there are normals)
        this.normalBufferPosition = size;

        if (this.mustCreateNormals(dc))
        {
            size += (this.colladaGeometry.getCount() * VERTS_PER_TRI);
        }

        if (this.coordBuffer != null && this.coordBuffer.capacity() >= size)
            this.coordBuffer.clear();
        else
            this.coordBuffer = BufferUtil.newFloatBuffer(size);

        this.colladaGeometry.getVertices(this.coordBuffer);
    }

    @Override
    protected OGLStackHandler beginDrawing(DrawContext dc, int attrMask)
    {
        OGLStackHandler ogsh = super.beginDrawing(dc, attrMask);

        if (!dc.isPickingMode())
        {
            // Push an identity texture matrix. This prevents drawSides() from leaking GL texture matrix state. The
            // texture matrix stack is popped from OGLStackHandler.pop(), in the finally block below.
            ogsh.pushTextureIdentity(dc.getGL());
        }

        return ogsh;
    }

    protected void createTexCoords()
    {
        int size = this.colladaGeometry.getCount() * VERTS_PER_TRI * TEX_COORDS_PER_TRI;

        if (this.textureCoordsBuffer != null && this.textureCoordsBuffer.capacity() >= size)
            this.textureCoordsBuffer.clear();
        else
            this.textureCoordsBuffer = BufferUtil.newFloatBuffer(size);

        this.colladaGeometry.getTextureCoordinates(this.textureCoordsBuffer);
    }

    protected void fillVBO(DrawContext dc)
    {
        GL gl = dc.getGL();
        ShapeData shapeData = (ShapeData) getCurrentData();

        int[] vboIds = (int[]) dc.getGpuResourceCache().get(shapeData.getVboCacheKey());
        if (vboIds == null)
        {
            int size = this.coordBuffer.limit() * BufferUtil.SIZEOF_FLOAT;

            vboIds = new int[1];
            gl.glGenBuffers(vboIds.length, vboIds, 0);
            dc.getGpuResourceCache().put(shapeData.getVboCacheKey(), vboIds, GpuResourceCache.VBO_BUFFERS, size);
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
        this.coordBuffer.position(this.normalBufferPosition);
        this.normalBuffer = this.coordBuffer.slice();

        this.colladaGeometry.getNormals(this.normalBuffer);
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
