/*
 * Copyright (C) 2012 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.ogc.collada.impl;

import com.sun.opengl.util.BufferUtil;
import gov.nasa.worldwind.cache.GpuResourceCache;
import gov.nasa.worldwind.geom.Box;
import gov.nasa.worldwind.geom.*;
import gov.nasa.worldwind.ogc.collada.*;
import gov.nasa.worldwind.pick.PickSupport;
import gov.nasa.worldwind.render.*;
import gov.nasa.worldwind.terrain.Terrain;
import gov.nasa.worldwind.util.*;

import javax.media.opengl.GL;
import java.awt.*;
import java.nio.FloatBuffer;
import java.util.*;
import java.util.List;

/**
 * Shape to render a COLLADA line or triangle mesh. An instance of this shape can render any number of {@link
 * ColladaLines} or {@link ColladaTriangles}, but a single instance cannot render both lines and triangles. New
 * instances are created by {@link #createTriangleMesh(java.util.List, gov.nasa.worldwind.ogc.collada.ColladaBindMaterial)
 * createTriangleMesh} and {@link #createLineMesh(java.util.List, gov.nasa.worldwind.ogc.collada.ColladaBindMaterial)
 * createLineMesh}.
 *
 * @author pabercrombie
 * @version $Id$
 */
// TODO extent computation does not handle nodes that are rendered multiple times with different transforms
// TODO use drawElements instead of drawArrays
public class ColladaMeshShape extends AbstractGeneralShape
{
    /**
     * Class to represent an instance of the mesh to be drawn as an ordered renderable. We can't use the mesh itself as
     * the ordered renderable because it may be drawn multiple times with different transforms.
     */
    public static class ColladaOrderedRenderable implements OrderedRenderable
    {
        /** Shape to render. */
        protected ColladaMeshShape mesh;
        /** Distance from the eye to the shape's reference position. */
        protected double eyeDistance;
        /** Transform applied to this instance of the mesh. */
        protected Matrix renderMatrix;

        public ColladaOrderedRenderable(ColladaMeshShape mesh, Matrix renderMatrix, double eyeDistance)
        {
            this.mesh = mesh;
            this.eyeDistance = eyeDistance;
            this.renderMatrix = renderMatrix;
        }

        public double getDistanceFromEye()
        {
            return this.eyeDistance;
        }

        public void pick(DrawContext dc, Point pickPoint)
        {
            this.mesh.pick(dc, pickPoint, this.renderMatrix);
        }

        public void render(DrawContext dc)
        {
            this.mesh.render(dc, this.renderMatrix);
        }
    }

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
        /**
         * Matrix to orient the shape on the surface of the globe. Cached result of {@link
         * gov.nasa.worldwind.globes.Globe#computeSurfaceOrientationAtPosition(gov.nasa.worldwind.geom.Position)}
         * evaluated at the reference position.
         */
        protected Matrix surfaceOrientationMatrix;
        protected Vec4 referenceCenter;
    }

    /** Geometry and attributes of a COLLADA {@code triangles} or {@code lines} element. */
    protected static class Geometry
    {
        protected ColladaAbstractGeometry colladaGeometry;

        /** Offset (in vertices) into the coord, normal, and texcoord buffers of this coordinates for this geometry. */
        protected int offset = -1;

        /** Texture applied to this geometry. */
        protected WWTexture texture;
        /** Material applied to this geometry. */
        protected Material material;

        public Geometry(ColladaAbstractGeometry geometry)
        {
            this.colladaGeometry = geometry;
        }
    }

    /** OpenGL element type for this shape (GL.GL_LINES or GL.GL_TRIANGLES). */
    protected int elementType;
    /** Number of vertices per shape. Two in the case of a line mesh, three in the case of a triangle mesh. */
    protected int vertsPerShape;

    /** Total number of shapes (lines or triangles) in this mesh. Equal to the sum of the shapes in each geometry. */
    protected int shapeCount;

    /** Material applied to this mesh. */
    protected ColladaBindMaterial bindMaterial;

    /** Geometry objects that describe different parts of the mesh. */
    protected List<Geometry> geometries;

    /**
     * The vertex data buffer for this shape data. The first half contains vertex coordinates, the second half contains
     * normals.
     */
    protected FloatBuffer coordBuffer;
    /** The slice of the <code>coordBuffer</code> that contains normals. */
    protected FloatBuffer normalBuffer;
    /** The index of the first normal in the <code>coordBuffer</code>. */
    protected int normalBufferPosition;
    /** Texture coordinates for all geometries in this shape. */
    protected FloatBuffer textureCoordsBuffer;

    protected OGLStackHandler oglStackHandler = new OGLStackHandler();

    /**
     * Create a triangle mesh shape.
     *
     * @param geometries   COLLADA elements that defines geometry for this shape. Must contain at least one element.
     * @param bindMaterial Material applied to the mesh. May be null.
     */
    public static ColladaMeshShape createTriangleMesh(List<ColladaTriangles> geometries,
        ColladaBindMaterial bindMaterial)
    {
        ColladaMeshShape shape = new ColladaMeshShape(geometries);

        shape.bindMaterial = bindMaterial;
        shape.elementType = GL.GL_TRIANGLES;
        shape.vertsPerShape = 3;

        return shape;
    }

    /**
     * Create a line mesh shape.
     *
     * @param geometries   COLLADA elements that defines geometry for this shape. Must contain at least one element.
     * @param bindMaterial Material applied to the mesh. May be null.
     */
    public static ColladaMeshShape createLineMesh(List<ColladaLines> geometries,
        ColladaBindMaterial bindMaterial)
    {
        ColladaMeshShape shape = new ColladaMeshShape(geometries);

        shape.bindMaterial = bindMaterial;
        shape.elementType = GL.GL_LINES;
        shape.vertsPerShape = 2;

        return shape;
    }

    /**
     * Create an instance of the shape.
     *
     * @param geometries Geometries to render. All geometries must be of the same type (either {@link ColladaTriangles}
     *                   or {@link ColladaLines}.
     */
    protected ColladaMeshShape(List<? extends ColladaAbstractGeometry> geometries)
    {
        if (WWUtil.isEmpty(geometries))
        {
            String message = Logging.getMessage("generic.ListIsEmpty");
            Logging.logger().severe(message);
            throw new IllegalStateException(message);
        }

        this.geometries = new ArrayList<Geometry>(geometries.size());
        for (ColladaAbstractGeometry geometry : geometries)
        {
            this.geometries.add(new Geometry(geometry));
            this.shapeCount += geometry.getCount();
        }
    }

    @Override
    public List<Intersection> intersect(Line line, Terrain terrain) throws InterruptedException
    {
        return null; // TODO
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

    /**
     * Render the mesh in a given orientation.
     *
     * @param dc     Current draw context.
     * @param matrix Matrix to be multiply with the current modelview matrix to orient the mesh.
     */
    public void render(DrawContext dc, Matrix matrix)
    {
        this.currentData = (AbstractShapeData) this.shapeDataCache.getEntry(dc.getGlobe());
        if (this.currentData == null)
        {
            this.currentData = this.createCacheEntry(dc);
            this.shapeDataCache.addEntry(this.currentData);
        }

        ShapeData current = (ShapeData) this.currentData;
        current.renderMatrix = matrix;

        this.render(dc);
    }

    public void pick(DrawContext dc, Point pickPoint, Matrix matrix)
    {
        // This method is called only when ordered renderables are being drawn.

        if (dc == null)
        {
            String msg = Logging.getMessage("nullValue.DrawContextIsNull");
            Logging.logger().severe(msg);
            throw new IllegalArgumentException(msg);
        }

        this.pickSupport.clearPickList();
        try
        {
            this.pickSupport.beginPicking(dc);
            this.render(dc, matrix);
        }
        finally
        {
            this.pickSupport.endPicking(dc);
            this.pickSupport.resolvePick(dc, pickPoint, this.pickLayer);
        }
    }

    /**
     * {@inheritDoc} Overridden because ColladaMeshShape uses ColladaOrderedRenderable instead of adding itself to the
     * ordered renderable queue.
     */
    @Override
    protected void drawBatched(DrawContext dc)
    {
        // Draw as many as we can in a batch to save ogl state switching.
        Object nextItem = dc.peekOrderedRenderables();

        if (!dc.isPickingMode())
        {
            while (nextItem != null && nextItem.getClass() == ColladaOrderedRenderable.class)
            {
                ColladaOrderedRenderable or = (ColladaOrderedRenderable) nextItem;
                ColladaMeshShape shape = or.mesh;
                if (!shape.isEnableBatchRendering())
                    break;

                dc.pollOrderedRenderables(); // take it off the queue
                shape.doDrawOrderedRenderable(dc, this.pickSupport, or.renderMatrix);

                nextItem = dc.peekOrderedRenderables();
            }
        }
        else if (this.isEnableBatchPicking())
        {
            super.drawBatched(dc);
            while (nextItem != null && nextItem.getClass() == this.getClass())
            {
                ColladaOrderedRenderable or = (ColladaOrderedRenderable) nextItem;
                ColladaMeshShape shape = or.mesh;
                if (!shape.isEnableBatchRendering() || !shape.isEnableBatchPicking())
                    break;

                if (shape.pickLayer != this.pickLayer) // batch pick only within a single layer
                    break;

                dc.pollOrderedRenderables(); // take it off the queue
                shape.doDrawOrderedRenderable(dc, this.pickSupport, or.renderMatrix);

                nextItem = dc.peekOrderedRenderables();
            }
        }
    }

    @Override
    protected boolean mustApplyTexture(DrawContext dc)
    {
        for (Geometry geometry : this.geometries)
        {
            if (this.mustApplyTexture(geometry))
                return true;
        }
        return false;
    }

    protected boolean mustApplyTexture(Geometry geometry)
    {
        String semantic = this.getTexCoordSemantic(geometry);
        return geometry.colladaGeometry.getTexCoordAccessor(semantic) != null
            && this.getTexture(geometry) != null;
    }

    /**
     * {@inheritDoc} Overridden because this shape uses {@link ColladaOrderedRenderable} to represent this drawn
     * instance of the mesh in the ordered renderable queue.
     */
    @Override
    protected void addOrderedRenderable(DrawContext dc)
    {
        ShapeData current = (ShapeData) this.getCurrent();

        double eyeDistance = this.computeEyeDistance(dc);
        OrderedRenderable or = new ColladaOrderedRenderable(this, current.renderMatrix, eyeDistance);
        dc.addOrderedRenderable(or);
    }

    /**
     * Draw the shape as an OrderedRenderable, using the specified transform matrix.
     *
     * @param dc             Current draw context.
     * @param pickCandidates Pick candidates for this frame.
     * @param matrix         Transform matrix to apply before trying shape. m
     */
    protected void doDrawOrderedRenderable(DrawContext dc, PickSupport pickCandidates, Matrix matrix)
    {
        ShapeData current = (ShapeData) this.getCurrent();
        current.renderMatrix = matrix;

        super.doDrawOrderedRenderable(dc, pickCandidates);
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

        Vec4 refPt = this.computePoint(dc.getTerrain(), this.getModelPosition());
        if (refPt != null)
            return refPt.distanceTo3(eyePoint);

        return 0;
    }

    @Override
    protected boolean doMakeOrderedRenderable(DrawContext dc)
    {
        // Do the minimum necessary to determine the model's reference point, extent and eye distance.
        this.createMinimalGeometry(dc, (ShapeData) this.getCurrent());

        // If the shape is less that a pixel in size, don't render it.
        if (this.getCurrent().getExtent() == null || dc.isSmall(this.getExtent(), 1))
            return false;

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
    protected WWTexture getTexture(Geometry geometry)
    {
        if (geometry.texture != null)
            return geometry.texture;

        String source = this.getTextureSource(geometry.colladaGeometry);
        if (source != null)
        {
            Object o = geometry.colladaGeometry.getRoot().resolveReference(source);
            if (o != null)
                geometry.texture = new LazilyLoadedTexture(o);
        }

        return geometry.texture;
    }

    @Override
    protected void doDrawInterior(DrawContext dc)
    {
        GL gl = dc.getGL();

        try
        {
            this.oglStackHandler.pushModelview(gl);
            this.setModelViewMatrix(dc);

            Material defaultMaterial = this.activeAttributes.getInteriorMaterial();

            // Interior material is applied by super.prepareToDrawInterior. But, we may
            // need to change it if different geometry elements use different materials.
            Material activeMaterial = defaultMaterial;

            int[] vboIds = null;
            if (this.shouldUseVBOs(dc))
                vboIds = this.getVboIds(dc);

            if (vboIds == null)
            {
                FloatBuffer vb = this.coordBuffer;
                gl.glVertexPointer(ColladaAbstractGeometry.COORDS_PER_VERTEX, GL.GL_FLOAT, 0, vb.rewind());
            }

            boolean texturesEnabled = false;
            for (Geometry geometry : this.geometries)
            {
                Material nextMaterial = geometry.material != null ? geometry.material : defaultMaterial;

                // Apply new material if necessary
                if (!dc.isPickingMode() && !nextMaterial.equals(activeMaterial))
                {
                    this.applyMaterial(dc, nextMaterial);
                    activeMaterial = nextMaterial;
                }

                if (!dc.isPickingMode()
                    && this.mustApplyTexture(geometry)
                    && this.getTexture(geometry).bind(dc)) // bind initiates retrieval
                {
                    this.getTexture(geometry).applyInternalTransform(dc);

                    if (!texturesEnabled)
                    {
                        gl.glEnable(GL.GL_TEXTURE_2D);
                        gl.glEnableClientState(GL.GL_TEXTURE_COORD_ARRAY);
                        texturesEnabled = true;
                    }

                    gl.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_WRAP_S, GL.GL_REPEAT);
                    gl.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_WRAP_T, GL.GL_REPEAT);

                    gl.glTexCoordPointer(ColladaAbstractGeometry.TEX_COORDS_PER_VERTEX, GL.GL_FLOAT, 0,
                        this.textureCoordsBuffer.rewind());
                }
                else if (texturesEnabled)
                {
                    gl.glDisable(GL.GL_TEXTURE_2D);
                    gl.glDisableClientState(GL.GL_TEXTURE_COORD_ARRAY);
                    texturesEnabled = false;
                }

                if (vboIds != null)
                    this.doDrawInteriorVBO(dc, geometry, vboIds);
                else
                    this.doDrawInteriorVA(dc, geometry);
            }
        }
        finally
        {
            this.oglStackHandler.pop(gl);
        }
    }

    /**
     * Draw one geometry in the mesh interior using vertex arrays.
     *
     * @param dc       Current draw context.
     * @param geometry Geometry to draw.
     */
    protected void doDrawInteriorVA(DrawContext dc, Geometry geometry)
    {
        GL gl = dc.getGL();
        if (geometry.offset == -1)
            return;

        if (!dc.isPickingMode() && this.mustApplyLighting(dc) && this.normalBuffer != null)
            gl.glNormalPointer(GL.GL_FLOAT, 0, this.normalBuffer.rewind());

        gl.glDrawArrays(this.elementType, geometry.offset, geometry.colladaGeometry.getCount() * this.vertsPerShape);
    }

    /**
     * Draw one geometry in the mesh interior using vertex buffer objects.
     *
     * @param dc       Current draw context.
     * @param geometry Geometry to draw.
     * @param vboIds   Array of vertex buffer identifiers. The first element of the array identifies the buffer that
     *                 contains vertex coordinates and normal vectors.
     */
    protected void doDrawInteriorVBO(DrawContext dc, Geometry geometry, int[] vboIds)
    {
        GL gl = dc.getGL();
        if (geometry.offset == -1)
            return;

        try
        {
            gl.glBindBuffer(GL.GL_ARRAY_BUFFER, vboIds[0]);
            gl.glVertexPointer(ColladaAbstractGeometry.COORDS_PER_VERTEX, GL.GL_FLOAT, 0, 0);

            if (!dc.isPickingMode() && this.mustApplyLighting(dc) && this.normalBuffer != null)
            {
                gl.glNormalPointer(GL.GL_FLOAT, 0, this.normalBufferPosition * BufferUtil.SIZEOF_FLOAT);
            }

            gl.glDrawArrays(this.elementType, geometry.offset,
                geometry.colladaGeometry.getCount() * this.vertsPerShape);
        }
        finally
        {
            gl.glBindBuffer(GL.GL_ARRAY_BUFFER, 0);
        }
    }

    protected void applyMaterial(DrawContext dc, Material material)
    {
        GL gl = dc.getGL();
        ShapeAttributes activeAttrs = this.getActiveAttributes();
        double opacity = activeAttrs.getInteriorOpacity();

        // We don't need to enable or disable lighting; that's handled by super.prepareToDrawInterior.
        if (this.mustApplyLighting(dc, activeAttrs))
        {
            material.apply(gl, GL.GL_FRONT_AND_BACK, (float) opacity);
        }
        else
        {
            Color sc = material.getDiffuse();
            gl.glColor4ub((byte) sc.getRed(), (byte) sc.getGreen(), (byte) sc.getBlue(),
                (byte) (opacity < 1 ? (int) (opacity * 255 + 0.5) : 255));
        }
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

        shapeData.setEyeDistance(this.computeEyeDistance(dc, shapeData));
        shapeData.setGlobeStateKey(dc.getGlobe().getGlobeStateKey(dc));
        shapeData.setVerticalExaggeration(dc.getVerticalExaggeration());

        if (this.coordBuffer == null)
            this.createGeometry(dc);

        if (shapeData.getExtent() == null)
            shapeData.setExtent(this.computeExtent(dc));
    }

    protected void createGeometry(DrawContext dc)
    {
        int size = this.shapeCount * this.vertsPerShape * ColladaAbstractGeometry.COORDS_PER_VERTEX;

        // Capture the position at which normals buffer starts (in case there are normals)
        this.normalBufferPosition = size;

        if (this.mustCreateNormals(dc))
        {
            size += (this.shapeCount * this.vertsPerShape * ColladaAbstractGeometry.COORDS_PER_VERTEX);
        }

        if (this.coordBuffer != null && this.coordBuffer.capacity() >= size)
            this.coordBuffer.clear();
        else
            this.coordBuffer = BufferUtil.newFloatBuffer(size);

        for (Geometry geometry : this.geometries)
        {
            geometry.offset = this.coordBuffer.position() / this.vertsPerShape;
            geometry.colladaGeometry.getVertices(this.coordBuffer);
        }
    }

    protected void createFullGeometry(DrawContext dc)
    {
        if (this.normalBuffer == null && this.mustCreateNormals(dc))
            this.createNormals();

        if (this.textureCoordsBuffer == null && this.mustApplyTexture(dc))
            this.createTexCoords();

        for (Geometry geometry : this.geometries)
        {
            if (geometry.material == null)
                geometry.material = this.getMaterial(geometry);
        }
    }

    protected Extent computeExtent(DrawContext dc)
    {
        Box box;
        List<Vec4> extrema = new ArrayList<Vec4>();
        Matrix matrix = this.computeRenderMatrix(dc);

        // Compute a bounding box around the vertices in this shape.
        this.coordBuffer.rewind();
        box = Box.computeBoundingBox(new BufferWrapper.FloatBufferWrapper(this.coordBuffer),
            ColladaAbstractGeometry.COORDS_PER_VERTEX);

        // Compute the corners of the bounding box and transform with the active transform matrix.
        Vec4[] corners = box.getCorners();
        for (Vec4 corner : corners)
        {
            extrema.add(corner.transformBy3(matrix));
        }

        if (extrema.isEmpty())
            return null;

        // Compute the bounding box around the transformed corners.
        box = Box.computeBoundingBox(extrema);

        Vec4 centerPoint = this.getCurrentData().getReferencePoint();

        return box != null ? box.translate(centerPoint) : null;
    }

    /** Create this shape's vertex normals. */
    protected void createNormals()
    {
        this.coordBuffer.position(this.normalBufferPosition);
        this.normalBuffer = this.coordBuffer.slice();

        for (Geometry geometry : this.geometries)
        {
            if (geometry.colladaGeometry.getNormalAccessor() != null)
            {
                geometry.colladaGeometry.getNormals(this.normalBuffer);
            }
            else
            {
                int thisSize = geometry.colladaGeometry.getCount() * this.vertsPerShape
                    * ColladaAbstractGeometry.COORDS_PER_VERTEX;
                this.normalBuffer.position(this.normalBuffer.position() + thisSize);
            }
        }
    }

    protected void createTexCoords()
    {
        int size = this.shapeCount * this.vertsPerShape * ColladaAbstractGeometry.COORDS_PER_VERTEX;

        if (this.textureCoordsBuffer != null && this.textureCoordsBuffer.capacity() >= size)
            this.textureCoordsBuffer.clear();
        else
            this.textureCoordsBuffer = BufferUtil.newFloatBuffer(size);

        for (Geometry geometry : this.geometries)
        {
            if (this.mustApplyTexture(geometry))
            {
                String semantic = this.getTexCoordSemantic(geometry);
                geometry.colladaGeometry.getTextureCoordinates(this.textureCoordsBuffer, semantic);
            }
            else
            {
                int thisSize = geometry.colladaGeometry.getCount() * this.vertsPerShape
                    * ColladaAbstractGeometry.TEX_COORDS_PER_VERTEX;
                this.textureCoordsBuffer.position(this.textureCoordsBuffer.position() + thisSize);
            }
        }
    }

    protected void fillVBO(DrawContext dc)
    {
        GL gl = dc.getGL();
        ShapeData shapeData = (ShapeData) getCurrentData();

        int[] vboIds = this.getVboIds(dc);
        if (vboIds == null)
        {
            int size = this.coordBuffer.limit() * BufferUtil.SIZEOF_FLOAT;

            vboIds = new int[1];
            gl.glGenBuffers(vboIds.length, vboIds, 0);
            dc.getGpuResourceCache().put(shapeData.getVboCacheKey(), vboIds, GpuResourceCache.VBO_BUFFERS,
                size);
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
     */
    protected Matrix computeRenderMatrix(DrawContext dc)
    {
        ShapeData current = (ShapeData) this.getCurrent();

        if (current.referenceCenter == null || current.isExpired(dc))
        {
            current.referenceCenter = this.computeReferenceCenter(dc);

            Position refPosition = dc.getGlobe().computePositionFromPoint(current.referenceCenter);
            current.surfaceOrientationMatrix = dc.getGlobe().computeSurfaceOrientationAtPosition(refPosition);
        }
        return current.surfaceOrientationMatrix.multiply(current.renderMatrix);
    }

    //////////////////////////////////////////////////////////////////////
    // Materials and textures
    //////////////////////////////////////////////////////////////////////

    /**
     * Indicates the material applied to a geometry.
     *
     * @param geometry Geometry for which to find material.
     *
     * @return Material to apply to the geometry. If the COLLADA document does not define a material, this method return
     *         a default material.
     */
    protected Material getMaterial(Geometry geometry)
    {
        ColladaInstanceMaterial myMaterialInstance = this.getInstanceMaterial(geometry);

        if (myMaterialInstance == null)
            return DEFAULT_INTERIOR_MATERIAL;

        // Attempt to resolve the instance. The material may not be immediately available.
        ColladaMaterial myMaterial = myMaterialInstance.get();
        if (myMaterial == null)
            return DEFAULT_INTERIOR_MATERIAL;

        ColladaInstanceEffect myEffectInstance = myMaterial.getInstanceEffect();
        if (myEffectInstance == null)
            return DEFAULT_INTERIOR_MATERIAL;

        // Attempt to resolve effect. The effect may not be immediately available.
        ColladaEffect myEffect = myEffectInstance.get();
        if (myEffect == null)
            return DEFAULT_INTERIOR_MATERIAL;

        return myEffect.getMaterial();
    }

    /**
     * Indicates the <i>instance_material</i> element for a geometry.
     *
     * @param geometry Geometry for which to find material.
     *
     * @return Material for the specified geometry, or null if the material cannot be resolved.
     */
    protected ColladaInstanceMaterial getInstanceMaterial(Geometry geometry)
    {
        if (this.bindMaterial == null)
            return null;

        ColladaTechniqueCommon techniqueCommon = this.bindMaterial.getTechniqueCommon();
        if (techniqueCommon == null)
            return null;

        String materialSource = geometry.colladaGeometry.getMaterial();
        if (materialSource == null)
            return null;

        for (ColladaInstanceMaterial material : techniqueCommon.getMaterials())
        {
            if (materialSource.equals(material.getSymbol()))
                return material;
        }
        return null;
    }

    /**
     * Indicates the semantic that identifies texture coordinates. This may be specified for each material using a
     * <i>bind_vertex_input</i> element.
     *
     * @param geometry Geometry for which to find semantic.
     *
     * @return The semantic string that identifies the texture coordinates, or null if the geometry does not define the
     *         semantic.
     */
    protected String getTexCoordSemantic(Geometry geometry)
    {
        ColladaEffect effect = this.getEffect(geometry.colladaGeometry);
        if (effect == null)
            return null;

        ColladaTexture texture = effect.getTexture();
        if (texture == null)
            return null;

        String texcoord = texture.getTexCoord();
        if (texcoord == null)
            return null;

        ColladaInstanceMaterial instanceMaterial = this.getInstanceMaterial(geometry);
        String inputSemantic = null;

        // Search bind_vertex_input to find the semantic that identifies the texture coords.
        for (ColladaBindVertexInput bind : instanceMaterial.getBindVertexInputs())
        {
            if (texcoord.equals(bind.getSemantic()))
                inputSemantic = bind.getInputSemantic();
        }

        return inputSemantic;
    }

    /**
     * Indicates the source (file path or URL) of the texture applied to a geometry.
     *
     * @param geometry Geometry for which to find texture source.
     *
     * @return The source of the texture, or null if it cannot be resolved.
     */
    protected String getTextureSource(ColladaAbstractGeometry geometry)
    {
        ColladaTechniqueCommon techniqueCommon = this.bindMaterial.getTechniqueCommon();
        if (techniqueCommon == null)
            return null;

        String materialSource = geometry.getMaterial();
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

        ColladaTexture texture = myEffect.getTexture();
        if (texture == null)
            return null;

        String imageRef = this.getImageRef(myEffect, texture);
        if (imageRef == null)
            return null;

        // imageRef identifiers an <image> element (may be external). This element will give us the filename.
        Object o = geometry.getRoot().resolveReference(imageRef);
        if (o instanceof ColladaImage)
            return ((ColladaImage) o).getInitFrom();

        return null;
    }

    /**
     * Indicates the reference string for an image. The image reference identifies an <i>image</i> element in this, or
     * another COLLADA file. For example, "#myImage".
     *
     * @param effect  Effect that defines the texture.
     * @param texture Texture for which to find the image reference.
     *
     * @return The image reference, or null if it cannot be resolved.
     */
    protected String getImageRef(ColladaEffect effect, ColladaTexture texture)
    {
        String sid = texture.getTexture();

        ColladaNewParam param = effect.getParam(sid);
        if (param == null)
            return null;

        ColladaSampler2D sampler = param.getSampler2D();
        if (sampler == null)
            return null;

        ColladaSource source = sampler.getSource();
        if (source == null)
            return null;

        sid = source.getCharacters();
        if (sid == null)
            return null;

        param = effect.getParam(sid);
        if (param == null)
            return null;

        ColladaSurface surface = param.getSurface();
        if (surface != null)
            return surface.getInitFrom();

        return null;
    }

    /**
     * Indicates the effect applied to a geometry.
     *
     * @param geometry Geometry for which to find effect.
     *
     * @return Effect applied to the specified geometry, or null if no effect is defined, or the effect is not
     *         available.
     */
    protected ColladaEffect getEffect(ColladaAbstractGeometry geometry)
    {
        ColladaTechniqueCommon techniqueCommon = this.bindMaterial.getTechniqueCommon();
        if (techniqueCommon == null)
            return null;

        String materialSource = geometry.getMaterial();
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
        return myEffectInstance.get();
    }
}
