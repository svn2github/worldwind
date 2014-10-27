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
import java.io.IOException;
import java.nio.*;
import java.util.*;

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
    protected int width; // the number of horizontal positions in the grid.
    protected int height; // the number of vertical positions in the grir.
    protected IntBuffer[] nearGridIndices; // OpenGL indices defining the near grid triangle strips.
    protected IntBuffer[] farGridIndices; // OpenGL indices defining the far grid triangle strips.
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
     * Constructs a volume from two grids of positions.
     *
     * @param positions The grid positions, with the near grid first and followed by the far grid.
     * @param width     The number of horizontal positions in the grid.
     * @param height    The number of vertical positions in the grid.
     *
     * @throws java.lang.IllegalArgumentException if the positions list is null, the width or height is less than 2, and
     *                                            the size of the positions list is less than that indicated by the
     *                                            specified width and height.
     */
    public RadarVolume(List<Position> positions, int width, int height)
    {
        if (positions == null)
        {
            String message = Logging.getMessage("nullValue.PositionsListIsNull");
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

        this.positions = new ArrayList<Position>(positions);
        this.width = width;
        this.height = height;

        this.makeIndices();
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
            this.makeVertices(dc);

        if (shapeData.gridNormals == null)
            this.makeNormals();

        return true;
    }

    @Override
    protected void doDrawOutline(DrawContext dc)
    {
        this.drawModel(dc, GL2.GL_LINE);
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

        // Draw the volume's side vertices.
        gl.glVertexPointer(3, GL.GL_FLOAT, 0, shapeData.sideVertices.rewind());
        gl.glNormalPointer(GL.GL_FLOAT, 0, shapeData.sideNormals.rewind());
        gl.glDrawElements(GL.GL_TRIANGLE_STRIP, this.sideIndices.limit(), GL.GL_UNSIGNED_INT,
            this.sideIndices.rewind());

        // Draw the volume's near and far grids.
//        Material material = this.getActiveAttributes().getInteriorMaterial();
//        material.apply(gl, GL2.GL_FRONT_AND_BACK, 1.0f);
        gl.glVertexPointer(3, GL.GL_FLOAT, 0, shapeData.gridVertices.rewind());
        gl.glNormalPointer(GL.GL_FLOAT, 0, shapeData.gridNormals.rewind());

        for (IntBuffer strip : this.nearGridIndices)
        {
            gl.glDrawElements(GL.GL_TRIANGLE_STRIP, strip.limit(), GL.GL_UNSIGNED_INT, strip.rewind());
        }

        for (IntBuffer strip : this.farGridIndices)
        {
            gl.glDrawElements(GL.GL_TRIANGLE_STRIP, strip.limit(), GL.GL_UNSIGNED_INT, strip.rewind());
        }
    }

    protected void showNormals(DrawContext dc)
    {
        ShapeData shapeData = this.getCurrent();

        FloatBuffer lineBuffer = Buffers.newDirectFloatBuffer(shapeData.gridVertices.limit() * 2);

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

        GL2 gl = dc.getGL().getGL2();

        gl.glVertexPointer(3, GL.GL_FLOAT, 0, lineBuffer.rewind());
        gl.glDrawArrays(GL.GL_LINES, 0, lineBuffer.limit() / 3);
    }

    protected void makeVertices(DrawContext dc)
    {
        // Get the current shape data.
        ShapeData shapeData = this.getCurrent();

        // Set the reference point to the grid's origin.
        Vec4 refPt = dc.getGlobe().computePointFromPosition(this.getPositions().get(0));
        shapeData.setReferencePoint(refPt);

        // Allocate the grid vertices.
        shapeData.gridVertices = Buffers.newDirectFloatBuffer(3 * this.getPositions().size());

        // Compute the grid vertices.
        for (Position position : this.getPositions())
        {
            Vec4 point = dc.getGlobe().computeEllipsoidalPointFromPosition(position).subtract3(refPt);
            shapeData.gridVertices.put((float) point.x).put((float) point.y).put((float) point.z);
        }

        // Create the side vertices. Can't use the grid vertices buffer because side vertices must have different
        // normals than the grid vertices.
        int numSideVertices = 2 * (2 * this.getHeight() + this.getWidth() - 2);
        shapeData.sideVertices = Buffers.newDirectFloatBuffer(3 * numSideVertices);
        int gridSize = this.getWidth() * this.getHeight();

        // Left side.
        for (int i = 0; i < this.getHeight(); i++)
        {
            int k = gridSize + i * this.getWidth();
            shapeData.sideVertices.put(shapeData.gridVertices.get(3 * k));
            shapeData.sideVertices.put(shapeData.gridVertices.get(3 * k + 1));
            shapeData.sideVertices.put(shapeData.gridVertices.get(3 * k + 2));

            k -= gridSize;
            shapeData.sideVertices.put(shapeData.gridVertices.get(3 * k));
            shapeData.sideVertices.put(shapeData.gridVertices.get(3 * k + 1));
            shapeData.sideVertices.put(shapeData.gridVertices.get(3 * k + 2));
        }

        // Top
        for (int i = 1; i < this.getWidth(); i++)
        {
            int k = 2 * gridSize - this.getWidth() + i;
            shapeData.sideVertices.put(shapeData.gridVertices.get(3 * k));
            shapeData.sideVertices.put(shapeData.gridVertices.get(3 * k + 1));
            shapeData.sideVertices.put(shapeData.gridVertices.get(3 * k + 2));

            k -= gridSize;
            shapeData.sideVertices.put(shapeData.gridVertices.get(3 * k));
            shapeData.sideVertices.put(shapeData.gridVertices.get(3 * k + 1));
            shapeData.sideVertices.put(shapeData.gridVertices.get(3 * k + 2));
        }

        // Right side.
        for (int i = 1; i < this.getHeight(); i++)
        {
            int k = 2 * gridSize - 1 - i * this.getWidth();
            shapeData.sideVertices.put(shapeData.gridVertices.get(3 * k));
            shapeData.sideVertices.put(shapeData.gridVertices.get(3 * k + 1));
            shapeData.sideVertices.put(shapeData.gridVertices.get(3 * k + 2));

            k -= gridSize;
            shapeData.sideVertices.put(shapeData.gridVertices.get(3 * k));
            shapeData.sideVertices.put(shapeData.gridVertices.get(3 * k + 1));
            shapeData.sideVertices.put(shapeData.gridVertices.get(3 * k + 2));
        }
    }

    protected void makeNormals()
    {
        ShapeData shapeData = this.getCurrent();

        // Allocate a buffer for the grid normals and initialize the buffer values to 0, which is required by the
        // function that computes average normals.
        shapeData.gridNormals = Buffers.newDirectFloatBuffer(shapeData.gridVertices.limit());
        while (shapeData.gridNormals.position() < shapeData.gridNormals.limit())
        {
            shapeData.gridNormals.put(0);
        }
        shapeData.gridNormals.rewind();

        // Generate the normals for the near and far grids.

        for (IntBuffer strip : this.nearGridIndices)
        {
            WWUtil.generateTriStripNormals(shapeData.gridVertices, strip, shapeData.gridNormals);
        }

        for (IntBuffer strip : this.farGridIndices)
        {
            WWUtil.generateTriStripNormals(shapeData.gridVertices, strip, shapeData.gridNormals);
        }

        // Allocate and zero a buffer for the side vertices then generate the side normals.
        shapeData.sideNormals = Buffers.newDirectFloatBuffer(shapeData.sideVertices.limit());
        while (shapeData.sideNormals.position() < shapeData.sideNormals.limit())
        {
            shapeData.sideNormals.put(0);
        }
        shapeData.gridNormals.rewind();
        WWUtil.generateTriStripNormals(shapeData.sideVertices, this.sideIndices, shapeData.sideNormals);
    }

    /**
     * Creates the triangle strip indices for the grids and the volume's sides.
     */
    protected void makeIndices()
    {
        int numStripIndices = 2 * this.getWidth();
        this.nearGridIndices = new IntBuffer[this.getHeight() - 1];
        for (int i = 0; i < this.getHeight() - 1; i++)
        {
            this.nearGridIndices[i] = Buffers.newDirectIntBuffer(numStripIndices);

            int k = i * this.getWidth();
            for (int j = 0; j < this.getWidth(); j++)
            {
                this.nearGridIndices[i].put(k).put(k + this.getWidth());
                k += 1;
            }
        }

        int base = this.getWidth() * this.getHeight();
        this.farGridIndices = new IntBuffer[this.getHeight() - 1];
        for (int i = 0; i < this.getHeight() - 1; i++)
        {
            this.farGridIndices[i] = Buffers.newDirectIntBuffer(numStripIndices);

            int k = i * this.getWidth() + base;
            for (int j = 0; j < this.getWidth(); j++)
            {
                this.farGridIndices[i].put(k).put(k + this.getWidth());
                k += 1;
            }
        }

        int numSideVertices = 2 * (2 * this.getHeight() + this.getWidth() - 2);
        this.sideIndices = Buffers.newDirectIntBuffer(numSideVertices);
        for (int i = 0; i < this.sideIndices.limit(); i++)
        {
            this.sideIndices.put(i);
        }
    }

    @Override
    protected void fillVBO(DrawContext dc)
    {
    }

    public Extent getExtent(Globe globe, double verticalExaggeration)
    {
        // See if we've cached an extent associated with the globe.
        Extent extent = super.getExtent(globe, verticalExaggeration);
        if (extent != null)
            return extent;

        this.getCurrent().setExtent(super.computeExtentFromPositions(globe, verticalExaggeration, this.getPositions()));

        return this.getCurrent().getExtent();
    }

    @Override
    public Sector getSector()
    {
        if (this.sector != null)
            return this.sector;

        this.sector = Sector.boundingSector(this.getPositions());

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
