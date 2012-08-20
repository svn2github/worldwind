/*
 * Copyright (C) 2012 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwindx.examples.openstreetmap;

import gov.nasa.worldwind.*;
import gov.nasa.worldwind.avlist.AVKey;
import gov.nasa.worldwind.cache.*;
import gov.nasa.worldwind.geom.*;
import gov.nasa.worldwind.layers.AbstractLayer;
import gov.nasa.worldwind.layers.placename.PlaceNameLayer;
import gov.nasa.worldwind.render.*;
import gov.nasa.worldwind.util.Logging;

import java.awt.*;
import java.io.*;
import java.net.URL;
import java.util.*;
import java.util.List;
import java.util.concurrent.PriorityBlockingQueue;
import java.util.logging.Level;
import java.util.zip.ZipInputStream;

/**
 * This is a generalization of PlaceNameLayer made specific for displaying cached Open Street Map data.
 * @author tag
 * @version $Id$
 */
public abstract class OSMAbstractLayer extends AbstractLayer
{
    protected List<OSMCluster> clusters;
    protected OSMShapeFactory shapeFactory;
    protected Vec4 referencePoint;
    protected List<NavigationTile> navTiles = new ArrayList<NavigationTile>();
    protected PriorityBlockingQueue<Runnable> requestQ = new PriorityBlockingQueue<Runnable>(64);

    protected List<Tile> currentDataTiles = new ArrayList<Tile>();

    protected abstract List<Renderable> makeShapes(InputStream inputStream)  throws IOException;
    protected abstract String getCacheFilePrefix();

    public OSMAbstractLayer(OSMShapeFactory shapeFactory)
    {
        this.shapeFactory = shapeFactory;

        this.initializeClusters();

        for (int i = 0; i < this.clusters.size(); i++)
        {
            int calc1 = (int) (Sector.FULL_SPHERE.getDeltaLatDegrees()
                / this.clusters.get(i).getTileDelta().getLatitude().getDegrees());
            int numLevels = (int) Math.log(calc1);

            navTiles.add(new NavigationTile(this.clusters.get(i), Sector.FULL_SPHERE, numLevels, "top"));
        }

        if (!WorldWind.getMemoryCacheSet().containsCache(Tile.class.getName()))
        {
            long size = Configuration.getLongValue(AVKey.OSM_LAYER_CACHE_SIZE, 2000L);
            MemoryCache cache = new BasicMemoryCache((long) (0.85 * size), size);
            cache.setName("OSM Layer Tiles");
            WorldWind.getMemoryCacheSet().addCache(Tile.class.getName(), cache);
        }
    }

    protected void initializeClusters()
    {
        this.clusters = new ArrayList<OSMCluster>(8);

        String cachePath = "Earth/OpenStreetMap";

        this.clusters.add(new OSMCluster("0", cachePath, OSMCacheBuilder.LEVEL_DELTAS[0], PlaceNameLayer.LEVEL_G,
            PlaceNameLayer.LEVEL_A));
        this.clusters.add(new OSMCluster("1", cachePath, OSMCacheBuilder.LEVEL_DELTAS[1], PlaceNameLayer.LEVEL_G,
            PlaceNameLayer.LEVEL_C));
        this.clusters.add(new OSMCluster("2", cachePath, OSMCacheBuilder.LEVEL_DELTAS[2], PlaceNameLayer.LEVEL_I,
            PlaceNameLayer.LEVEL_F));
        this.clusters.add(new OSMCluster("3", cachePath, OSMCacheBuilder.LEVEL_DELTAS[3], 0, PlaceNameLayer.LEVEL_G));
        this.clusters.add(new OSMCluster("4", cachePath, OSMCacheBuilder.LEVEL_DELTAS[4], 0, PlaceNameLayer.LEVEL_H));
        this.clusters.add(new OSMCluster("5", cachePath, OSMCacheBuilder.LEVEL_DELTAS[5], 0, PlaceNameLayer.LEVEL_I));
        this.clusters.add(new OSMCluster("6", cachePath, OSMCacheBuilder.LEVEL_DELTAS[6], 0, PlaceNameLayer.LEVEL_K));
        this.clusters.add(new OSMCluster("7", cachePath, OSMCacheBuilder.LEVEL_DELTAS[7], 0, PlaceNameLayer.LEVEL_M));
    }

    protected PriorityBlockingQueue<Runnable> getRequestQ()
    {
        return this.requestQ;
    }

    protected Tile[] buildDataTiles(OSMCluster cluster, NavigationTile navTile)
    {
        final Angle dLat = cluster.getTileDelta().getLatitude();
        final Angle dLon = cluster.getTileDelta().getLongitude();

        // Determine the row and column offset from the global tiling origin for the southwest tile corner
        int firstRow = Tile.computeRow(dLat, navTile.navSector.getMinLatitude());
        int firstCol = Tile.computeColumn(dLon, navTile.navSector.getMinLongitude());
        int lastRow = Tile.computeRow(dLat, navTile.navSector.getMaxLatitude().subtract(dLat));
        int lastCol = Tile.computeColumn(dLon, navTile.navSector.getMaxLongitude().subtract(dLon));

        int nLatTiles = lastRow - firstRow + 1;
        int nLonTiles = lastCol - firstCol + 1;

        Tile[] tiles = new Tile[nLatTiles * nLonTiles];

        Angle p1 = Tile.computeRowLatitude(firstRow, dLat);
        for (int row = 0; row <= lastRow - firstRow; row++)
        {
            Angle p2;
            p2 = p1.add(dLat);

            Angle t1 = Tile.computeColumnLongitude(firstCol, dLon);
            for (int col = 0; col <= lastCol - firstCol; col++)
            {
                Angle t2;
                t2 = t1.add(dLon);
                //Need offset row and column to correspond to total ro/col numbering
                tiles[col + row * nLonTiles] = new Tile(this, cluster, new Sector(p1, p2, t1, t2),
                    row + firstRow, col + firstCol);
                t1 = t2;
            }
            p1 = p2;
        }

        return tiles;
    }

    protected Angle clampAngle(Angle a, Angle min, Angle max)
    {
        double degrees = a.degrees;
        double minDegrees = min.degrees;
        double maxDegrees = max.degrees;
        return Angle.fromDegrees(degrees < minDegrees ? minDegrees : (degrees > maxDegrees ? maxDegrees : degrees));
    }

    @Override
    protected void doPick(DrawContext dc, Point point)
    {
        if (dc.getVisibleSector() == null)
            return;

        this.assembleTiles(dc);

        if (this.currentDataTiles.size() < 1)
            return;

        for (Tile tile : this.currentDataTiles)
        {
            this.drawOrRequestTile(dc, tile);
        }
    }

    protected void doPreRender(DrawContext dc)
    {
        if (dc.getVisibleSector() == null)
            return;

        this.assembleTiles(dc);

        if (this.currentDataTiles.size() < 1)
            return;

        for (Tile tile : this.currentDataTiles)
        {
            this.drawOrRequestTile(dc, tile);
        }
    }

    protected void doRender(DrawContext dc)
    {
        if (dc.getVisibleSector() == null)
            return;

        this.assembleTiles(dc);

        if (this.currentDataTiles.size() < 1)
            return;

        for (Tile tile : this.currentDataTiles)
        {
            this.drawOrRequestTile(dc, tile);
        }
    }

    protected long frameTimeStamp;

    protected void assembleTiles(DrawContext dc)
    {
        if (dc.getFrameTimeStamp() == this.frameTimeStamp)
            return;

        this.frameTimeStamp = dc.getFrameTimeStamp();
        this.currentDataTiles.clear();

        this.referencePoint = this.computeReferencePoint(dc);

        for (int i = 0; i < this.clusters.size(); i++)
        {
            List<Tile> dataTiles = this.assembleClusterDataTiles(dc, i);
            if (dataTiles == null || dataTiles.size() < 1)
                continue;

            this.currentDataTiles.addAll(dataTiles);
        }

        this.sendRequests();
        this.requestQ.clear();
    }

    protected List<Tile> assembleClusterDataTiles(DrawContext dc, int clusterNumber)
    {
        List<Tile> dataTiles = null;

        OSMCluster cluster = this.clusters.get(clusterNumber);

        double minDistSquared = cluster.getMinDisplayDistance() * cluster.getMinDisplayDistance();
        double maxDistSquared = cluster.getMaxDisplayDistance() * cluster.getMaxDisplayDistance();

        if (isClusterVisible(dc, minDistSquared, maxDistSquared))
        {
            NavigationTile navTile = this.navTiles.get(clusterNumber);

            // Drill down into nav tiles to find bottom level navTiles visible.
            List<NavigationTile> navTilesVisible = navTile.getVisibleNavTiles(dc, minDistSquared, maxDistSquared);

            // Get the data tiles for each visible nav tile.
            for (NavigationTile nt : navTilesVisible)
            {
                List<Tile> tiles = nt.getTiles();
                if (tiles == null || tiles.size() < 1)
                    continue;

                if (dataTiles == null)
                    dataTiles = new ArrayList<Tile>();

                for (Tile tile : tiles)
                {
                    if (this.isTileVisible(dc, tile, minDistSquared, maxDistSquared))
                        dataTiles.add(tile);
                }
            }
        }

        return dataTiles;
    }

    protected Vec4 computeReferencePoint(DrawContext dc)
    {
        if (dc.getViewportCenterPosition() != null)
            return dc.getGlobe().computePointFromPosition(dc.getViewportCenterPosition());

        java.awt.geom.Rectangle2D viewport = dc.getView().getViewport();
        int x = (int) viewport.getWidth() / 2;
        for (int y = (int) (0.5 * viewport.getHeight()); y >= 0; y--)
        {
            Position pos = dc.getView().computePositionFromScreenPoint(x, y);
            if (pos == null)
                continue;

            return dc.getGlobe().computePointFromPosition(pos.getLatitude(), pos.getLongitude(), 0d);
        }

        return null;
    }

    protected boolean isClusterVisible(DrawContext dc, double minDistanceSquared, double maxDistanceSquared)
    {
        double distanceSquared = dc.getView().getEyePoint().distanceToSquared3(this.referencePoint);

        return minDistanceSquared < distanceSquared && maxDistanceSquared > distanceSquared;
    }

    protected void drawOrRequestTile(DrawContext dc, Tile tile)
    {
        if (tile.isTileInMemoryWithData())
        {
            List<Renderable> shapes = tile.getShapes();
            if (shapes != null)
            {
                for (Renderable shape : shapes)
                {
                    if (shape instanceof PreRenderable && dc.isPreRenderMode())
                        ((PreRenderable) shape).preRender(dc);
                    else
                        shape.render(dc);
                }
            }
            return;
        }

        // Tile's data isn't available, so request it
        if (!tile.getCluster().isResourceAbsent(tile.getCluster().getTileNumber(tile.row, tile.column)))
            this.requestTile(dc, tile);
    }

    protected boolean isTileVisible(DrawContext dc, Tile tile, double minDistanceSquared, double maxDistanceSquared)
    {
        if (!tile.getSector().intersects(dc.getVisibleSector()))
            return false;

        View view = dc.getView();
        Position eyePos = view.getEyePosition();
        if (eyePos == null)
            return false;

        Angle lat = clampAngle(eyePos.getLatitude(), tile.getSector().getMinLatitude(),
            tile.getSector().getMaxLatitude());
        Angle lon = clampAngle(eyePos.getLongitude(), tile.getSector().getMinLongitude(),
            tile.getSector().getMaxLongitude());
        Vec4 p = dc.getGlobe().computePointFromPosition(lat, lon, 0d);
        double distSquared = dc.getView().getEyePoint().distanceToSquared3(p);
        //noinspection RedundantIfStatement
        if (minDistanceSquared > distSquared || maxDistanceSquared < distSquared)
            return false;

        return true;
    }

    protected void requestTile(DrawContext dc, Tile tile)
    {
        Vec4 centroid = dc.getGlobe().computePointFromPosition(tile.getSector().getCentroid(), 0);
        if (this.referencePoint != null)
            tile.setPriority(centroid.distanceTo3(this.referencePoint));

        RequestTask task = new RequestTask(tile, this);
        this.getRequestQ().add(task);
    }

    protected void sendRequests()
    {
        Runnable task = this.requestQ.poll();
        while (task != null)
        {
            if (!WorldWind.getTaskService().isFull())
            {
                WorldWind.getTaskService().addTask(task);
            }
            task = this.requestQ.poll();
        }
    }

    protected static class RequestTask implements Runnable, Comparable<RequestTask>
    {
        protected final OSMAbstractLayer layer;
        public final Tile tile;

        RequestTask(Tile tile, OSMAbstractLayer layer)
        {
            this.layer = layer;
            this.tile = tile;
        }

        public void run()
        {
            if (Thread.currentThread().isInterrupted())
                return;

            if (this.tile.isTileInMemoryWithData())
                return;

            final java.net.URL tileURL = this.layer.getDataFileStore().findFile(tile.getFileCachePath(), false);
            if (tileURL != null)
            {
                this.layer.loadTile(this.tile, tileURL);
                this.layer.firePropertyChange(AVKey.LAYER, null, this);
            }
            else
            {
                tile.getCluster().markResourceAbsent(tile.getCluster().getTileNumber(tile.row, tile.column));
            }
        }

        /**
         * @param that the task to compare
         *
         * @return -1 if <code>this</code> less than <code>that</code>, 1 if greater than, 0 if equal
         *
         * @throws IllegalArgumentException if <code>that</code> is null
         */
        public int compareTo(RequestTask that)
        {
            if (that == null)
            {
                String msg = Logging.getMessage("nullValue.RequestTaskIsNull");
                Logging.logger().severe(msg);
                throw new IllegalArgumentException(msg);
            }
            return this.tile.getPriority() == that.tile.getPriority() ? 0 :
                this.tile.getPriority() < that.tile.getPriority() ? -1 : 1;
        }

        public boolean equals(Object o)
        {
            if (this == o)
                return true;
            if (o == null || getClass() != o.getClass())
                return false;

            final RequestTask that = (RequestTask) o;

            // Don't include layer in comparison so that requests are shared among layers
            return !(tile != null ? !tile.equals(that.tile) : that.tile != null);
        }

        public int hashCode()
        {
            return (tile != null ? tile.hashCode() : 0);
        }

        public String toString()
        {
            return this.tile.toString();
        }
    }

    protected void loadTile(Tile tile, java.net.URL url)
    {
        tile.setShapes(this.readTileData(url));

        WorldWind.getMemoryCache(Tile.class.getName()).add(tile.getFileCachePath(), tile);
    }

    protected List<Renderable> readTileData(URL url)
    {
        ZipInputStream zis = null;

        try
        {
            String path = url.getFile();
            path = path.replaceAll("%20", " ");

            java.io.FileInputStream fis = new java.io.FileInputStream(path);
            java.io.BufferedInputStream buf = new java.io.BufferedInputStream(fis);
            zis = new ZipInputStream(buf);
            zis.getNextEntry();

            return this.makeShapes(zis);
        }
        catch (Exception e)
        {
            Logging.logger().log(Level.FINE,
                Logging.getMessage("layers.PlaceNameLayer.ExceptionAttemptingToReadFile", url.toString()), e);
        }
        finally
        {
            try
            {
                if (zis != null)
                    zis.close();
            }
            catch (java.io.IOException e)
            {
                Logging.logger().log(Level.FINE,
                    Logging.getMessage("layers.PlaceNameLayer.ExceptionAttemptingToReadFile", url.toString()), e);
            }
        }

        return null;
    }

    protected String createFileCachePath(OSMCluster cluster, int row, int column)
    {
        if (row < 0 || column < 0)
        {
            String message = Logging.getMessage("PlaceNameService.RowOrColumnOutOfRange", row, column);
            Logging.logger().severe(message);
            throw new IllegalArgumentException(message);
        }

        StringBuilder sb = new StringBuilder(cluster.getFileCachePath());
        sb.append(File.separator).append(cluster.getClusterName());
        sb.append(File.separator).append(row);
        sb.append(File.separator).append(this.getCacheFilePrefix());
        sb.append(".").append(row).append('.').append(column);
        sb.append(".zip");

        String path = sb.toString();
        return path.replaceAll("[:*?<>|]", "");
    }

    @Override
    public String toString()
    {
        return "Open Street Map Places";
    }

    protected class NavigationTile
    {
        protected String id;
        protected OSMCluster cluster;
        protected Sector navSector;
        protected List<NavigationTile> subNavTiles = new ArrayList<NavigationTile>();
        protected List<String> tileKeys = new ArrayList<String>();
        protected int level;

        NavigationTile(OSMCluster cluster, Sector sector, int level, String id)
        {
            this.cluster = cluster;
            this.id = id;
            this.navSector = sector;
            this.level = level;
        }

        protected void buildSubNavTiles()
        {
            if (level > 0)
            {
                //split sector, create a navTile for each quad
                Sector[] subSectors = this.navSector.subdivide();
                for (int j = 0; j < subSectors.length; j++)
                {
                    subNavTiles.add(new NavigationTile(this.cluster, subSectors[j], this.level - 1, this.id + "." + j));
                }
            }
        }

        public List<NavigationTile> getVisibleNavTiles(DrawContext dc, double minDistSquared, double maxDistSquared)
        {
            ArrayList<NavigationTile> navList = new ArrayList<NavigationTile>();
            if (this.isNavSectorVisible(dc, minDistSquared, maxDistSquared))
            {
                if (this.level > 0 && !this.hasSubTiles())
                    this.buildSubNavTiles();

                if (this.hasSubTiles())
                {
                    for (NavigationTile nav : this.subNavTiles)
                    {
                        navList.addAll(nav.getVisibleNavTiles(dc, minDistSquared, maxDistSquared));
                    }
                }
                else  //at bottom level navigation tile
                {
                    navList.add(this);
                }
            }

            return navList;
        }

        public boolean hasSubTiles()
        {
            return !subNavTiles.isEmpty();
        }

        protected boolean isNavSectorVisible(DrawContext dc, double minDistanceSquared, double maxDistanceSquared)
        {
            if (!navSector.intersects(dc.getVisibleSector()))
                return false;

            View view = dc.getView();
            Position eyePos = view.getEyePosition();
            if (eyePos == null)
                return false;

            //check for eyePos over globe
            if (Double.isNaN(eyePos.getLatitude().getDegrees()) || Double.isNaN(eyePos.getLongitude().getDegrees()))
                return false;

            Angle lat = clampAngle(eyePos.getLatitude(), navSector.getMinLatitude(), navSector.getMaxLatitude());
            Angle lon = clampAngle(eyePos.getLongitude(), navSector.getMinLongitude(), navSector.getMaxLongitude());
            Vec4 p = dc.getGlobe().computePointFromPosition(lat, lon, 0d);
            double distSquared = dc.getView().getEyePoint().distanceToSquared3(p);
            //noinspection RedundantIfStatement
            if (minDistanceSquared > distSquared || maxDistanceSquared < distSquared)
                return false;

            return true;
        }

        public List<Tile> getTiles()
        {
            if (tileKeys.isEmpty())
            {
                Tile[] tiles = buildDataTiles(this.cluster, this);
                //load tileKeys
                for (Tile t : tiles)
                {
                    tileKeys.add(t.getFileCachePath());
                    WorldWind.getMemoryCache(Tile.class.getName()).add(t.getFileCachePath(), t);
                }
                return Arrays.asList(tiles);
            }
            else
            {
                List<Tile> dataTiles = new ArrayList<Tile>();
                for (String s : tileKeys)
                {
                    Tile t = (Tile) WorldWind.getMemoryCache(Tile.class.getName()).getObject(s);
                    if (t != null)
                    {
                        dataTiles.add(t);
                    }
                }
                return dataTiles;
            }
        }
    }

    protected static class Tile implements Cacheable
    {
        protected final OSMCluster cluster;
        protected final Sector sector;
        protected final int row;
        protected final int column;
        protected Integer hashInt = null;
        // Computed data.
        protected String fileCachePath = null;
        protected double priority = Double.MAX_VALUE; // Default is minimum priority
        protected List<Renderable> shapes;

        Tile(OSMAbstractLayer layer, OSMCluster cluster, Sector sector, int row, int column)
        {
            this.cluster = cluster;
            this.sector = sector;
            this.row = row;
            this.column = column;
            this.fileCachePath = layer.createFileCachePath(cluster, this.row, this.column);
            this.hashInt = this.computeHash();
        }

        public void setShapes(List<Renderable> shapes)
        {
            this.shapes = shapes;
        }

        public List<Renderable> getShapes()
        {
            return this.shapes;
        }

        public long getSizeInBytes()
        {
            return 1; // using counts, not sizes
        }

        static int computeRow(Angle delta, Angle latitude)
        {
            if (delta == null || latitude == null)
            {
                String msg = Logging.getMessage("nullValue.AngleIsNull");
                Logging.logger().severe(msg);
                throw new IllegalArgumentException(msg);
            }
            return (int) ((latitude.getDegrees() + 90d) / delta.getDegrees());
        }

        static int computeColumn(Angle delta, Angle longitude)
        {
            if (delta == null || longitude == null)
            {
                String msg = Logging.getMessage("nullValue.AngleIsNull");
                Logging.logger().severe(msg);
                throw new IllegalArgumentException(msg);
            }
            return (int) ((longitude.getDegrees() + 180d) / delta.getDegrees());
        }

        static Angle computeRowLatitude(int row, Angle delta)
        {
            if (delta == null)
            {
                String msg = Logging.getMessage("nullValue.AngleIsNull");
                Logging.logger().severe(msg);
                throw new IllegalArgumentException(msg);
            }
            return Angle.fromDegrees(-90d + delta.getDegrees() * row);
        }

        static Angle computeColumnLongitude(int column, Angle delta)
        {
            if (delta == null)
            {
                String msg = Logging.getMessage("nullValue.AngleIsNull");
                Logging.logger().severe(msg);
                throw new IllegalArgumentException(msg);
            }
            return Angle.fromDegrees(-180 + delta.getDegrees() * column);
        }

        public Integer getHashInt()
        {
            return hashInt;
        }

        int computeHash()
        {
            return this.getFileCachePath() != null ? this.getFileCachePath().hashCode() : 0;
        }

        @Override
        public boolean equals(Object o)
        {
            if (this == o)
                return true;
            if (o == null || getClass() != o.getClass())
                return false;

            final Tile tile = (Tile) o;

            return !(this.getFileCachePath() != null ? !this.getFileCachePath().equals(tile.getFileCachePath())
                : tile.getFileCachePath() != null);
        }

        public String getFileCachePath()
        {
//            if (this.fileCachePath == null)
//                this.fileCachePath = this.cluster.createFileCachePathFromTile(this.row, this.column);
//
            return this.fileCachePath;
        }

        public OSMCluster getCluster()
        {
            return this.cluster;
        }

        public Sector getSector()
        {
            return sector;
        }

        public int hashCode()
        {
            return this.hashInt;
        }

        protected boolean isTileInMemoryWithData()
        {
            Tile t = (Tile) WorldWind.getMemoryCache(Tile.class.getName()).getObject(this.getFileCachePath());

            return !(t == null || t.getShapes() == null);
        }

        public double getPriority()
        {
            return priority;
        }

        public void setPriority(double priority)
        {
            this.priority = priority;
        }
    }
}
