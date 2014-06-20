/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */
package gov.nasa.worldwind.formats.shapefile;

import com.jogamp.common.nio.Buffers;
import gov.nasa.worldwind.cache.*;
import gov.nasa.worldwind.geom.*;
import gov.nasa.worldwind.layers.Layer;
import gov.nasa.worldwind.pick.*;
import gov.nasa.worldwind.render.*;
import gov.nasa.worldwind.terrain.Terrain;
import gov.nasa.worldwind.util.*;

import javax.media.opengl.*;
import java.awt.*;
import java.nio.*;
import java.util.*;
import java.util.Queue;

/**
 * @author dcollins
 * @version $Id$
 */
public class ShapefileExtrudedPolygons extends ShapefileRenderable implements OrderedRenderable
{
    protected static class RecordGroup
    {
        public final ShapeAttributes attributes;
        public ArrayList<Record> records = new ArrayList<Record>();
        public IntBuffer indices;
        public Range interiorIndexRange = new Range(0, 0);
        public Range outlineIndexRange = new Range(0, 0);
        public Object vboKey = new Object();

        public RecordGroup(ShapeAttributes attributes)
        {
            this.attributes = attributes;
        }
    }

    protected static class Tile
    {
        public final Sector sector;
        public final int level;
        public ArrayList<Record> records = new ArrayList<Record>();
        public ArrayList<RecordGroup> attributeGroups = new ArrayList<RecordGroup>();
        public Tile[] children;
        public ShapeDataCache dataCache = new ShapeDataCache(60000);
        public TileData currentData;

        public Tile(Sector sector, int level)
        {
            this.sector = sector;
            this.level = level;
        }
    }

    protected static class TileData extends ShapeDataCache.ShapeDataCacheEntry
    {
        public FloatBuffer vertices;
        public Vec4 origin;
        public Matrix transformMatrix;
        public Object vboKey = new Object();
        public boolean vboExpired;

        public TileData(DrawContext dc, long minExpiryTime, long maxExpiryTime)
        {
            super(dc, minExpiryTime, maxExpiryTime);
        }
    }

    // Shapefile extruded polygon properties.
    protected double baseDepth;
    protected double defaultHeight;
    // Shapefile extruded polygon tile quadtree structures.
    protected Tile rootTile;
    protected int tileMaxLevel = 3;
    protected int tileMaxCapacity = 10000;
    // Data structures supporting polygon tessellation and drawing.
    protected ArrayList<Tile> currentTiles = new ArrayList<Tile>();
    protected PolygonTessellator tess = new PolygonTessellator();
    protected byte[] byteArray = new byte[6];
    protected float[] floatArray = new float[6];
    protected double[] doubleArray = new double[16];
    // Data structures supporting picking.
    protected Layer pickLayer;
    protected PickSupport pickSupport = new PickSupport();
    protected ByteBuffer pickColors;
    protected Object pickColorsVboKey = new Object();

    public ShapefileExtrudedPolygons(Shapefile shapefile)
    {
        super(shapefile); // superclass constructor checks shapefile argument

        if (!Shapefile.isPolygonType(shapefile.getShapeType()))
        {
            String msg = Logging.getMessage("SHP.UnsupportedShapeType", shapefile.getShapeType());
            Logging.logger().severe(msg);
            throw new IllegalArgumentException(msg);
        }

        if (this.sector != null && this.records.size() > 0) // Suppress tile creation for empty shapefiles.
        {
            this.rootTile = new Tile(this.sector, 0);
            this.rootTile.records.addAll(this.records);

            if (this.mustSplitTile(this.rootTile))
            {
                this.splitTile(this.rootTile);
            }

            this.rootTile.records.trimToSize(); // Reduce memory overhead from unused ArrayList capacity.
        }
    }

    protected boolean mustSplitTile(Tile tile)
    {
        return tile.level < this.tileMaxLevel && tile.records.size() > this.tileMaxCapacity;
    }

    protected void splitTile(Tile tile)
    {
        // Create four child tiles by subdividing the tile's sector in latitude and longitude.
        Sector[] childSectors = tile.sector.subdivide();
        tile.children = new Tile[4];
        tile.children[0] = new Tile(childSectors[0], tile.level + 1);
        tile.children[1] = new Tile(childSectors[1], tile.level + 1);
        tile.children[2] = new Tile(childSectors[2], tile.level + 1);
        tile.children[3] = new Tile(childSectors[3], tile.level + 1);

        // Move any records completely contained in a child tile's sector into the child's list of records. This may
        // include records that are marked as not visible, as recomputing the tile tree for record visibility changes
        // would be expensive.
        Iterator<ShapefileRenderable.Record> iterator = tile.records.iterator();
        while (iterator.hasNext())
        {
            ShapefileRenderable.Record record = iterator.next();
            for (int i = 0; i < 4; i++)
            {
                if (tile.children[i].sector.contains(record.sector))
                {
                    tile.children[i].records.add(record); // add it to the child
                    record.tile = tile.children[i]; // assign the record's tile
                    iterator.remove(); // remove it from the parent
                    break; // skip to the next record
                }
            }
        }

        // Recursively split child tiles as necessary, moving their records into each child's descendants. The recursive
        // split stops when a child tile reaches a maximum level, or when the number of records contained within the
        // tile is small enough.
        for (int i = 0; i < 4; i++)
        {
            if (this.mustSplitTile(tile.children[i]))
            {
                this.splitTile(tile.children[i]);
            }

            tile.children[i].records.trimToSize(); // Reduce memory overhead from unused ArrayList capacity.
        }
    }

    @Override
    protected void recordDidChange(Record record)
    {
        Tile tile = record.tile != null ? (Tile) record.tile : this.rootTile; // null indicates the root tile
        this.invalidateTileAttributeGroups(tile);
    }

    public double getBaseDepth()
    {
        return this.baseDepth;
    }

    public void setBaseDepth(double baseDepth)
    {
        this.baseDepth = baseDepth;
        this.invalidateAllTileGeometry();
    }

    public double getDefaultHeight()
    {
        return this.defaultHeight;
    }

    public void setDefaultHeight(double defaultHeight)
    {
        this.defaultHeight = defaultHeight;
        this.invalidateAllTileGeometry();
    }

    public Extent getExtent(DrawContext dc)
    {
        if (dc == null)
        {
            String msg = Logging.getMessage("nullValue.DrawContextIsNull");
            Logging.logger().severe(msg);
            throw new IllegalArgumentException(msg);
        }

        return this.rootTile != null ? this.getTileExtent(dc, this.rootTile) : null;
    }

    @Override
    public double getDistanceFromEye()
    {
        return 0;
    }

    @Override
    public void pick(DrawContext dc, Point pickPoint)
    {
        if (dc == null)
        {
            String msg = Logging.getMessage("nullValue.DrawContextIsNull");
            Logging.logger().severe(msg);
            throw new IllegalArgumentException(msg);
        }

        if (!this.visible)
            return;

        if (this.rootTile == null) // Shapefile is empty or contains only null records.
            return;

        this.pickSupport.clearPickList();
        try
        {
            this.pickSupport.beginPicking(dc);
            this.render(dc); // draw each tile's records in a single color

            // TODO: Pick rectangle support
            PickedObject po = this.pickSupport.getTopObject(dc, pickPoint); // resolve the picked tile, if any
            if (po != null)
            {
                this.pickSupport.clearPickList();
                this.beginDrawing(dc);
                this.drawTileInUniqueColors(dc, (Tile) po.getObject());
                this.endDrawing(dc);
                this.pickSupport.resolvePick(dc, pickPoint, this.pickLayer); // resolve the picked records, if any
            }
        }
        finally
        {
            this.pickSupport.endPicking(dc);
        }
    }

    @Override
    public void render(DrawContext dc)
    {
        if (dc == null)
        {
            String msg = Logging.getMessage("nullValue.DrawContextIsNull");
            Logging.logger().severe(msg);
            throw new IllegalArgumentException(msg);
        }

        if (!this.visible)
            return;

        if (this.rootTile == null) // Shapefile is empty or contains only null records.
            return;

        if (dc.isOrderedRenderingMode())
            this.drawOrderedSurfaceRenderable(dc);
        else
            this.makeOrderedSurfaceRenderable(dc);
    }

    protected void makeOrderedSurfaceRenderable(DrawContext dc)
    {
        this.assembleTiles(dc); // performs a visibility test against the top level tile

        if (this.currentTiles.isEmpty()) // don't add an ordered renderable when there's nothing to draw
        {
            return;
        }

        this.pickLayer = dc.getCurrentLayer();
        dc.addOrderedSurfaceRenderable(this);
    }

    protected void assembleTiles(DrawContext dc)
    {
        this.currentTiles.clear();
        this.addTileOrDescendants(dc, this.rootTile);
    }

    protected void addTileOrDescendants(DrawContext dc, Tile tile)
    {
        tile.currentData = (TileData) tile.dataCache.getEntry(dc.getGlobe());
        if (tile.currentData == null)
        {
            tile.currentData = new TileData(dc, 3000, 9000);
            tile.dataCache.addEntry(tile.currentData);
        }

        if (tile.records.isEmpty() || !this.isTileVisible(dc, tile))
        {
            return;
        }

        if (this.mustRegenerateTileGeometry(dc, tile))
        {
            this.regenerateTileGeometry(dc, tile);
        }

        if (this.mustAssembleTileAttributeGroups(tile))
        {
            this.assembleTileAttributeGroups(tile);
        }

        this.currentTiles.add(tile);

        if (tile.children != null)
        {
            for (Tile childTile : tile.children)
            {
                this.addTileOrDescendants(dc, childTile);
            }
        }
    }

    protected boolean isTileVisible(DrawContext dc, Tile tile)
    {
        Extent extent = this.getTileExtent(dc, tile);

        if (dc.isSmall(extent, 1))
        {
            return false;
        }

        return dc.isPickingMode() ?
            dc.getPickFrustums().intersectsAny(extent) : dc.getView().getFrustumInModelCoordinates().intersects(extent);
    }

    protected Extent getTileExtent(DrawContext dc, Tile tile)
    {
        Extent extent = tile.currentData.getExtent();

        if (extent == null) // no need to check for data expiration, a tile's extent never changes
        {
            // Compute the tile's minimum and maximum height as height above and below the extreme elevations in the
            // tile's sector. We use the overall maximum height of all records in order to ensure that the extents of
            // parent tiles enclose the extents of their descendants.
            double[] extremes = dc.getGlobe().getMinAndMaxElevations(tile.sector);
            double minHeight = extremes[0] - this.baseDepth;
            double maxHeight = extremes[1] + Math.max(this.maxHeight, this.defaultHeight);

            extent = Sector.computeBoundingBox(dc.getGlobe(), dc.getVerticalExaggeration(), this.sector, minHeight,
                maxHeight);
            tile.currentData.setExtent(extent);
        }

        return extent;
    }

    protected boolean mustRegenerateTileGeometry(DrawContext dc, Tile tile)
    {
        // If the new eye distance is significantly closer than cached data's the current eye distance, reduce the
        // timer's remaining time by 50%. This reduction is performed only once each time the timer is reset.
        if (tile.currentData.origin != null)
        {
            double newEyeDistance = dc.getView().getEyePoint().distanceTo3(tile.currentData.origin);
            tile.currentData.adjustTimer(dc, newEyeDistance);
        }

        return tile.currentData.isExpired(dc) || !tile.currentData.isValid(dc);
    }

    protected void invalidateTileGeometry(Tile tile)
    {
        tile.dataCache.setAllExpired(true); // force the tile vertices to be regenerated
        tile.dataCache.clearExtents();
    }

    protected void invalidateAllTileGeometry()
    {
        Queue<Tile> tileQueue = new ArrayDeque<Tile>();
        tileQueue.add(this.rootTile);

        while (!tileQueue.isEmpty())
        {
            Tile tile = tileQueue.poll();
            this.invalidateTileGeometry(tile);

            if (tile.children != null)
            {
                tileQueue.addAll(Arrays.asList(tile.children));
            }
        }
    }

    protected void regenerateTileGeometry(DrawContext dc, Tile tile)
    {
        this.tessellateTile(dc.getTerrain(), tile);

        tile.currentData.setEyeDistance(dc.getView().getEyePoint().distanceTo3(tile.currentData.origin));
        tile.currentData.setGlobeStateKey(dc.getGlobe().getGlobeStateKey(dc));
        tile.currentData.setVerticalExaggeration(dc.getVerticalExaggeration());
        tile.currentData.restartTimer(dc);
    }

    protected void tessellateTile(Terrain terrain, Tile tile)
    {
        TileData tileData = tile.currentData;

        // Allocate the model coordinate vertices to hold the upper and lower points for all records in the tile. The
        // records in the tile never changes, so the number of vertices in the tile never changes.
        int vertexStride = 3;
        FloatBuffer vertices = tileData.vertices;
        if (vertices == null)
        {
            int numPoints = 0;
            for (ShapefileRenderable.Record record : tile.records)
            {
                numPoints += record.numberOfPoints;
            }

            vertices = Buffers.newDirectFloatBuffer(2 * vertexStride * numPoints);
        }

        // Generate the model coordinate vertices and indices for all records in the tile. This may include records that
        // are marked as not visible, as recomputing the vertices and indices for record visibility changes would be
        // expensive. The tessellated interior and outline indices are generated only once, since each record's indices
        // never change.
        tileData.origin = null;
        double[] coord = this.doubleArray;
        float[] vertex = this.floatArray;
        for (ShapefileRenderable.Record record : tile.records)
        {
            double height = record.height != null ? record.height : this.defaultHeight;
            double NdotR = 0;
            Vec4 N = null;

            this.tess.setEnabled(record.interiorIndices == null); // generate polygon interior and outline indices once
            this.tess.reset();
            this.tess.setPolygonNormal(0, 0, 1); // tessellate in geographic coordinates
            this.tess.beginPolygon();

            for (int part = record.firstPartNumber; part <= record.lastPartNumber; part++)
            {
                this.tess.beginContour();

                VecBuffer subBuffer = this.coordBuffer.subBuffer(part);
                for (int i = 0; i < subBuffer.getSize(); i++)
                {
                    subBuffer.get(i, coord);
                    Vec4 p = terrain.getSurfacePoint(Angle.fromDegrees(coord[1]), Angle.fromDegrees(coord[0]), 0);

                    // Tessellate indices in geographic coordinates. This produces an index tessellation that is
                    // independent of the record's model coordinates, since the count and organization of top and bottom
                    // of vertices is always the same.
                    int index = vertices.position() / vertexStride; // index of top vertex
                    this.tess.addVertex(coord[1], coord[0], 0, index); // coordinates stored as lon,lat

                    if (tileData.origin == null) // first vertex in the tile
                    {
                        tileData.origin = p;
                    }

                    if (N == null) // first vertex in the record
                    {
                        N = terrain.getGlobe().computeSurfaceNormalAtPoint(p);
                        NdotR = N.dot3(p);
                    }

                    // Add the model coordinate top and bottom vertices, with heights relative to the terrain.
                    double t = height - (N.dot3(p) - NdotR);
                    double b = -this.baseDepth;
                    vertex[0] = (float) (p.x + N.x * t - tileData.origin.x);
                    vertex[1] = (float) (p.y + N.y * t - tileData.origin.y);
                    vertex[2] = (float) (p.z + N.z * t - tileData.origin.z);
                    vertex[3] = (float) (p.x + N.x * b - tileData.origin.x);
                    vertex[4] = (float) (p.y + N.y * b - tileData.origin.y);
                    vertex[5] = (float) (p.z + N.z * b - tileData.origin.z);
                    vertices.put(vertex);
                }

                this.tess.endContour();
            }

            this.tess.endPolygon();
            this.assembleRecordIndices(this.tess, record);
        }

        tileData.vertices = (FloatBuffer) vertices.rewind();
        tileData.transformMatrix = Matrix.fromTranslation(tileData.origin.x, tileData.origin.y, tileData.origin.z);
        tileData.vboExpired = true;
    }

    protected void assembleRecordIndices(PolygonTessellator tessellator, ShapefileRenderable.Record record)
    {
        if (!tessellator.isEnabled())
            return;

        // Get the tessellated interior and boundary indices, representing a triangle tessellation and line segment
        // tessellation of the record's top vertices. Flip each buffer in order to limit the buffer range we use to
        // values added during tessellation.
        IntBuffer tessInterior = (IntBuffer) tessellator.getInteriorIndices().flip();
        IntBuffer tessBoundary = (IntBuffer) tessellator.getBoundaryIndices().flip();

        // Allocate the record's interior and outline indices. This accounts for the number of tessellated interior
        // and boundary indices, plus the indices necessary to tessellate the record's sides with triangles and lines.
        IntBuffer interiorIndices = IntBuffer.allocate(tessInterior.remaining() + 3 * tessBoundary.remaining());
        IntBuffer outlineIndices = IntBuffer.allocate(2 * tessBoundary.remaining());

        // Fill the triangle index buffer with the triangle tessellation of the polygon's top vertices.
        interiorIndices.put(tessInterior);

        // Fill the triangle index buffer with a triangle tessellation using two triangles to connect the top and bottom
        // vertices at each boundary line. Fill the line index buffer with a horizontal line for each boundary line
        // segment, and a vertical line at the first vertex of each boundary line segment.
        for (int i = tessBoundary.position(); i < tessBoundary.limit(); i += 2)
        {
            int top1 = tessBoundary.get(i);
            int top2 = tessBoundary.get(i + 1);
            int bot1 = top1 + 1; // top and bottom vertices are adjacent
            int bot2 = top2 + 1;
            // side top left triangle
            interiorIndices.put(top1);
            interiorIndices.put(bot1);
            interiorIndices.put(top2);
            // side bottom right triangle
            interiorIndices.put(top2);
            interiorIndices.put(bot1);
            interiorIndices.put(bot2);
            // top horizontal line
            outlineIndices.put(top1);
            outlineIndices.put(top2);
            // vertical line
            outlineIndices.put(top1);
            outlineIndices.put(bot1);
        }

        record.interiorIndices = (IntBuffer) interiorIndices.rewind();
        record.outlineIndices = (IntBuffer) outlineIndices.rewind();
    }

    protected boolean mustAssembleTileAttributeGroups(Tile tile)
    {
        return tile.attributeGroups.isEmpty();
    }

    protected void invalidateTileAttributeGroups(Tile tile)
    {
        tile.attributeGroups.clear();
    }

    protected void assembleTileAttributeGroups(Tile tile)
    {
        tile.attributeGroups.clear();

        // Assemble the tile's records into groups with common attributes. Attributes are compared using the instance's
        // address, so subsequent changes to an Attribute instance will be reflected in the record group automatically.
        // We take care to avoid assembling groups based on any Attribute property, as those properties may change
        // without re-assembling these groups. However, changes to a record's visibility state, highlight state, normal
        // attributes reference and highlight attributes reference invalidate this grouping.
        HashMap<ShapeAttributes, RecordGroup> attrMap = new HashMap<ShapeAttributes, RecordGroup>();
        for (Record record : tile.records)
        {
            if (!record.isVisible()) // ignore records marked as not visible
                continue;

            ShapeAttributes attrs = this.determineActiveAttributes(record);
            RecordGroup group = attrMap.get(attrs);

            if (group == null) // create a new group if one doesn't already exist
            {
                group = new RecordGroup(attrs);
                attrMap.put(attrs, group); // add it to the map to prevent duplicates
                tile.attributeGroups.add(group); // add it to the tile's attribute group list
            }

            group.records.add(record);
            group.interiorIndexRange.length += record.interiorIndices.remaining();
            group.outlineIndexRange.length += record.outlineIndices.remaining();
        }

        // Make the indices for each record group. We take care to make indices for both the interior and the outline,
        // regardless of the current state of Attributes.isDrawInterior and Attributes.isDrawOutline. This enable these
        // properties change state without needing to re-assemble these groups.
        for (RecordGroup group : tile.attributeGroups)
        {
            int indexCount = group.interiorIndexRange.length + group.outlineIndexRange.length;
            IntBuffer indices = Buffers.newDirectIntBuffer(indexCount);

            group.interiorIndexRange.location = indices.position();
            for (Record record : group.records) // assemble the group's triangle indices in a single contiguous range
            {
                indices.put(record.interiorIndices);
                record.interiorIndices.rewind();
            }

            group.outlineIndexRange.location = indices.position();
            for (Record record : group.records) // assemble the group's line indices in a single contiguous range
            {
                indices.put(record.outlineIndices);
                record.outlineIndices.rewind();
            }

            group.indices = (IntBuffer) indices.rewind();
            group.records.clear();
            group.records.trimToSize(); // Reduce memory overhead from unused ArrayList capacity.
        }
    }

    protected void drawOrderedSurfaceRenderable(DrawContext dc)
    {
        try
        {
            this.beginDrawing(dc);

            for (Tile tile : this.currentTiles)
            {
                if (dc.isPickingMode())
                {
                    Color color = dc.getUniquePickColor();
                    dc.getGL().getGL2().glColor3ub((byte) color.getRed(), (byte) color.getGreen(),
                        (byte) color.getBlue());
                    this.pickSupport.addPickableObject(color.getRGB(), tile);
                }

                this.drawTile(dc, tile);
            }
        }
        finally
        {
            this.endDrawing(dc);
        }
    }

    protected void beginDrawing(DrawContext dc)
    {
        GL2 gl = dc.getGL().getGL2(); // GL initialization checks for GL2 compatibility.
        gl.glEnableClientState(GL2.GL_VERTEX_ARRAY); // all drawing uses vertex arrays
        gl.glDepthFunc(GL.GL_LEQUAL);
        gl.glMatrixMode(GL2.GL_MODELVIEW);
        gl.glPushMatrix();

        if (!dc.isPickingMode())
        {
            gl.glEnable(GL.GL_BLEND);
            gl.glEnable(GL.GL_LINE_SMOOTH);
            gl.glBlendFunc(GL.GL_SRC_ALPHA, GL.GL_ONE_MINUS_SRC_ALPHA);
            gl.glHint(GL.GL_LINE_SMOOTH_HINT, GL.GL_FASTEST);
        }
    }

    protected void endDrawing(DrawContext dc)
    {
        GL2 gl = dc.getGL().getGL2(); // GL initialization checks for GL2 compatibility.
        gl.glDisableClientState(GL2.GL_VERTEX_ARRAY);
        gl.glColor4f(1, 1, 1, 1);
        gl.glDepthFunc(GL.GL_LESS);
        gl.glLineWidth(1);
        gl.glPopMatrix();

        if (!dc.isPickingMode())
        {
            gl.glDisable(GL.GL_BLEND);
            gl.glDisable(GL.GL_LINE_SMOOTH);
            gl.glBlendFunc(GL.GL_ONE, GL.GL_ZERO);
            gl.glHint(GL.GL_LINE_SMOOTH_HINT, GL.GL_DONT_CARE);
        }

        if (dc.getGLRuntimeCapabilities().isUseVertexBufferObject())
        {
            gl.glBindBuffer(GL.GL_ARRAY_BUFFER, 0);
            gl.glBindBuffer(GL.GL_ELEMENT_ARRAY_BUFFER, 0);
        }
    }

    protected void drawTile(DrawContext dc, Tile tile)
    {
        GL2 gl = dc.getGL().getGL2(); // GL initialization checks for GL2 compatibility.
        TileData tileData = tile.currentData;

        int[] vboId = null;
        boolean useVbo = dc.getGLRuntimeCapabilities().isUseVertexBufferObject();
        if (useVbo && (vboId = (int[]) dc.getGpuResourceCache().get(tileData.vboKey)) == null)
        {
            long vboSize = 4 * tileData.vertices.remaining(); // 4 bytes for each float vertex component
            vboId = new int[1];
            gl.glGenBuffers(1, vboId, 0);
            gl.glBindBuffer(GL.GL_ARRAY_BUFFER, vboId[0]);
            gl.glBufferData(GL.GL_ARRAY_BUFFER, vboSize, tileData.vertices, GL.GL_STATIC_DRAW);
            gl.glVertexPointer(3, GL.GL_FLOAT, 0, 0);
            dc.getGpuResourceCache().put(tileData.vboKey, vboId, GpuResourceCache.VBO_BUFFERS, vboSize);
        }
        else if (useVbo)
        {
            gl.glBindBuffer(GL.GL_ARRAY_BUFFER, vboId[0]);
            if (tileData.vboExpired)
            {
                gl.glBufferSubData(GL.GL_ARRAY_BUFFER, 0, 4 * tileData.vertices.remaining(), tileData.vertices);
                tileData.vboExpired = false;
            }
            gl.glVertexPointer(3, GL.GL_FLOAT, 0, 0);
        }
        else
        {
            gl.glVertexPointer(3, GL.GL_FLOAT, 0, tileData.vertices);
        }

        Matrix modelview = dc.getView().getModelviewMatrix().multiply(tileData.transformMatrix);
        modelview.toArray(this.doubleArray, 0, false);
        gl.glLoadMatrixd(this.doubleArray, 0);

        for (RecordGroup attrGroup : tile.attributeGroups)
        {
            this.drawRecordGroup(dc, attrGroup);
        }
    }

    protected void drawRecordGroup(DrawContext dc, RecordGroup recordGroup)
    {
        GL2 gl = dc.getGL().getGL2(); // GL initialization checks for GL2 compatibility.

        int[] vboId = null;
        boolean useVbo = dc.getGLRuntimeCapabilities().isUseVertexBufferObject();
        if (useVbo && (vboId = (int[]) dc.getGpuResourceCache().get(recordGroup.vboKey)) == null)
        {
            long vboSize = 4 * recordGroup.indices.remaining(); // 4 bytes for each unsigned int index
            vboId = new int[1];
            gl.glGenBuffers(1, vboId, 0);
            gl.glBindBuffer(GL.GL_ELEMENT_ARRAY_BUFFER, vboId[0]);
            gl.glBufferData(GL.GL_ELEMENT_ARRAY_BUFFER, vboSize, recordGroup.indices, GL.GL_STATIC_DRAW);
            dc.getGpuResourceCache().put(recordGroup.vboKey, vboId, GpuResourceCache.VBO_BUFFERS, vboSize);
        }
        else if (useVbo)
        {
            gl.glBindBuffer(GL.GL_ELEMENT_ARRAY_BUFFER, vboId[0]);
        }

        if (recordGroup.attributes.isDrawInterior())
        {
            if (!dc.isPickingMode())
            {
                float[] color = this.floatArray;
                recordGroup.attributes.getInteriorMaterial().getDiffuse().getRGBColorComponents(color);
                gl.glColor3f(color[0], color[1], color[2]);
            }

            if (useVbo)
            {
                gl.glDrawElements(GL.GL_TRIANGLES, recordGroup.interiorIndexRange.length, GL.GL_UNSIGNED_INT,
                    4 * recordGroup.interiorIndexRange.location);
            }
            else
            {
                gl.glDrawElements(GL.GL_TRIANGLES, recordGroup.interiorIndexRange.length, GL.GL_UNSIGNED_INT,
                    recordGroup.indices.position(recordGroup.interiorIndexRange.location));
                recordGroup.indices.rewind();
            }
        }

        if (recordGroup.attributes.isDrawOutline())
        {
            gl.glLineWidth((float) recordGroup.attributes.getOutlineWidth());

            if (!dc.isPickingMode())
            {
                float[] color = this.floatArray;
                recordGroup.attributes.getOutlineMaterial().getDiffuse().getRGBColorComponents(color);
                gl.glColor3f(color[0], color[1], color[2]);
            }

            if (useVbo)
            {
                gl.glDrawElements(GL.GL_LINES, recordGroup.outlineIndexRange.length, GL.GL_UNSIGNED_INT,
                    4 * recordGroup.outlineIndexRange.location);
            }
            else
            {
                gl.glDrawElements(GL.GL_LINES, recordGroup.outlineIndexRange.length, GL.GL_UNSIGNED_INT,
                    recordGroup.indices.position(recordGroup.outlineIndexRange.location));
                recordGroup.indices.rewind();
            }
        }
    }

    protected void drawTileInUniqueColors(DrawContext dc, Tile tile)
    {
        GL2 gl = dc.getGL().getGL2();
        TileData tileData = tile.currentData;

        int pickColorsSize = tileData.vertices.remaining(); // 1 RGB color for each XYZ vertex
        if (this.pickColors == null || this.pickColors.capacity() < pickColorsSize)
        {
            this.pickColors = Buffers.newDirectByteBuffer(pickColorsSize);
            dc.getGpuResourceCache().remove(this.pickColorsVboKey); // remove any associated VBO from GPU memory
        }

        byte[] vertexColors = this.byteArray;
        this.pickColors.clear();

        for (ShapefileRenderable.Record record : tile.records)
        {
            // Get a unique pick color for the record, and add it to the list of pickable objects. We must generate a
            // color for every record, regardless of its visibility, since the tile's color array must match the
            // tile's vertex array, which includes invisible records.
            Color color = dc.getUniquePickColor();
            this.pickSupport.addPickableObject(color.getRGB(), record);

            // top vertex
            vertexColors[0] = (byte) color.getRed();
            vertexColors[1] = (byte) color.getGreen();
            vertexColors[2] = (byte) color.getBlue();
            // bottom vertex
            vertexColors[3] = vertexColors[0];
            vertexColors[4] = vertexColors[1];
            vertexColors[5] = vertexColors[2];

            // Add the unique color for the top and bottom vertices of the record.
            for (int i = 0; i < record.numberOfPoints; i++)
            {
                this.pickColors.put(vertexColors);
            }
        }

        this.pickColors.flip();

        int[] vboId = null;
        boolean useVbo = dc.getGLRuntimeCapabilities().isUseVertexBufferObject();
        if (useVbo && (vboId = (int[]) dc.getGpuResourceCache().get(this.pickColorsVboKey)) == null)
        {
            vboId = new int[1];
            gl.glGenBuffers(1, vboId, 0);
            gl.glBindBuffer(GL.GL_ARRAY_BUFFER, vboId[0]);
            gl.glBufferData(GL.GL_ARRAY_BUFFER, pickColorsSize, this.pickColors, GL2.GL_DYNAMIC_DRAW);
            gl.glColorPointer(3, GL.GL_UNSIGNED_BYTE, 0, 0);
            dc.getGpuResourceCache().put(this.pickColorsVboKey, vboId, GpuResourceCache.VBO_BUFFERS, pickColorsSize);
        }
        else if (useVbo)
        {
            gl.glBindBuffer(GL.GL_ARRAY_BUFFER, vboId[0]);
            gl.glBufferSubData(GL.GL_ARRAY_BUFFER, 0, pickColorsSize, this.pickColors);
            gl.glColorPointer(3, GL.GL_UNSIGNED_BYTE, 0, 0);
        }
        else
        {
            gl.glColorPointer(3, GL.GL_UNSIGNED_BYTE, 0, this.pickColors);
        }

        try
        {
            gl.glEnableClientState(GL2.GL_COLOR_ARRAY);
            this.drawTile(dc, tile);
        }
        finally
        {
            gl.glDisableClientState(GL2.GL_COLOR_ARRAY);
        }
    }
}