/*
 * Copyright (C) 2012 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwindx.examples.openstreetmap;

import crosby.binary.osmosis.OsmosisReader;
import gov.nasa.worldwind.WorldWind;
import gov.nasa.worldwind.geom.*;
import gov.nasa.worldwind.layers.placename.PlaceNameLayer;
import gov.nasa.worldwind.util.*;
import org.openstreetmap.osmosis.core.container.v0_6.EntityContainer;
import org.openstreetmap.osmosis.core.domain.v0_6.*;
import org.openstreetmap.osmosis.core.task.v0_6.*;

import javax.xml.stream.XMLStreamException;
import java.io.*;
import java.util.*;
import java.util.zip.*;

/**
 * Caches the contents of Open Street Map .pbf files for use with {@link OSMNodeLayer} and {@link OSMWayLayer}.
 * <p/>
 * Data is cached in a pyramid, with specific OSM key/value pairs placed at specified levels in the pyramid. The level
 * for each key/value pair is specified in the OSM configuration file, which defaults to config/Earth/OSMAttributes.xml.
 * Most of the key/value pairs default to MAX_LEVEL, which is 7.
 * <p/>
 * During normal World Wind operation the {@link OSMNodeLayer} and {@link OSMWayLayer} classes manage loading cached
 * data that has been placed in the cache by this class.
 *
 * @author tag
 * @version $Id$
 */
public class OSMCacheBuilder implements Sink
{
    /**
     * Each level identifies a grid of a certain resolution. Level 0 is the full globe, level 7 is a grid of 1152 x 2304
     * sectors. Data in lower number levels is shown at greater eye distances than that in higher numbered levels.
     */
    public static final LatLon[] LEVEL_DELTAS = new LatLon[]
        {
            PlaceNameLayer.GRID_1x1,
            PlaceNameLayer.GRID_4x8,
            PlaceNameLayer.GRID_8x16,
            PlaceNameLayer.GRID_16x32,
            PlaceNameLayer.GRID_36x72,
            PlaceNameLayer.GRID_72x144,
            PlaceNameLayer.GRID_144x288,
            PlaceNameLayer.GRID_1152x2304,
        };

    /** The minimum level. */
    public static final int MIN_LEVEL = 0;
    /** The maximum level. */
    public static final int MAX_LEVEL = 7;

    /**
     * Cached data is stored in files with a name prefix identifying the type of data in the file. "N" indicates node
     * data, "W" indicates way data.
     */
    public static final String NODE_FILE_PREFIX = "N";
    /**
     * Cached data is stored in files with a name prefix identifying the type of data in the file. "N" indicates node
     * data, "W" indicates way data.
     */
    public static final String WAY_FILE_PREFIX = "W";

    /** The full path to the OSM data cache. */
    protected String cachePath;
    /** The {@link OSMShapeFactory} to use for creating shapes. Created by this class' constructor. */
    protected OSMShapeFactory shapeFactory;

    protected Map<String, NodeLocation> nodeMap;
    protected Map<Integer, Level> levelMap;

    /** Keeps track of the number of nodes in the cache. */
    protected int numNodes;
    /** Keeps track of the number of persisted nodes in the cache. Only named nodes are persisted (cached). */
    protected int numPersistedNodes;
    /** Keeps track of the number of ways in the cache. */
    protected int numWays;
    /** Keeps track of the number ways persisted. */
    protected int numPersistedWays;

    protected static class NodeLocation
    {
        protected float lat;
        protected float lon;

        public NodeLocation(double lat, double lon)
        {
            this.lat = (float) lat;
            this.lon = (float) lon;
        }
    }

    /**
     * Constructs a cache builder instance.
     *
     * @param configurationStream A stream containing configuration data for this cache builder instance. Configuration
     *                            data consists of the OSM attribute specifications. Only the "level" field of the
     *                            attribute bundles is used by this class.
     *
     * @throws XMLStreamException       if an exception occurs while reading the stream.
     * @throws IllegalArgumentException in the input stream is null.
     */
    public OSMCacheBuilder(InputStream configurationStream) throws XMLStreamException
    {
        if (configurationStream == null)
        {
            String message = Logging.getMessage("nullValue.InputStreamIsNull");
            Logging.logger().severe(message);
            throw new IllegalArgumentException(message);
        }

        this.shapeFactory = new OSMShapeFactory(configurationStream);
        this.cachePath = WorldWind.getDataFileStore().getWriteLocation().getPath() + "/Earth/OpenStreetMap";

        this.nodeMap = new HashMap<String, NodeLocation>();
        this.levelMap = new HashMap<Integer, Level>();
    }

    /**
     * Caches the contents of a specified OSM .pbf file.
     *
     * @param file The file whose contents to cache.
     *
     * @throws FileNotFoundException    if the specified file cannot be found.
     * @throws InterruptedException     if reading is interrupted.
     * @throws IllegalArgumentException if the file is null.
     */
    public void loadFromFile(File file) throws FileNotFoundException, InterruptedException
    {
        if (file == null)
        {
            String message = Logging.getMessage("nullValue.FileIsNull");
            Logging.logger().severe(message);
            throw new IllegalArgumentException(message);
        }

        RunnableSource reader = new OsmosisReader(new FileInputStream(file));

        // The Osmosis reader calls methods on this class -- identified as the "sink" -- to process the file.
        reader.setSink(this);

        // Block until the file is fully processed.
        Thread readerThread = new Thread(reader);
        readerThread.start();
        readerThread.join();
    }

    /**
     * This method is a callback for the Osmosis reader.
     *
     * @param entityContainer holds the information for the current entity (node, way or relation)l
     */
    public void process(EntityContainer entityContainer)
    {
        if (Thread.currentThread().isInterrupted())
            return; // TODO: determine how to stop the parser from continuing to call process()

        try
        {
            Entity entity = entityContainer.getEntity();

            if (entity instanceof Node)
            {
                ++this.numNodes;
                this.nodeMap.put(Long.toString(entity.getId()), new NodeLocation(((Node) entity).getLatitude(),
                    ((Node) entity).getLongitude()));

                // Only named nodes are cached. Unnamed nodes that are used by ways are cached with the associated
                // ways.
                if (OSMUtil.containsTagKey(entity, "name"))
                    this.persistNode((Node) entity, this.shapeFactory.determineAttributes(entity));
            }
            else if (entity instanceof Way)
            {
                ++this.numWays;
                this.persistWay((Way) entity, this.shapeFactory.determineAttributes(entity));
            }
        }
        catch (IOException e)
        {
            e.printStackTrace();
        }
    }

    /** This method is a callback for the Osmosis reader. It's called after the file has been parsed. */
    public void release()
    {
        for (Level level : this.levelMap.values())
        {
            level.release();
        }
    }

    /** This method is a callback for the Osmosis reader. It's called after the file has been parsed. */
    public void complete()
    {
    }

    /**
     * Returns the number of nodes encountered during parsing.
     *
     * @return the number of nodes encountered during parsing.
     */
    public int getNumNodes()
    {
        return numNodes;
    }

    /**
     * The number of nodes cached. Only named nodes are cached.
     *
     * @return the number of nodes persisted.
     */
    public int getNumPersistedNodes()
    {
        return numPersistedNodes;
    }

    /**
     * The number of ways encountered during parsing.
     *
     * @return the number of ways encountered.
     */
    public int getNumWays()
    {
        return numWays;
    }

    /**
     * The number of ways cached. This number is typically the same as that returned by {@link #getNumWays()}.
     *
     * @return the number of ways persisted.
     */
    public int getNumPersistedWays()
    {
        return numPersistedWays;
    }

    /**
     * Add the specified node to the cache at the level indicated in the specified attributes.
     *
     * @param node       the node to cache.
     * @param attributes the node attributes. Only the level field is used.
     *
     * @throws IOException if an IO exception occurs while caching the node.
     */
    protected void persistNode(Node node, OSMShapeAttributes attributes) throws IOException
    {
        this.getLevel(attributes.getLevel()).persistNode(node);
    }

    /**
     * Add the specified way to the cache at the level indicated in the specified attributes.
     *
     * @param way        the way to cache.
     * @param attributes the way attributes. Only the level field is used.
     *
     * @throws IOException if an IO exception occurs while caching the node.
     */
    protected void persistWay(Way way, OSMShapeAttributes attributes) throws IOException
    {
        this.getLevel(attributes.getLevel()).persistWay(way);
    }

    /**
     * Returns the {@link Level} associated with a specified level number. A new level is created if one is not already
     * associated with the level number.
     *
     * @param levelNumber the level number.
     *
     * @return the level associated with the specified level number.
     */
    protected Level getLevel(int levelNumber)
    {
        Level level = this.levelMap.get(levelNumber);

        return level != null ? level : this.addLevel(levelNumber);
    }

    /**
     * Adds a {@link Level} for a specified level number.
     *
     * @param levelNumber the level number of the level to add.
     *
     * @return the new level.
     */
    protected Level addLevel(int levelNumber)
    {
        String levelCachePath = this.cachePath + "/" + levelNumber;
        this.levelMap.put(levelNumber, new Level(levelCachePath, LEVEL_DELTAS[levelNumber]));

        return this.levelMap.get(levelNumber);
    }

    /** Represents one level in the OSM cache. */
    protected class Level
    {
        /** The full path to the cache for this level. */
        protected String cachePath;
        /** The size of sectors in this level. */
        protected LatLon sectorDelta;

        /**
         * Maintains a cache of output streams corresponding to files opened by this level. Each file corresponds to one
         * sector of the level. The streams are kept alive because the nodes and ways in the source file are not sorted
         * by location. They are effectively randomly ordered relative to which sector they lie in. The streams are
         * released when file parsing is complete.
         */
        protected Map<TileKey, OutputStream> outputStreams;

        /**
         * Construct a level.
         *
         * @param cachePath   the full cache path for the level.
         * @param sectorDelta the size of sectors within the level.
         */
        protected Level(String cachePath, LatLon sectorDelta)
        {
            this.cachePath = cachePath;
            this.sectorDelta = sectorDelta;

            this.outputStreams = new HashMap<TileKey, OutputStream>();
        }

        /** Release all the output streams used to read the source data. */
        protected void release()
        {
            for (OutputStream os : this.outputStreams.values())
            {
                try
                {
                    os.close();
                }
                catch (IOException e)
                {
                    String message = Logging.getMessage("generic.ExceptionClosingStream");
                    Logging.logger().log(java.util.logging.Level.SEVERE, message, e);
                }
            }
        }

        /**
         * Create the cached representation of the node and write it to the cache.
         *
         * @param node the node to persist.
         *
         * @throws IOException if an IO exception occurs while writing the node to the cache.
         */
        protected void persistNode(Node node) throws IOException
        {
            LatLon location = LatLon.fromDegrees(node.getLatitude(), node.getLongitude());

            int row = this.computeRow(location);
            int col = this.computeCol(location);

            this.makeNode(node).writeDelimitedTo(this.getOutputStream(row, col, NODE_FILE_PREFIX));

            ++numPersistedNodes;
        }

        /**
         * Creates the cached version of a node.
         *
         * @param node the node to cache.
         *
         * @return the cache representation of the node.
         */
        protected OSMNodeProto.Node makeNode(Node node)
        {
            OSMNodeProto.Node.Builder nodeBuilder = OSMNodeProto.Node.newBuilder();

            nodeBuilder.setId(Long.toString(node.getId()));

            nodeBuilder.setLat((float) node.getLatitude());
            nodeBuilder.setLon((float) node.getLongitude());

            for (Tag tag : node.getTags())
            {
                OSMNodeProto.Tag.Builder tagBuilder = OSMNodeProto.Tag.newBuilder();
                tagBuilder.setKey(tag.getKey());
                tagBuilder.setValue(tag.getValue());
                nodeBuilder.addTags(tagBuilder);
            }

            return nodeBuilder.build();
        }

        /**
         * Create the cache representation of the way and write it to the cache.
         *
         * @param way the way to persist.
         *
         * @throws IOException if an error occurs while writing the way to the cache.
         */
        public void persistWay(Way way) throws IOException
        {
            // Need to add the way to all sectors that it intersects.
            Set<OutputStream> streams = new HashSet<OutputStream>();

            for (WayNode wayNode : way.getWayNodes())
            {
                NodeLocation node = nodeMap.get(Long.toString(wayNode.getNodeId()));

                LatLon location = LatLon.fromDegrees(node.lat, node.lon);

                int row = this.computeRow(location);
                int col = this.computeCol(location);

                streams.add(this.getOutputStream(row, col, WAY_FILE_PREFIX));
            }

            OSMNodeProto.Way wayProto = this.makeWay(way);

            for (OutputStream os : streams)
            {
                wayProto.writeDelimitedTo(os);
            }

            ++numPersistedWays;
        }

        /**
         * Creates the cached version of a way.
         *
         * @param way the way to cache.
         *
         * @return the cache representation of the way.
         */
        protected OSMNodeProto.Way makeWay(Way way)
        {
            OSMNodeProto.Way.Builder wayBuilder = OSMNodeProto.Way.newBuilder();

            wayBuilder.setId(Long.toString(way.getId()));

            for (WayNode wayNode : way.getWayNodes())
            {
                OSMNodeProto.Location.Builder positionBuilder = OSMNodeProto.Location.newBuilder();

                NodeLocation node = nodeMap.get(Long.toString(wayNode.getNodeId()));

                positionBuilder.setLat(node.lat);
                positionBuilder.setLon(node.lon);

                wayBuilder.addLocations(positionBuilder.build());
            }

            for (Tag tag : way.getTags())
            {
                OSMNodeProto.Tag.Builder tagBuilder = OSMNodeProto.Tag.newBuilder();
                tagBuilder.setKey(tag.getKey());
                tagBuilder.setValue(tag.getValue());
                wayBuilder.addTags(tagBuilder);
            }

            return wayBuilder.build();
        }

        /**
         * Returns the output stream associated with a specified sector. If one does not exist it is created.
         *
         * @param row        the sector row.
         * @param col        the sector column.
         * @param entityType the entity type, either "N" for node or "W" for way.
         *
         * @return the output stream for the sector.
         *
         * @throws IOException
         */
        protected OutputStream getOutputStream(int row, int col, String entityType) throws IOException
        {
            OutputStream os = this.outputStreams.get(new TileKey(row, col, entityType));

            return os != null ? os : this.addOutputStream(row, col, entityType);
        }

        /**
         * Creates an output stream for a sector.
         *
         * @param row        the sector row.
         * @param col        the sector column.
         * @param entityType the entity type, either "N" for node or "W" for way.
         *
         * @return the new output stream.
         *
         * @throws IOException
         */
        protected OutputStream addOutputStream(int row, int col, String entityType) throws IOException
        {
            ZipOutputStream zos = new ZipOutputStream(new FileOutputStream(this.makeFilePath(row, col, entityType)));
            zos.putNextEntry(new ZipEntry("Nodes"));

            this.outputStreams.put(new TileKey(row, col, entityType), zos);

            return zos;
        }

        /**
         * Forms the full path to a sector's cache directory.
         *
         * @param row        the sector row.
         * @param col        the sector column.
         * @param entityType the entity type, either "N" for node or "W" for way.
         *
         * @return the full cache path for the sector.
         */
        protected String makeFilePath(int row, int col, String entityType)
        {
            String pathToParentDir = this.cachePath + "/" + row;
            File dir = new File(pathToParentDir);
            if (!dir.exists())
                dir.mkdirs();

            return pathToParentDir + "/" + entityType + "." + row + "." + col + ".zip";
        }

        /**
         * Computes the row of the sector containing a specified location.
         *
         * @param location the location.
         *
         * @return the row of the sector in this level containing the specified location.
         */
        protected int computeRow(LatLon location)
        {
            return Tile.computeRow(this.sectorDelta.getLatitude(), location.getLatitude(), Angle.NEG90);
        }

        /**
         * Computes the column of the sector containing a specified location.
         *
         * @param location the location.
         *
         * @return the column of the sector in this level containing the specified location.
         */
        protected int computeCol(LatLon location)
        {
            return Tile.computeColumn(this.sectorDelta.getLongitude(), location.getLongitude(),
                Angle.NEG180);
        }

        /**
         * This class is used as a map key for the output stream map. Each key instance corresponds to one sector in a
         * level.
         */
        protected class TileKey
        {
            /** The sector row. */
            protected int row;
            /** The sector column. */
            protected int col;
            /** The entity type, either "N" for node or "W" for way. */
            protected String entityType;

            /**
             * Constructs a key for a specified row, column and entity type.
             *
             * @param row        the sector row.
             * @param col        the sector column.
             * @param entityType the entity type, either "N" for node or "W" for way.
             */
            public TileKey(int row, int col, String entityType)
            {
                this.row = row;
                this.col = col;
                this.entityType = entityType;
            }

            @Override
            public boolean equals(Object o)
            {
                if (this == o)
                    return true;
                if (o == null || getClass() != o.getClass())
                    return false;

                TileKey key = (TileKey) o;

                if (col != key.col)
                    return false;
                if (row != key.row)
                    return false;
                if (entityType != null ? !entityType.equals(key.entityType) : key.entityType != null)
                    return false;

                return true;
            }

            @Override
            public int hashCode()
            {
                int result = row;
                result = 31 * result + col;
                result = 31 * result + (entityType != null ? entityType.hashCode() : 0);
                return result;
            }
        }
    }
}
