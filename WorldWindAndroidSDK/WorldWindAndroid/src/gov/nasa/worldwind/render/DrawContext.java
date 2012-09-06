/*
 * Copyright (C) 2012 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */
package gov.nasa.worldwind.render;

import android.graphics.Point;
import android.opengl.GLES20;
import gov.nasa.worldwind.*;
import gov.nasa.worldwind.cache.GpuResourceCache;
import gov.nasa.worldwind.geom.Sector;
import gov.nasa.worldwind.globes.Globe;
import gov.nasa.worldwind.layers.*;
import gov.nasa.worldwind.pick.*;
import gov.nasa.worldwind.terrain.SectorGeometryList;
import gov.nasa.worldwind.util.*;

import java.nio.ByteBuffer;
import java.util.Collection;

/**
 * @author dcollins
 * @version $Id$
 */
public class DrawContext extends WWObjectImpl
{
    protected static final double DEFAULT_VERTICAL_EXAGGERATION = 1;

    protected int viewportWidth;
    protected int viewportHeight;
    protected int clearColor;
    protected Model model;
    protected View view;
    protected double verticalExaggeration = DEFAULT_VERTICAL_EXAGGERATION;
    protected Sector visibleSector;
    protected GpuResourceCache gpuResourceCache;
    protected SectorGeometryList surfaceGeometry;
    protected SurfaceTileRenderer surfaceTileRenderer = new SurfaceTileRenderer();
    protected Layer currentLayer;
    protected GpuProgram currentProgram;
    protected long frameTimestamp;
    protected boolean pickingMode;
    protected boolean deepPickingMode;
    protected int uniquePickNumber;
    protected ByteBuffer pickColor = ByteBuffer.allocateDirect(4);
    protected Point pickPoint;
    protected PickedObjectList objectsAtPickPoint = new PickedObjectList();
    protected Collection<PerformanceStatistic> perFrameStatistics;

    /**
     * Initializes this <code>DrawContext</code>. This method should be called at the beginning of each frame to prepare
     * the <code>DrawContext</code> for the coming render pass.
     */
    public void initialize(int viewportWidth, int viewportHeight)
    {
        if (viewportWidth < 0)
        {
            String msg = Logging.getMessage("generic.WidthIsInvalid", viewportWidth);
            Logging.error(msg);
            throw new IllegalArgumentException(msg);
        }

        if (viewportHeight < 0)
        {
            String msg = Logging.getMessage("generic.HeightIsInvalid", viewportHeight);
            Logging.error(msg);
            throw new IllegalArgumentException(msg);
        }

        this.viewportWidth = viewportWidth;
        this.viewportHeight = viewportHeight;
        this.model = null;
        this.view = null;
        this.verticalExaggeration = DEFAULT_VERTICAL_EXAGGERATION;
        this.visibleSector = null;
        this.gpuResourceCache = null;
        this.surfaceGeometry = null;
        this.currentLayer = null;
        this.currentProgram = null;
        this.frameTimestamp = 0;
        this.pickingMode = false;
        this.deepPickingMode = false;
        this.uniquePickNumber = 0;
        this.pickPoint = null;
        this.objectsAtPickPoint.clear();
        this.perFrameStatistics = null;
    }

    public int getViewportWidth()
    {
        return this.viewportWidth;
    }

    public int getViewportHeight()
    {
        return this.viewportHeight;
    }

    /**
     * Returns the WorldWindow's background color.
     *
     * @return the WorldWindow's background color.
     */
    public int getClearColor()
    {
        return this.clearColor;
    }

    /**
     * Retrieves the current <code>Model</code>, which may be null.
     *
     * @return the current <code>Model</code>, which may be null
     */
    public Model getModel()
    {
        return this.model;
    }

    /**
     * Assign a new <code>Model</code>. Some layers cannot function properly with a null <code>Model</code>. It is
     * recommended that the <code>Model</code> is never set to null during a normal render pass.
     *
     * @param model the new <code>Model</code>
     */
    public void setModel(Model model)
    {
        this.model = model;
    }

    /**
     * Retrieves the current <code>View</code>, which may be null.
     *
     * @return the current <code>View</code>, which may be null
     */
    public View getView()
    {
        return this.view;
    }

    /**
     * Assigns a new <code>View</code>. Some layers cannot function properly with a null <code>View</code>. It is
     * recommended that the <code>View</code> is never set to null during a normal render pass.
     *
     * @param view the enw <code>View</code>
     */
    public void setView(View view)
    {
        this.view = view;
    }

    /**
     * Retrieves the current <code>Globe</code>, which may be null.
     *
     * @return the current <code>Globe</code>, which may be null
     */
    public Globe getGlobe()
    {
        return this.model != null ? this.model.getGlobe() : null;
    }

    /**
     * Retrieves a list containing all the current layers. No guarantee is made about the order of the layers.
     *
     * @return a <code>LayerList</code> containing all the current layers
     */
    public LayerList getLayers()
    {
        return this.model != null ? this.model.getLayers() : null;
    }

    /**
     * Retrieves the current vertical exaggeration. Vertical exaggeration affects the appearance of areas with varied
     * elevation. A vertical exaggeration of zero creates a surface which exactly fits the shape of the underlying
     * <code>Globe</code>. A vertical exaggeration of 3 will create mountains and valleys which are three times as
     * high/deep as they really are.
     *
     * @return the current vertical exaggeration
     */
    public double getVerticalExaggeration()
    {
        return this.verticalExaggeration;
    }

    /**
     * Sets the vertical exaggeration. Vertical exaggeration affects the appearance of areas with varied elevation. A
     * vertical exaggeration of zero creates a surface which exactly fits the shape of the underlying
     * <code>Globe</code>. A vertical exaggeration of 3 will create mountains and valleys which are three times as
     * high/deep as they really are.
     *
     * @param verticalExaggeration the new vertical exaggeration.
     */
    public void setVerticalExaggeration(double verticalExaggeration)
    {
        this.verticalExaggeration = verticalExaggeration;
    }

    /**
     * Retrieves a <code>Sector</code> which is at least as large as the current visible sector. The value returned is
     * the value passed to <code>SetVisibleSector</code>. This method may return null.
     *
     * @return a <code>Sector</code> at least the size of the current visible sector, null if unavailable
     */
    public Sector getVisibleSector()
    {
        return this.visibleSector;
    }

    /**
     * Sets the visible <code>Sector</code>. The new visible sector must completely encompass the Sector which is
     * visible on the display.
     *
     * @param sector the new visible <code>Sector</code>
     */
    public void setVisibleSector(Sector sector)
    {
        this.visibleSector = sector;
    }

    /**
     * Returns the GPU resource cache used by this draw context.
     *
     * @return the GPU resource cache used by this draw context.
     */
    public GpuResourceCache getGpuResourceCache()
    {
        return this.gpuResourceCache;
    }

    /**
     * Specifies the GPU resource cache for this draw context.
     *
     * @param gpuResourceCache the GPU resource cache for this draw context.
     */
    public void setGpuResourceCache(GpuResourceCache gpuResourceCache)
    {
        if (gpuResourceCache == null)
        {
            String msg = Logging.getMessage("nullValue.CacheIsNull");
            Logging.error(msg);
            throw new IllegalArgumentException(msg);
        }

        this.gpuResourceCache = gpuResourceCache;
    }

    /**
     * Indicates the surface geometry that is visible this frame.
     *
     * @return the visible surface geometry.
     */
    public SectorGeometryList getSurfaceGeometry()
    {
        return this.surfaceGeometry;
    }

    /**
     * Specifies the surface geometry that is visible this frame.
     *
     * @param surfaceGeometry the visible surface geometry.
     */
    public void setSurfaceGeometry(SectorGeometryList surfaceGeometry)
    {
        this.surfaceGeometry = surfaceGeometry;
    }

    /** {@inheritDoc} */
    public SurfaceTileRenderer getSurfaceTileRenderer()
    {
        return this.surfaceTileRenderer;
    }

    /**
     * Returns the current-layer. The field is informative only and enables layer contents to determine their containing
     * layer.
     *
     * @return the current layer, or null if no layer is current.
     */
    public Layer getCurrentLayer()
    {
        return this.currentLayer;
    }

    /**
     * Sets the current-layer field to the specified layer or null. The field is informative only and enables layer
     * contents to determine their containing layer.
     *
     * @param layer the current layer or null.
     */
    public void setCurrentLayer(Layer layer)
    {
        this.currentLayer = layer;
    }

    public GpuProgram getCurrentProgram()
    {
        return this.currentProgram;
    }

    public void setCurrentProgram(GpuProgram program)
    {
        this.currentProgram = program;
    }

    /**
     * Returns the time stamp corresponding to the beginning of a pre-render, pick, render sequence. The stamp remains
     * constant across these three operations so that called objects may avoid recomputing the same values during each
     * of the calls in the sequence.
     *
     * @return the frame time stamp. See {@link System#currentTimeMillis()} for its numerical meaning.
     */
    public long getFrameTimeStamp()
    {
        return this.frameTimestamp;
    }

    /**
     * Specifies the time stamp corresponding to the beginning of a pre-render, pick, render sequence. The stamp must
     * remain constant across these three operations so that called objects may avoid recomputing the same values during
     * each of the calls in the sequence.
     *
     * @param timeStamp the frame time stamp. See {@link System#currentTimeMillis()} for its numerical meaning.
     */
    public void setFrameTimeStamp(long timeStamp)
    {
        this.frameTimestamp = timeStamp;
    }

    /**
     * Indicates whether the drawing is occurring in picking picking mode. In picking mode, each unique object is drawn
     * in a unique RGB color by calling {@link #getUniquePickColor()} prior to rendering. Any OpenGL state that could
     * cause an object to draw a color other than the unique RGB pick color must be disabled. This includes
     * antialiasing, blending, and dithering.
     *
     * @return true if drawing should occur in picking mode, otherwise false.
     */
    public boolean isPickingMode()
    {
        return this.pickingMode;
    }

    /**
     * Specifies whether drawing should occur in picking mode. See {@link #isPickingMode()} for more information.
     *
     * @param tf true to specify that drawing should occur in picking mode, otherwise false.
     */
    public void setPickingMode(boolean tf)
    {
        this.pickingMode = tf;
    }

    /**
     * Indicates whether all items under the pick point are picked.
     *
     * @return true if all items under the pick point are picked, otherwise false .
     */
    public boolean isDeepPickingEnabled()
    {
        return this.deepPickingMode;
    }

    /**
     * Specifies whether all items under the pick point are picked.
     *
     * @param tf true to pick all objects under the pick point.
     */
    public void setDeepPickingEnabled(boolean tf)
    {
        this.deepPickingMode = tf;
    }

    /**
     * Returns a unique color to serve as a pick identifier during picking.
     *
     * @return a unique pick color.
     */
    public int getUniquePickColor()
    {
        this.uniquePickNumber++;

        if (this.uniquePickNumber == this.clearColor)
            this.uniquePickNumber++;

        if (this.uniquePickNumber >= 0x00FFFFFF)
        {
            this.uniquePickNumber = 1;  // no black, no white
            if (this.uniquePickNumber == this.clearColor)
                this.uniquePickNumber++;
        }

        return this.uniquePickNumber;
    }

    public int getPickColor(Point point)
    {
        if (point == null)
        {
            String msg = Logging.getMessage("nullValue.PointIsNull");
            Logging.error(msg);
            throw new IllegalArgumentException(msg);
        }

        // Read the RGBA color at the specified point as a 4-component tuple of unsigned bytes. OpenGL ES does not
        // support reading only the RGB values, so we read the RGBA value and ignore the alpha component. We convert the
        // y coordinate from Android UI coordinates to GL coordinates.
        int yInGLCoords = this.viewportHeight - point.y;
        GLES20.glReadPixels(point.x, yInGLCoords, 1, 1, GLES20.GL_RGBA, GLES20.GL_UNSIGNED_BYTE, this.pickColor);

        // GL places the value RGBA in the first 4 bytes of the buffer, in that order. We ignore the alpha component and
        // compose an integer equivalent to those returned by getUniquePickColor.
        return ((0xFF & this.pickColor.get(0)) << 16)
            | ((0xFF & this.pickColor.get(1)) << 8)
            | (0xFF & this.pickColor.get(2));
    }

    /**
     * Returns the current pick point.
     *
     * @return the current pick point, or null if no pick point is available.
     */
    public Point getPickPoint()
    {
        return pickPoint;
    }

    /**
     * Specifies the pick point.
     *
     * @param point the pick point, or null to indicate there is no pick point.
     */
    public void setPickPoint(Point point)
    {
        this.pickPoint = point;
    }

    /**
     * Returns the World Wind objects at the current pick point. The list of objects is determined while drawing in
     * picking mode, and is cleared each time this draw context is initialized.
     *
     * @return the list of currently picked objects.
     */
    public PickedObjectList getObjectsAtPickPoint()
    {
        return this.objectsAtPickPoint;
    }

    /**
     * Adds a single picked object to the current picked-object list.
     *
     * @param pickedObject the object to add.
     *
     * @throws IllegalArgumentException if the pickedObject is null.
     */
    public void addPickedObject(PickedObject pickedObject)
    {
        if (pickedObject == null)
        {
            String msg = Logging.getMessage("nullValue.PickedObject");
            Logging.error(msg);
            throw new IllegalArgumentException(msg);
        }

        this.objectsAtPickPoint.add(pickedObject);
    }

    public Collection<PerformanceStatistic> getPerFrameStatistics()
    {
        return this.perFrameStatistics;
    }

    public void setPerFrameStatistics(Collection<PerformanceStatistic> perFrameStatistics)
    {
        this.perFrameStatistics = perFrameStatistics;
    }

    public void addPerFrameStatistic(String key, String displayName, Object value)
    {
        if (this.perFrameStatistics == null)
            return;

        if (WWUtil.isEmpty(key))
        {
            String msg = Logging.getMessage("nullValue.KeyIsNull");
            Logging.error(msg);
            throw new IllegalArgumentException(msg);
        }

        if (WWUtil.isEmpty(displayName))
        {
            String msg = Logging.getMessage("nullValue.NameIsNull");
            Logging.error(msg);
            throw new IllegalArgumentException(msg);
        }

        this.perFrameStatistics.add(new PerformanceStatistic(key, displayName, value));
    }
}
