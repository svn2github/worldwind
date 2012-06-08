/*
 * Copyright (C) 2012 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.ogc.collada.impl;

import com.sun.opengl.util.BufferUtil;
import gov.nasa.worldwind.cache.GpuResourceCache;
import gov.nasa.worldwind.geom.*;
import gov.nasa.worldwind.geom.Box;
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
 * @author pabercrombie
 * @version $Id$
 */
// TODO extent computation does not handle nodes that are rendered multiple times with different transforms
// TODO use drawElements instead of drawArrays
public class ColladaTriangleMesh extends AbstractGeneralShape
{
    /**
     * Class to represent an instance of the mesh to be drawn as an ordered renderable. We can't use the mesh itself as
     * the ordered renderable because it may be drawn multiple times with different transforms.
     */
    public static class ColladaOrderedRenderable implements OrderedRenderable
    {
        protected ColladaTriangleMesh mesh;
        protected double eyeDistance;
        protected Matrix renderMatrix;

        public ColladaOrderedRenderable(ColladaTriangleMesh mesh, Matrix renderMatrix, double eyeDistance)
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
        protected Vec4 referenceCenter;
    }

    /** Geometry and attributes of a COLLADA Triangles element. */
    protected static class Geometry
    {
        protected ColladaTriangles colladaGeometry;

        /** Offset (in vertices) into the coord, normal, and texcoord buffers of this coordinates for this geometry. */
        protected int offset = -1;

        /** Texture applied to this geometry. */
        protected WWTexture texture;
        /** Material applied to this geometry. */
        protected Material material;

        public Geometry(ColladaTriangles triangles)
        {
            this.colladaGeometry = triangles;
        }
    }

    protected static final int VERTS_PER_TRI = 3;
    protected static final int TEX_COORDS_PER_TRI = 2;
    protected static final int COORDS_PER_VERT = 3;

    /** Total number of triangles in this mesh. Equal to the sum of the triangles in each geometry. */
    protected int triCount;

    /**
     * The vertex data buffer for this shape data. The first half contains vertex coordinates, the second half contains
     * normals.
     */
    protected ColladaBindMaterial bindMaterial;

    protected List<Geometry> geometries;

    /** Vertex coordinates for all geometries in this shape. */
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
     * @param geometries COLLADA elements that defines geometry for this shape.
     */
    public ColladaTriangleMesh(List<ColladaTriangles> geometries, ColladaBindMaterial bindMaterial)
    {
        if (WWUtil.isEmpty(geometries))
        {
            String message = Logging.getMessage("generic.ListIsEmpty");
            Logging.logger().severe(message);
            throw new IllegalStateException(message);
        }

        this.geometries = new ArrayList<Geometry>(geometries.size());
        for (ColladaTriangles triangles : geometries)
        {
            this.geometries.add(new Geometry(triangles));
            this.triCount += triangles.getCount();
        }

        this.bindMaterial = bindMaterial;
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
     * {@inheritDoc} Overridden because ColladaTriangleMesh uses ColladaOrderedRenderable instead of adding itself to
     * the ordered renderable queue.
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
                ColladaTriangleMesh shape = or.mesh;
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
                ColladaTriangleMesh shape = or.mesh;
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
        return geometry.colladaGeometry.getTexCoordAccessor() != null
            && this.getTexture(geometry) != null;
    }

    protected String getTextureSource(ColladaTriangles colladaGeometry)
    {
        ColladaTechniqueCommon techniqueCommon = this.bindMaterial.getTechniqueCommon();
        if (techniqueCommon == null)
            return null;

        String materialSource = colladaGeometry.getMaterial();
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
    protected void addOrderedRenderable(DrawContext dc)
    {
        ShapeData current = (ShapeData) this.getCurrent();

        double eyeDistance = this.computeEyeDistance(dc);
        OrderedRenderable or = new ColladaOrderedRenderable(this, current.renderMatrix, eyeDistance);
        dc.addOrderedRenderable(or);
    }

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
                gl.glVertexPointer(VERTS_PER_TRI, GL.GL_FLOAT, 0, vb.rewind());
            }

            boolean texturesEnabled = false;
            for (Geometry geometry : this.geometries)
            {
                Material nextMaterial = geometry.material != null ? geometry.material : defaultMaterial;

                // Apply new material if necessary
                if (!nextMaterial.equals(activeMaterial))
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

                    gl.glTexCoordPointer(TEX_COORDS_PER_TRI, GL.GL_FLOAT, 0, this.textureCoordsBuffer.rewind());
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

    protected void doDrawInteriorVA(DrawContext dc, Geometry geometry)
    {
        GL gl = dc.getGL();
        if (geometry.offset == -1)
            return;

        if (!dc.isPickingMode() && this.mustApplyLighting(dc) && this.normalBuffer != null)
            gl.glNormalPointer(GL.GL_FLOAT, 0, this.normalBuffer.rewind());

        gl.glDrawArrays(GL.GL_TRIANGLES, geometry.offset, geometry.colladaGeometry.getCount() * VERTS_PER_TRI);
    }

    protected void doDrawInteriorVBO(DrawContext dc, Geometry geometry, int[] vboIds)
    {
        GL gl = dc.getGL();
        if (geometry.offset == -1)
            return;

        try
        {
            gl.glBindBuffer(GL.GL_ARRAY_BUFFER, vboIds[0]);
            gl.glVertexPointer(VERTS_PER_TRI, GL.GL_FLOAT, 0, 0);

            if (!dc.isPickingMode() && this.mustApplyLighting(dc) && this.normalBuffer != null)
            {
                gl.glNormalPointer(GL.GL_FLOAT, 0, this.normalBufferPosition * BufferUtil.SIZEOF_FLOAT);
            }

            gl.glDrawArrays(GL.GL_TRIANGLES, geometry.offset, geometry.colladaGeometry.getCount() * VERTS_PER_TRI);
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
        int size = this.triCount * VERTS_PER_TRI * COORDS_PER_VERT;

        // Capture the position at which normals buffer starts (in case there are normals)
        this.normalBufferPosition = size;

        if (this.mustCreateNormals(dc))
        {
            size += (this.triCount * VERTS_PER_TRI * COORDS_PER_VERT);
        }

        if (this.coordBuffer != null && this.coordBuffer.capacity() >= size)
            this.coordBuffer.clear();
        else
            this.coordBuffer = BufferUtil.newFloatBuffer(size);

        for (Geometry geometry : this.geometries)
        {
            geometry.offset = this.coordBuffer.position() / VERTS_PER_TRI;
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
        box = Box.computeBoundingBox(new BufferWrapper.FloatBufferWrapper(this.coordBuffer), COORDS_PER_VERT);

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
            geometry.colladaGeometry.getNormals(this.normalBuffer);
        }
    }

    protected void createTexCoords()
    {
        int size = this.triCount * VERTS_PER_TRI * TEX_COORDS_PER_TRI;

        if (this.textureCoordsBuffer != null && this.textureCoordsBuffer.capacity() >= size)
            this.textureCoordsBuffer.clear();
        else
            this.textureCoordsBuffer = BufferUtil.newFloatBuffer(size);

        for (Geometry geometry : this.geometries)
        {
            if (this.mustApplyTexture(geometry))
            {
                geometry.colladaGeometry.getTextureCoordinates(this.textureCoordsBuffer);
            }
            else
            {
                int thisSize = geometry.colladaGeometry.getCount() * VERTS_PER_TRI * TEX_COORDS_PER_TRI;
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
     *
     * @throws IllegalArgumentException if draw context is null or the referencePoint is null
     */
    protected Matrix computeRenderMatrix(DrawContext dc)
    {
        ShapeData current = (ShapeData) this.getCurrent();

        // TODO cache some of these computations
        current.referenceCenter = this.computeReferenceCenter(dc);
        Position refPosition = dc.getGlobe().computePositionFromPoint(current.referenceCenter);

        Matrix matrix = dc.getGlobe().computeSurfaceOrientationAtPosition(refPosition);

        if (this.heading != null)
            matrix = matrix.multiply(Matrix.fromRotationZ(Angle.POS360.subtract(this.heading)));

        if (this.pitch != null)
            matrix = matrix.multiply(Matrix.fromRotationX(this.pitch));

        if (this.roll != null)
            matrix = matrix.multiply(Matrix.fromRotationY(this.roll));

        return matrix.multiply(current.renderMatrix);
    }

    protected Material getMaterial(Geometry geometry)
    {
        ColladaTechniqueCommon techniqueCommon = this.bindMaterial.getTechniqueCommon();
        if (techniqueCommon == null)
            return DEFAULT_INTERIOR_MATERIAL;

        String materialSource = geometry.colladaGeometry.getMaterial();
        if (materialSource == null)
            return DEFAULT_INTERIOR_MATERIAL;

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
}
