/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwindx.examples;

import com.jogamp.common.nio.Buffers;
import gov.nasa.worldwind.Exportable;
import gov.nasa.worldwind.geom.*;
import gov.nasa.worldwind.globes.Globe;
import gov.nasa.worldwind.render.*;
import gov.nasa.worldwind.terrain.Terrain;
import gov.nasa.worldwind.util.*;

import javax.media.opengl.*;
import javax.xml.stream.*;
import java.awt.*;
import java.io.IOException;
import java.nio.*;
import java.util.List;

/**
 * Displays a volume defined by a near and far grid of positions. This shape is meant to represent a radar volume, with
 * the radar having a minimum and maximum range.
 *
 * @author tag
 * @version $Id$
 */
public class RadarVolume extends AbstractShape
{
    protected List<Position> positions; // the grid positions, near grid first, followed by far grid
    protected boolean[] inclusionFlags; // flags indicating which grid positions are included (visible)
    protected int width; // the number of horizontal positions in the grid.
    protected int height; // the number of vertical positions in the grid.
    protected IntBuffer gridIndices; // OpenGL indices defining the grid triangles.
    protected IntBuffer sideIndices; // OpenGL indices defining the sides of the area between the grids.

    /**
     * This class holds globe-specific data for this shape. It's managed via the shape-data cache in {@link
     * gov.nasa.worldwind.render.AbstractShape.AbstractShapeData}.
     */
    protected static class ShapeData extends AbstractShapeData
    {
        protected FloatBuffer gridVertices;
        protected FloatBuffer gridNormals;
        protected FloatBuffer sideVertices;
        protected FloatBuffer sideNormals;
        protected FloatBuffer floor;
        protected FloatBuffer outline;

        /**
         * Construct a cache entry using the boundaries of this shape.
         *
         * @param dc    the current draw context.
         * @param shape this shape.
         */
        public ShapeData(DrawContext dc, RadarVolume shape)
        {
            super(dc, shape.minExpiryTime, shape.maxExpiryTime);
        }

        @Override
        public boolean isValid(DrawContext dc)
        {
            return super.isValid(dc) && this.gridVertices != null;// && this.normals != null;
        }

        @Override
        public boolean isExpired(DrawContext dc)
        {
            return false; // the computed data is terrain independent and therevore never expired
        }
    }

    /**
     * Constructs a radar volume.
     *
     * @param positions      the volume's positions, organized as two grids. The near grid is held in the first width x
     *                       height entries, the far grid is held in the next width x height entries. This list is
     *                       retained as-is and is not copied.
     * @param inclusionFlags flags indicating which grid positions are included in the volume. This array is retained
     *                       as-is and is not copied.
     * @param width          the horizontal dimension of the grid.
     * @param height         the vertical dimension of the grid.
     *
     * @throws java.lang.IllegalArgumentException if the positions list or inclusion flags array is null, the size of
     *                                            the inclusion flags array is less than the number of grid positions,
     *                                            the positions list is less than the specified size, or the width or
     *                                            height are less than 2.
     */
    public RadarVolume(List<Position> positions, boolean[] inclusionFlags, int width, int height)
    {
        if (positions == null || inclusionFlags == null)
        {
            String message = Logging.getMessage("nullValue.ArrayIsNull");
            Logging.logger().severe(message);
            throw new IllegalArgumentException(message);
        }

        if (width < 2)
        {
            String message = Logging.getMessage("generic.InvalidWidth", width);
            Logging.logger().severe(message);
            throw new IllegalArgumentException(message);
        }

        if (height < 2)
        {
            String message = Logging.getMessage("generic.InvalidHeight", height);
            Logging.logger().severe(message);
            throw new IllegalArgumentException(message);
        }

        if (positions.size() < width * height + 1)
        {
            String message = Logging.getMessage("generic.ListLengthInsufficient", positions.size());
            Logging.logger().severe(message);
            throw new IllegalArgumentException(message);
        }

        if (inclusionFlags.length < positions.size())
        {
            String message = Logging.getMessage("generic.ListLengthInsufficient", inclusionFlags.length);
            Logging.logger().severe(message);
            throw new IllegalArgumentException(message);
        }

        this.positions = positions;
        this.inclusionFlags = inclusionFlags;
        this.width = width;
        this.height = height;
    }

    @Override
    protected void initialize()
    {
        // Nothing unique to initialize.
    }

    @Override
    protected AbstractShapeData createCacheEntry(DrawContext dc)
    {
        return new ShapeData(dc, this);
    }

    /**
     * Returns the current shape data cache entry.
     *
     * @return the current data cache entry.
     */
    protected ShapeData getCurrent()
    {
        return (ShapeData) this.getCurrentData();
    }

    /**
     * Returns the grid positions as specified to this object's constructor.
     *
     * @return this object's grid positions.
     */
    public List<Position> getPositions()
    {
        return positions;
    }

    /**
     * Returns the inclusion flags as specified to this object's constructor.
     *
     * @return this object's inclusion flags.
     */
    public boolean[] getInclusionFlags()
    {
        return this.inclusionFlags;
    }

    /**
     * Indicates the grid width.
     *
     * @return the grid width.
     */
    public int getWidth()
    {
        return width;
    }

    /**
     * Indicates the grid height.
     *
     * @return the grid height.
     */
    public int getHeight()
    {
        return height;
    }

    @Override
    protected boolean mustApplyTexture(DrawContext dc)
    {
        return false;
    }

    @Override
    protected boolean shouldUseVBOs(DrawContext dc)
    {
        return false;
    }

    @Override
    protected boolean isOrderedRenderableValid(DrawContext dc)
    {
        ShapeData shapeData = this.getCurrent();

        return shapeData.gridVertices != null;// && shapeData.normals != null;
    }

    @Override
    protected boolean doMakeOrderedRenderable(DrawContext dc)
    {
        if (!this.intersectsFrustum(dc))
            return false;

        ShapeData shapeData = this.getCurrent();

        if (shapeData.gridVertices == null)
        {
            this.makeGridVertices(dc);
            this.makeGridIndices();
            this.makeGridNormals();
            this.makeFloor();
            this.makeSides();
        }

        return true;
    }

    @Override
    protected void prepareToDrawOutline(DrawContext dc, ShapeAttributes activeAttrs, ShapeAttributes defaultAttrs)
    {
        // Override this method to avoid applying lighting to the outline.

        if (activeAttrs == null || !activeAttrs.isDrawOutline())
            return;

        GL2 gl = dc.getGL().getGL2();

        if (!dc.isPickingMode())
        {
            Material material = activeAttrs.getOutlineMaterial();
            if (material == null)
                material = defaultAttrs.getOutlineMaterial();

            Color sc = material.getDiffuse();
            double opacity = activeAttrs.getOutlineOpacity();
            gl.glColor4ub((byte) sc.getRed(), (byte) sc.getGreen(), (byte) sc.getBlue(),
                (byte) (opacity < 1 ? (int) (opacity * 255 + 0.5) : 255));

            gl.glDisable(GL2.GL_LIGHTING);
            gl.glDisableClientState(GL2.GL_NORMAL_ARRAY);

            gl.glHint(GL.GL_LINE_SMOOTH_HINT, activeAttrs.isEnableAntialiasing() ? GL.GL_NICEST : GL.GL_DONT_CARE);
        }
    }

    @Override
    protected void doDrawOutline(DrawContext dc)
    {
        ShapeData shapeData = this.getCurrent();
        GL2 gl = dc.getGL().getGL2();

        gl.glVertexPointer(3, GL.GL_FLOAT, 0, shapeData.outline.rewind());
        gl.glDrawArrays(GL.GL_LINES, 0, shapeData.outline.limit() / 3);
    }

    @Override
    protected void doDrawInterior(DrawContext dc)
    {
        this.drawModel(dc, GL2.GL_FILL);
    }

    protected void drawModel(DrawContext dc, int displayMode)
    {
        ShapeData shapeData = this.getCurrent();
        GL2 gl = dc.getGL().getGL2();

        gl.glPolygonMode(GL2.GL_FRONT_AND_BACK, displayMode);

        // Draw the volume's floor.
        gl.glVertexPointer(3, GL.GL_FLOAT, 24, shapeData.floor.rewind());
        gl.glNormalPointer(GL.GL_FLOAT, 24, shapeData.floor.rewind());
        gl.glDrawArrays(GL.GL_TRIANGLES, 0, shapeData.floor.limit() / 6);

        // Draw the volume's near and far grids.
        gl.glVertexPointer(3, GL.GL_FLOAT, 0, shapeData.gridVertices.rewind());
        gl.glNormalPointer(GL.GL_FLOAT, 0, shapeData.gridNormals.rewind());
        gl.glDrawElements(GL.GL_TRIANGLES, this.gridIndices.limit(), GL.GL_UNSIGNED_INT, this.gridIndices.rewind());

        // Draw the volume's sides.
        gl.glVertexPointer(3, GL.GL_FLOAT, 0, shapeData.sideVertices.rewind());
        gl.glNormalPointer(GL.GL_FLOAT, 0, shapeData.sideNormals.rewind());
        gl.glDrawElements(GL.GL_TRIANGLE_STRIP, this.sideIndices.limit(), GL.GL_UNSIGNED_INT,
            this.sideIndices.rewind());
    }

    protected void showNormals(DrawContext dc)
    {
        // This method is purely diagnostic and is not used by default.

        ShapeData shapeData = this.getCurrent();

        int size = shapeData.gridVertices.limit() * 2 + shapeData.floor.limit();
        FloatBuffer lineBuffer = Buffers.newDirectFloatBuffer(size);

        for (int i = 0; i < shapeData.gridVertices.limit(); i += 3)
        {
            float xo = shapeData.gridVertices.get(i);
            float yo = shapeData.gridVertices.get(i + 1);
            float zo = shapeData.gridVertices.get(i + 2);
            lineBuffer.put(xo).put(yo).put(zo);

            double length = 1e3;
            float xn = (float) (xo + shapeData.gridNormals.get(i) * length);
            float yn = (float) (yo + shapeData.gridNormals.get(i + 1) * length);
            float zn = (float) (zo + shapeData.gridNormals.get(i + 2) * length);
            lineBuffer.put(xn).put(yn).put(zn);
        }

        for (int i = 0; i < shapeData.floor.limit(); i += 6)
        {
            float xo = shapeData.floor.get(i);
            float yo = shapeData.floor.get(i + 1);
            float zo = shapeData.floor.get(i + 2);
            lineBuffer.put(xo).put(yo).put(zo);

            double length = 1e3;
            float xn = (float) (xo + shapeData.floor.get(i + 3) * length);
            float yn = (float) (yo + shapeData.floor.get(i + 4) * length);
            float zn = (float) (zo + shapeData.floor.get(i + 5) * length);
            lineBuffer.put(xn).put(yn).put(zn);
        }

        GL2 gl = dc.getGL().getGL2();

        gl.glVertexPointer(3, GL.GL_FLOAT, 0, lineBuffer.rewind());
        gl.glDrawArrays(GL.GL_LINES, 0, lineBuffer.limit() / 3);
    }

    protected void makeGridVertices(DrawContext dc)
    {
        // The grid consists of independent triangles. A tri-strip can't be used because not all positions in the
        // input grids participate in triangle formation because they may be obstructed.

        // Get the current shape data.
        ShapeData shapeData = this.getCurrent();

        // Set the reference point to the grid's origin.
        Vec4 refPt = dc.getGlobe().computePointFromPosition(this.positions.get(0));
        shapeData.setReferencePoint(refPt);

        // Allocate the grid vertices.
        shapeData.gridVertices = Buffers.newDirectFloatBuffer(3 * this.positions.size());

        // Compute the grid vertices.
        for (Position position : this.positions)
        {
            Vec4 point = dc.getGlobe().computePointFromPosition(position).subtract3(refPt);
            shapeData.gridVertices.put((float) point.x).put((float) point.y).put((float) point.z);
        }
    }

    protected void makeGridNormals()
    {
        // The grid normals are defined by a vector from each position in the near grid to the corresponding
        // position in the far grid.

        ShapeData shapeData = this.getCurrent();
        FloatBuffer vertices = shapeData.gridVertices;

        shapeData.gridNormals = Buffers.newDirectFloatBuffer(shapeData.gridVertices.limit());
        int gridSize = this.getWidth() * this.getHeight();
        int separation = 3 * gridSize;
        for (int i = 0; i < gridSize; i++)
        {
            int k = i * 3;
            double nx = vertices.get(k + separation) - vertices.get(k);
            double ny = vertices.get(k + separation + 1) - vertices.get(k + 1);
            double nz = vertices.get(k + separation + 2) - vertices.get(k + 2);

            double length = Math.sqrt(nx * nx + ny * ny + nz * nz);
            if (length > 0)
            {
                nx /= length;
                ny /= length;
                nz /= length;
            }

            shapeData.gridNormals.put((float) nx).put((float) ny).put((float) nz);
            shapeData.gridNormals.put(k + separation, (float) nx);
            shapeData.gridNormals.put(k + separation + 1, (float) ny);
            shapeData.gridNormals.put(k + separation + 2, (float) nz);
        }
    }

    private void makeGridIndices()
    {
        // The grid indices define the independent triangles of the near and far grids.

        int maxNumIndices = 2 * (this.width - 1) * (this.height - 1) * 6;
        this.gridIndices = Buffers.newDirectIntBuffer(maxNumIndices);

        // Visit each grid cell and determine whether any of its positions are obscured. If the top and bottom
        // positions are not obscured, and either the lower left or lower right positions are not obscured, the cell
        // will be shown by either one triangle or two. One triangle is used if only one of the lower positions is
        // not obscured. Two triangles are shown if both lower positions are not obscured.

        for (int n = 0; n < 2; n++)
        {
            int base = n * this.width * this.height;

            for (int j = 0; j < this.height - 1; j++)
            {
                for (int i = 0; i < this.width - 1; i++)
                {
                    int k = base + j * this.width + i;
                    boolean ll = this.inclusionFlags[k];
                    boolean lr = this.inclusionFlags[k + 1];
                    boolean ul = this.inclusionFlags[k + this.width];
                    boolean ur = this.inclusionFlags[k + this.width + 1];

                    if (ul && ur)
                    {
                        if (ll && lr)
                        {
                            // Show both triangles.
                            this.gridIndices.put(k).put(k + 1 + this.width).put(k + 1);
                            this.gridIndices.put(k).put(k + this.width).put(k + 1 + this.width);
                        }
                        else if (ll)
                        {
                            // Show the left triangle.
                            this.gridIndices.put(k).put(k + this.width).put(k + 1 + this.width);
                        }
                        else if (lr)
                        {
                            // Show the right triangle.
                            this.gridIndices.put(k + 1).put(k + this.width).put(k + 1 + this.width);
                        }
                    }
                }
            }
        }
        this.gridIndices.flip(); // capture the currently used buffer size as the limit.
    }

    protected void makeFloor()
    {
        // The floor consists of independent triangles between the visible portions of the near and far grids. The
        // algorithm for determining their vertices is similar to that for determining the grid indices: visit each
        // cell in the far grid and determine which cell positions are not obscured. When either of both of the
        // lower left or lower right positions are not obscured, compute the two floor triangles between the far grid
        // and the near grid.

        ShapeData shapeData = this.getCurrent();

        int floorSize = 18 * 2 * (this.width - 1); // 18 floats per triangle, 2(w - 1) triangles in the floor
        shapeData.floor = Buffers.newDirectFloatBuffer(floorSize);
        FloatBuffer vertices = shapeData.gridVertices;

        // This method is responsible for making the outline too.
        shapeData.outline = Buffers.newDirectFloatBuffer(6 * (this.width - 1));

        // Keep track of which columns have their floor computed.
        boolean[] floorFlags = new boolean[this.width - 1];
        for (int i = 0; i < floorFlags.length; i++)
        {
            floorFlags[i] = false;
        }

        int gridSize = this.width * this.height;
        float[] x = new float[6];
        float[] y = new float[6];
        float[] z = new float[6];

        for (int j = 0; j < this.height - 1; j++)
        {
            for (int i = 0; i < this.width - 1; i++)
            {
                int k = gridSize + j * this.width + i;
                boolean ll = this.inclusionFlags[k];
                boolean lr = this.inclusionFlags[k + 1];
                boolean ul = this.inclusionFlags[k + this.width];
                boolean ur = this.inclusionFlags[k + this.width + 1];

                if (ul && ur && !floorFlags[i])
                {
                    if (ll && lr)
                    {
                        // First triangle.
                        x[0] = vertices.get(3 * k);
                        y[0] = vertices.get(3 * k + 1);
                        z[0] = vertices.get(3 * k + 2);

                        x[1] = vertices.get(3 * (k + 1));
                        y[1] = vertices.get(3 * (k + 1) + 1);
                        z[1] = vertices.get(3 * (k + 1) + 2);

                        x[2] = vertices.get(3 * (k - gridSize));
                        y[2] = vertices.get(3 * (k - gridSize) + 1);
                        z[2] = vertices.get(3 * (k - gridSize) + 2);

                        // Second triangle
                        x[3] = vertices.get(3 * (k + 1));
                        y[3] = vertices.get(3 * (k + 1) + 1);
                        z[3] = vertices.get(3 * (k + 1) + 2);

                        x[4] = vertices.get(3 * (k + 1 - gridSize));
                        y[4] = vertices.get(3 * (k + 1 - gridSize) + 1);
                        z[4] = vertices.get(3 * (k + 1 - gridSize) + 2);

                        x[5] = vertices.get(3 * (k - gridSize));
                        y[5] = vertices.get(3 * (k - gridSize) + 1);
                        z[5] = vertices.get(3 * (k - gridSize) + 2);
                    }
                    else if (ll)
                    {
                        x[0] = vertices.get(3 * k);
                        y[0] = vertices.get(3 * k + 1);
                        z[0] = vertices.get(3 * k + 2);

                        x[1] = vertices.get(3 * (k + this.width + 1));
                        y[1] = vertices.get(3 * (k + this.width + 1) + 1);
                        z[1] = vertices.get(3 * (k + this.width + 1) + 2);

                        x[2] = vertices.get(3 * (k - gridSize));
                        y[2] = vertices.get(3 * (k - gridSize) + 1);
                        z[2] = vertices.get(3 * (k - gridSize) + 2);

                        x[3] = vertices.get(3 * (k + this.width + 1));
                        y[3] = vertices.get(3 * (k + this.width + 1) + 1);
                        z[3] = vertices.get(3 * (k + this.width + 1) + 2);

                        x[4] = vertices.get(3 * (k + this.width + 1 - gridSize));
                        y[4] = vertices.get(3 * (k + this.width + 1 - gridSize) + 1);
                        z[4] = vertices.get(3 * (k + this.width + 1 - gridSize) + 2);

                        x[5] = vertices.get(3 * (k - gridSize));
                        y[5] = vertices.get(3 * (k - gridSize) + 1);
                        z[5] = vertices.get(3 * (k - gridSize) + 2);
                    }
                    else if (lr)
                    {
                        x[0] = vertices.get(3 * (k + this.width));
                        y[0] = vertices.get(3 * (k + this.width) + 1);
                        z[0] = vertices.get(3 * (k + this.width) + 2);

                        x[1] = vertices.get(3 * (k + 1));
                        y[1] = vertices.get(3 * (k + 1) + 1);
                        z[1] = vertices.get(3 * (k + 1) + 2);

                        x[2] = vertices.get(3 * (k + this.width - gridSize));
                        y[2] = vertices.get(3 * (k + this.width - gridSize) + 1);
                        z[2] = vertices.get(3 * (k + this.width - gridSize) + 2);

                        x[3] = vertices.get(3 * (k + 1));
                        y[3] = vertices.get(3 * (k + 1) + 1);
                        z[3] = vertices.get(3 * (k + 1) + 2);

                        x[4] = vertices.get(3 * (k + 1 - gridSize));
                        y[4] = vertices.get(3 * (k + 1 - gridSize) + 1);
                        z[4] = vertices.get(3 * (k + 1 - gridSize) + 2);

                        x[5] = vertices.get(3 * (k + this.width - gridSize));
                        y[5] = vertices.get(3 * (k + this.width - gridSize) + 1);
                        z[5] = vertices.get(3 * (k + this.width - gridSize) + 2);
                    }
                    else
                    {
                        continue;
                    }

                    floorFlags[i] = true; // mark that this column's floor has been computed

                    // Compute the normal for the first floor triangle of this column.
                    double ux = x[1] - x[0];
                    double uy = y[1] - y[0];
                    double uz = z[1] - z[0];

                    double vx = x[2] - x[0];
                    double vy = y[2] - y[0];
                    double vz = z[2] - z[0];

                    double nx = uy * vz - uz * vy;
                    double ny = uz * vx - ux * vz;
                    double nz = ux * vy - uy * vx;
                    double length = Math.sqrt(nx * nx + ny * ny + nz * nz);
                    if (length > 0)
                    {
                        nx /= length;
                        ny /= length;
                        nz /= length;
                    }

                    // Interleave the vertex coordinates with the normal coordinates.
                    shapeData.floor.put(x[0]).put(y[0]).put(z[0]);
                    shapeData.floor.put((float) nx).put((float) ny).put((float) nz);
                    shapeData.floor.put(x[1]).put(y[1]).put(z[1]);
                    shapeData.floor.put((float) nx).put((float) ny).put((float) nz);
                    shapeData.floor.put(x[2]).put(y[2]).put(z[2]);
                    shapeData.floor.put((float) nx).put((float) ny).put((float) nz);

                    // Compute the normal for the second floor triangle of this column.
                    ux = x[4] - x[3];
                    uy = y[4] - y[3];
                    uz = z[4] - z[3];

                    vx = x[5] - x[3];
                    vy = y[5] - y[3];
                    vz = z[5] - z[3];

                    nx = uy * vz - uz * vy;
                    ny = uz * vx - ux * vz;
                    nz = ux * vy - uy * vx;
                    length = Math.sqrt(nx * nx + ny * ny + nz * nz);
                    if (length > 0)
                    {
                        nx /= length;
                        ny /= length;
                        nz /= length;
                    }

                    shapeData.floor.put(x[3]).put(y[3]).put(z[3]);
                    shapeData.floor.put((float) nx).put((float) ny).put((float) nz);
                    shapeData.floor.put(x[4]).put(y[4]).put(z[4]);
                    shapeData.floor.put((float) nx).put((float) ny).put((float) nz);
                    shapeData.floor.put(x[5]).put(y[5]).put(z[5]);
                    shapeData.floor.put((float) nx).put((float) ny).put((float) nz);

                    // Capture the outline vertices.
                    shapeData.outline.put(x[0]).put(y[0]).put(z[0]);
                    shapeData.outline.put(x[1]).put(y[1]).put(z[1]);

                    // Once all the floor segments have been computed we're done.
                    if (shapeData.floor.position() == shapeData.floor.limit())
                    {
                        shapeData.floor.flip();
                        shapeData.outline.flip();
                        return;
                    }
                }
            }
        }
    }

    protected void makeSides()
    {
        // The sides consist of a single triangle strip going around the left, top and right sides of the volume.
        // Obscured positions on the sides are skipped.

        ShapeData shapeData = this.getCurrent();

        int numSideVertices = 2 * (2 * this.getHeight() + this.getWidth() - 2);

        shapeData.sideVertices = Buffers.newDirectFloatBuffer(3 * numSideVertices);
        int gridSize = this.getWidth() * this.getHeight();

        // Left side vertices.
        for (int i = 0; i < this.getHeight(); i++)
        {
            int k = gridSize + i * this.getWidth();
            if (this.inclusionFlags[k])
            {
                shapeData.sideVertices.put(shapeData.gridVertices.get(3 * k));
                shapeData.sideVertices.put(shapeData.gridVertices.get(3 * k + 1));
                shapeData.sideVertices.put(shapeData.gridVertices.get(3 * k + 2));

                k -= gridSize;
                shapeData.sideVertices.put(shapeData.gridVertices.get(3 * k));
                shapeData.sideVertices.put(shapeData.gridVertices.get(3 * k + 1));
                shapeData.sideVertices.put(shapeData.gridVertices.get(3 * k + 2));
            }
        }

        // Top vertices.
        for (int i = 1; i < this.getWidth(); i++)
        {
            int k = 2 * gridSize - this.getWidth() + i;
            if (this.inclusionFlags[k])
            {
                shapeData.sideVertices.put(shapeData.gridVertices.get(3 * k));
                shapeData.sideVertices.put(shapeData.gridVertices.get(3 * k + 1));
                shapeData.sideVertices.put(shapeData.gridVertices.get(3 * k + 2));

                k -= gridSize;
                shapeData.sideVertices.put(shapeData.gridVertices.get(3 * k));
                shapeData.sideVertices.put(shapeData.gridVertices.get(3 * k + 1));
                shapeData.sideVertices.put(shapeData.gridVertices.get(3 * k + 2));
            }
        }

        // Right side vertices.
        for (int i = 1; i < this.getHeight(); i++)
        {
            int k = 2 * gridSize - 1 - i * this.getWidth();
            if (this.inclusionFlags[k])
            {
                shapeData.sideVertices.put(shapeData.gridVertices.get(3 * k));
                shapeData.sideVertices.put(shapeData.gridVertices.get(3 * k + 1));
                shapeData.sideVertices.put(shapeData.gridVertices.get(3 * k + 2));

                k -= gridSize;
                shapeData.sideVertices.put(shapeData.gridVertices.get(3 * k));
                shapeData.sideVertices.put(shapeData.gridVertices.get(3 * k + 1));
                shapeData.sideVertices.put(shapeData.gridVertices.get(3 * k + 2));
            }
        }

        shapeData.sideVertices.flip();

        // Create the side indices.
        this.sideIndices = Buffers.newDirectIntBuffer(shapeData.sideVertices.limit() / 3);
        for (int i = 0; i < this.sideIndices.limit(); i++)
        {
            this.sideIndices.put(i);
        }

        // Allocate and zero a buffer for the side normals then generate the side normals.
        shapeData.sideNormals = Buffers.newDirectFloatBuffer(shapeData.sideVertices.limit());
        while (shapeData.sideNormals.position() < shapeData.sideNormals.limit())
        {
            shapeData.sideNormals.put(0);
        }
        WWUtil.generateTriStripNormals(shapeData.sideVertices, this.sideIndices, shapeData.sideNormals);
    }

    @Override
    protected void fillVBO(DrawContext dc)
    {
        // Not using VBOs.
    }

    public Extent getExtent(Globe globe, double verticalExaggeration)
    {
        // See if we've cached an extent associated with the globe.
        Extent extent = super.getExtent(globe, verticalExaggeration);
        if (extent != null)
            return extent;

        this.getCurrent().setExtent(super.computeExtentFromPositions(globe, verticalExaggeration, this.positions));

        return this.getCurrent().getExtent();
    }

    @Override
    public Sector getSector()
    {
        if (this.sector != null)
            return this.sector;

        this.sector = Sector.boundingSector(this.positions);

        return this.sector;
    }

    @Override
    public Position getReferencePosition()
    {
        return this.positions.get(0);
    }

    @Override
    public void moveTo(Position position)
    {
        // Not supported
    }

    @Override
    public List<Intersection> intersect(Line line, Terrain terrain) throws InterruptedException
    {
        return null;
    }

    @Override
    public String isExportFormatSupported(String mimeType)
    {
        return Exportable.FORMAT_NOT_SUPPORTED;
    }

    @Override
    protected void doExportAsKML(XMLStreamWriter xmlWriter) throws IOException, XMLStreamException
    {
        throw new UnsupportedOperationException("KML output not supported for AntennaModel");
    }
}
