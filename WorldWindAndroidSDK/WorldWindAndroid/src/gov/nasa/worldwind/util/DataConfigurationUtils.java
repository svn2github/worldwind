/*
 * Copyright (C) 2012 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */
package gov.nasa.worldwind.util;

import gov.nasa.worldwind.avlist.*;
import gov.nasa.worldwind.geom.*;
import gov.nasa.worldwind.ogc.OGCConstants;
import gov.nasa.worldwind.wms.CapabilitiesRequest;
import org.w3c.dom.Element;

import javax.xml.xpath.XPath;
import java.net.*;
import java.util.concurrent.*;

/**
 * A collection of static methods useful for opening, reading, and otherwise working with World Wind data configuration
 * documents.
 *
 * @author dcollins
 * @version $Id$
 */
// TODO: isWWDotNetLayerSetConfigEvent(XMLEvent event) not yet implemented on Android because javax.xml.stream package
// TODO: is not available in the Android SDK.
public class DataConfigurationUtils
{
    protected static final String DATE_TIME_PATTERN = "dd MM yyyy HH:mm:ss z";

    /**
     * Convenience method to create a {@link java.util.concurrent.ScheduledExecutorService} which can be used by World
     * Wind components to schedule periodic resource checks. The returned ExecutorService is backed by a single daemon
     * thread with minimum priority.
     *
     * @param threadName the String name for the ExecutorService's thread, may be <code>null</code>.
     * @return a new ScheduledExecutorService appropriate for scheduling periodic resource checks.
     */
    public static ScheduledExecutorService createResourceRetrievalService(final String threadName)
    {
        ThreadFactory threadFactory = new ThreadFactory()
        {
            public Thread newThread(Runnable r)
            {
                Thread thread = new Thread(r);
                thread.setDaemon(true);
                thread.setPriority(Thread.MIN_PRIORITY);

                if (threadName != null)
                {
                    thread.setName(threadName);
                }

                return thread;
            }
        };

        return Executors.newSingleThreadScheduledExecutor(threadFactory);
    }

    //**************************************************************//
    //********************  WMS Common Configuration  **************//
    //**************************************************************//

    /**
     * Parses WMS layer parameters from the XML configuration document starting at domElement. This writes output as
     * key-value pairs to params. If a parameter from the XML document already exists in params, that parameter is
     * ignored. Supported key and parameter names are: <table> <th><td>Parameter</td><td>Element
     * Path</td><td>Type</td></th> <tr><td>{@link AVKey#WMS_VERSION}</td><td>Service/@version</td><td>String</td></tr>
     * <tr><td>{@link AVKey#LAYER_NAMES}</td><td>Service/LayerNames</td><td>String</td></tr> <tr><td>{@link
     * AVKey#STYLE_NAMES}</td><td>Service/StyleNames</td><td>String</td></tr> <tr><td>{@link
     * AVKey#GET_MAP_URL}</td><td>Service/GetMapURL</td><td>String</td></tr> <tr><td>{@link
     * AVKey#GET_CAPABILITIES_URL}</td><td>Service/GetCapabilitiesURL</td><td>String</td></tr> <tr><td>{@link
     * AVKey#SERVICE}</td><td>AVKey#GET_MAP_URL</td><td>String</td></tr> <tr><td>{@link
     * AVKey#DATASET_NAME}</td><td>AVKey.LAYER_NAMES</td><td>String</td></tr> </table>
     *
     * @param domElement the XML document root to parse for WMS layer parameters.
     * @param params     the output key-value pairs which receive the WMS layer parameters. A null reference is
     *                   permitted.
     * @return a reference to params, or a new AVList if params is null.
     * @throws IllegalArgumentException if the document is null.
     */
    public static AVList getWMSLayerConfigParams(Element domElement, AVList params)
    {
        if (domElement == null)
        {
            String message = Logging.getMessage("nullValue.DocumentIsNull");
            Logging.error(message);
            throw new IllegalArgumentException(message);
        }

        if (params == null)
        {
            params = new AVListImpl();
        }

        XPath xpath = WWXML.makeXPath();

        // Need to determine these for URLBuilder construction.
        WWXML.checkAndSetStringParam(domElement, params, AVKey.WMS_VERSION, "Service/@version", xpath);
        WWXML.checkAndSetStringParam(domElement, params, AVKey.LAYER_NAMES, "Service/LayerNames", xpath);
        WWXML.checkAndSetStringParam(domElement, params, AVKey.STYLE_NAMES, "Service/StyleNames", xpath);
        WWXML.checkAndSetStringParam(domElement, params, AVKey.GET_MAP_URL, "Service/GetMapURL", xpath);
        WWXML.checkAndSetStringParam(domElement, params, AVKey.GET_CAPABILITIES_URL, "Service/GetCapabilitiesURL",
                xpath);

        params.setValue(AVKey.SERVICE, params.getValue(AVKey.GET_MAP_URL));
        String serviceURL = params.getStringValue(AVKey.SERVICE);
        if (serviceURL != null)
        {
            params.setValue(AVKey.SERVICE, WWXML.fixGetMapString(serviceURL));
        }

        // The dataset name is the layer-names string for WMS elevation models
        String layerNames = params.getStringValue(AVKey.LAYER_NAMES);
        if (layerNames != null)
        {
            params.setValue(AVKey.DATASET_NAME, layerNames);
        }

        return params;
    }

      // TODO Implement on Android
//    public static AVList getWMSLayerConfigParams(WMSCapabilities caps, String[] formatOrderPreference, AVList params)
//    {
//        return null;
//    }

    /**
     * Convenience method to get the OGC GetCapabilities URL from a specified parameter list. If all the necessary
     * parameters are available, this returns the GetCapabilities URL. Otherwise this returns null.
     *
     * @param params parameter list to get the GetCapabilities parameters from.
     * @return a OGC GetCapabilities URL, or null if the necessary parameters are not available.
     * @throws IllegalArgumentException if the parameter list is null.
     */
    public static URL getOGCGetCapabilitiesURL(AVList params)
    {
        if (params == null)
        {
            String message = Logging.getMessage("nullValue.ParametersIsNull");
            Logging.error(message);
            throw new IllegalArgumentException(message);
        }

        String uri = params.getStringValue(AVKey.GET_CAPABILITIES_URL);
        if (uri == null || uri.length() == 0)
        {
            return null;
        }

        String service = params.getStringValue(AVKey.SERVICE_NAME);
        if (service == null || service.length() == 0)
        {
            return null;
        }

        if (service.equals(OGCConstants.WMS_SERVICE_NAME))
        {
            service = "WMS";
        }

        try
        {
            CapabilitiesRequest request = new CapabilitiesRequest(new URI(uri), service);
            return request.getUri().toURL();
        }
        catch (URISyntaxException e)
        {
            String message = Logging.getMessage("generic.URIInvalid", uri);
            Logging.error(message, e);
        }
        catch (MalformedURLException e)
        {
            String message = Logging.getMessage("generic.URIInvalid", uri);
            Logging.error(message, e);
        }

        return null;
    }

    //**************************************************************//
    //********************  LevelSet Common Configuration  *********//
    //**************************************************************//

    /**
     * Parses LevelSet configuration parameters from the specified DOM document. This writes output as key-value pairs
     * to params. If a parameter from the XML document already exists in params, that parameter is ignored. Supported
     * key and parameter names are: <table> <th><td>Parameter</td><td>Element path</td><td>Type</td></th> <tr><td>{@link
     * gov.nasa.worldwind.avlist.AVKey#DATASET_NAME}</td><td>DatasetName</td><td>String</td></tr> <tr><td>{@link
     * gov.nasa.worldwind.avlist.AVKey#DATA_CACHE_NAME}</td><td>DataCacheName</td><td>String</td></tr> <tr><td>{@link
     * gov.nasa.worldwind.avlist.AVKey#SERVICE}</td><td>Service/URL</td><td>String</td></tr> <tr><td>{@link
     * gov.nasa.worldwind.avlist.AVKey#EXPIRY_TIME}</td><td>ExpiryTime</td><td>Long</td></tr> <tr><td>{@link
     * gov.nasa.worldwind.avlist.AVKey#EXPIRY_TIME}</td><td>LastUpdate</td><td>Long</td></tr> <tr><td>{@link
     * gov.nasa.worldwind.avlist.AVKey#FORMAT_SUFFIX}</td><td>FormatSuffix</td><td>String</td></tr> <tr><td>{@link
     * gov.nasa.worldwind.avlist.AVKey#NUM_LEVELS}</td><td>NumLevels/@count</td><td>Integer</td></tr> <tr><td>{@link
     * gov.nasa.worldwind.avlist.AVKey#NUM_EMPTY_LEVELS}</td><td>NumLevels/@numEmpty</td><td>Integer</td></tr>
     * <tr><td>{@link gov.nasa.worldwind.avlist.AVKey#INACTIVE_LEVELS}</td><td>NumLevels/@inactive</td><td>String</td></tr>
     * <tr><td>{@link gov.nasa.worldwind.avlist.AVKey#SECTOR}</td><td>Sector</td><td>{@link
     * gov.nasa.worldwind.geom.Sector}</td></tr> <tr><td>{@link gov.nasa.worldwind.avlist.AVKey#SECTOR_RESOLUTION_LIMITS}</td><td>SectorResolutionLimit</td>
     * <td>{@link LevelSet.SectorResolution}</td></tr> <tr><td>{@link gov.nasa.worldwind.avlist.AVKey#TILE_ORIGIN}</td><td>TileOrigin/LatLon</td><td>{@link
     * gov.nasa.worldwind.geom.LatLon}</td></tr> <tr><td>{@link gov.nasa.worldwind.avlist.AVKey#TILE_WIDTH}</td><td>TileSize/Dimension/@width</td><td>Integer</td></tr>
     * <tr><td>{@link gov.nasa.worldwind.avlist.AVKey#TILE_HEIGHT}</td><td>TileSize/Dimension/@height</td><td>Integer</td></tr>
     * <tr><td>{@link gov.nasa.worldwind.avlist.AVKey#LEVEL_ZERO_TILE_DELTA}</td><td>LastUpdate</td><td>LatLon</td></tr>
     * <tr><td>{@link gov.nasa.worldwind.avlist.AVKey#MAX_ABSENT_TILE_ATTEMPTS}</td><td>AbsentTiles/MaxAttempts</td><td>Integer</td></tr>
     * <tr><td>{@link gov.nasa.worldwind.avlist.AVKey#MIN_ABSENT_TILE_CHECK_INTERVAL}</td><td>AbsentTiles/MinCheckInterval/Time</td><td>Integer
     * milliseconds</td></tr> </table>
     *
     * @param domElement the XML document root to parse for LevelSet configuration parameters.
     * @param params     the output key-value pairs which receive the LevelSet configuration parameters. A null
     *                   reference is permitted.
     * @return a reference to params, or a new AVList if params is null.
     * @throws IllegalArgumentException if the document is null.
     */
    public static AVList getLevelSetConfigParams(Element domElement, AVList params)
    {
        if (domElement == null)
        {
            String message = Logging.getMessage("nullValue.DocumentIsNull");
            Logging.error(message);
            throw new IllegalArgumentException(message);
        }

        if (params == null)
        {
            params = new AVListImpl();
        }

        XPath xpath = WWXML.makeXPath();

        // Title and cache name properties.
        WWXML.checkAndSetStringParam(domElement, params, AVKey.DATASET_NAME, "DatasetName", xpath);
        WWXML.checkAndSetStringParam(domElement, params, AVKey.DATA_CACHE_NAME, "DataCacheName", xpath);

        // Service properties.
        WWXML.checkAndSetStringParam(domElement, params, AVKey.SERVICE, "Service/GetMapURL", xpath); // TODO changed from Service/URL
        WWXML.checkAndSetStringParam(domElement, params, AVKey.SERVICE_NAME, "Service/@serviceName", xpath);

        WWXML.checkAndSetLongParam(domElement, params, AVKey.EXPIRY_TIME, "ExpiryTime", xpath);
        WWXML.checkAndSetDateTimeParam(domElement, params, AVKey.EXPIRY_TIME, "LastUpdate", DATE_TIME_PATTERN, xpath);

        // Image format properties.
        WWXML.checkAndSetStringParam(domElement, params, AVKey.FORMAT_SUFFIX, "FormatSuffix", xpath);

        // Tile structure properties.
        WWXML.checkAndSetIntegerParam(domElement, params, AVKey.NUM_LEVELS, "NumLevels/@count", xpath);
        WWXML.checkAndSetIntegerParam(domElement, params, AVKey.NUM_EMPTY_LEVELS, "NumLevels/@numEmpty", xpath);
        WWXML.checkAndSetStringParam(domElement, params, AVKey.INACTIVE_LEVELS, "NumLevels/@inactive", xpath);
        WWXML.checkAndSetSectorParam(domElement, params, AVKey.SECTOR, "Sector", xpath);
        WWXML.checkAndSetSectorResolutionParam(domElement, params, AVKey.SECTOR_RESOLUTION_LIMITS,
                "SectorResolutionLimit", xpath);
        WWXML.checkAndSetLatLonParam(domElement, params, AVKey.TILE_ORIGIN, "TileOrigin/LatLon", xpath);
        WWXML.checkAndSetIntegerParam(domElement, params, AVKey.TILE_WIDTH, "TileSize/Dimension/@width", xpath);
        WWXML.checkAndSetIntegerParam(domElement, params, AVKey.TILE_HEIGHT, "TileSize/Dimension/@height", xpath);
        WWXML.checkAndSetLatLonParam(domElement, params, AVKey.LEVEL_ZERO_TILE_DELTA, "LevelZeroTileDelta/LatLon",
                xpath);

        // Retrieval properties.
        WWXML.checkAndSetIntegerParam(domElement, params, AVKey.MAX_ABSENT_TILE_ATTEMPTS,
                "AbsentTiles/MaxAttempts", xpath);
        WWXML.checkAndSetTimeParamAsInteger(domElement, params, AVKey.MIN_ABSENT_TILE_CHECK_INTERVAL,
                "AbsentTiles/MinCheckInterval/Time", xpath);

        return params;
    }

    /**
     * Gathers LevelSet configuration parameters from a specified LevelSet reference. This writes output as key-value
     * pairs params. If a parameter from the XML document already exists in params, that parameter is ignored. Supported
     * key and parameter names are: <table> <th><td>Parameter</td><td>Element Path</td><td>Type</td></th> <tr><td>{@link
     * gov.nasa.worldwind.avlist.AVKey#DATASET_NAME}</td><td>First Level's dataset</td><td>String</td></tr>
     * <tr><td>{@link gov.nasa.worldwind.avlist.AVKey#DATA_CACHE_NAME}</td><td>First Level's
     * cacheName</td><td>String</td></tr> <tr><td>{@link gov.nasa.worldwind.avlist.AVKey#SERVICE}</td><td>First Level's
     * service</td><td>String</td></tr> <tr><td>{@link gov.nasa.worldwind.avlist.AVKey#EXPIRY_TIME}</td><td>First
     * Level's expiryTime</td><td>Long</td></tr> <tr><td>{@link gov.nasa.worldwind.avlist.AVKey#FORMAT_SUFFIX}</td><td>FirstLevel's
     * formatSuffix</td><td>String</td></tr> <tr><td>{@link gov.nasa.worldwind.avlist.AVKey#NUM_LEVELS}</td><td>numLevels</td><td>Integer</td></tr>
     * <tr><td>{@link gov.nasa.worldwind.avlist.AVKey#NUM_EMPTY_LEVELS}</td><td>1 + index of first non-empty
     * Level</td><td>Integer</td></tr> <tr><td>{@link gov.nasa.worldwind.avlist.AVKey#INACTIVE_LEVELS}</td><td>Comma
     * delimited string of Level numbers</td><td>String</td></tr> <tr><td>{@link gov.nasa.worldwind.avlist.AVKey#SECTOR}</td><td>sector</td><td>{@link
     * gov.nasa.worldwind.geom.Sector}</td></tr> <tr><td>{@link gov.nasa.worldwind.avlist.AVKey#SECTOR_RESOLUTION_LIMITS}</td><td>sectorLevelLimits</td>
     * <td>{@link LevelSet.SectorResolution}</td></tr> <tr><td>{@link gov.nasa.worldwind.avlist.AVKey#TILE_ORIGIN}</td><td>tileOrigin</td><td>{@link
     * gov.nasa.worldwind.geom.LatLon}</td></tr> <tr><td>{@link gov.nasa.worldwind.avlist.AVKey#TILE_WIDTH}</td><td>First
     * Level's tileWidth<td><td>Integer</td></tr> <tr><td>{@link gov.nasa.worldwind.avlist.AVKey#TILE_HEIGHT}</td><td>First
     * Level's tileHeight</td><td>Integer</td></tr> <tr><td>{@link gov.nasa.worldwind.avlist.AVKey#LEVEL_ZERO_TILE_DELTA}</td><td>levelZeroTileDelta</td><td>LatLon</td></tr>
     * </table>
     *
     * @param levelSet the LevelSet reference to gather configuration parameters from.
     * @param params   the output key-value pairs which receive the LevelSet configuration parameters. A null reference
     *                 is permitted.
     * @return a reference to params, or a new AVList if params is null.
     * @throws IllegalArgumentException if the document is null.
     */
    public static AVList getLevelSetConfigParams(LevelSet levelSet, AVList params)
    {
        if (levelSet == null)
        {
            String message = Logging.getMessage("nullValue.LevelSetIsNull");
            Logging.error(message);
            throw new IllegalArgumentException(message);
        }

        if (params == null)
        {
            params = new AVListImpl();
        }

        Level firstLevel = levelSet.getFirstLevel();

        // Title and cache name properties.
        String s = params.getStringValue(AVKey.DATASET_NAME);
        if (s == null || s.length() == 0)
        {
            s = firstLevel.getDataset();
            if (s != null && s.length() > 0)
            {
                params.setValue(AVKey.DATASET_NAME, s);
            }
        }

        s = params.getStringValue(AVKey.DATA_CACHE_NAME);
        if (s == null || s.length() == 0)
        {
            s = firstLevel.getCacheName();
            if (s != null && s.length() > 0)
            {
                params.setValue(AVKey.DATA_CACHE_NAME, s);
            }
        }

        // Service properties.
        s = params.getStringValue(AVKey.SERVICE);
        if (s == null || s.length() == 0)
        {
            s = firstLevel.getService();
            if (s != null && s.length() > 0)
            {
                params.setValue(AVKey.SERVICE, s);
            }
        }

        Object o = params.getValue(AVKey.EXPIRY_TIME);
        if (o == null)
        {
            // If the expiry time is zero or negative, then treat it as an uninitialized value.
            long l = firstLevel.getExpiryTime();
            if (l > 0)
            {
                params.setValue(AVKey.EXPIRY_TIME, l);
            }
        }

        // Image format properties.
        s = params.getStringValue(AVKey.FORMAT_SUFFIX);
        if (s == null || s.length() == 0)
        {
            s = firstLevel.getFormatSuffix();
            if (s != null && s.length() > 0)
            {
                params.setValue(AVKey.FORMAT_SUFFIX, s);
            }
        }

        // Tile structure properties.
        o = params.getValue(AVKey.NUM_LEVELS);
        if (o == null)
        {
            params.setValue(AVKey.NUM_LEVELS, levelSet.getNumLevels());
        }

        o = params.getValue(AVKey.NUM_EMPTY_LEVELS);
        if (o == null)
        {
            params.setValue(AVKey.NUM_EMPTY_LEVELS, getNumEmptyLevels(levelSet));
        }

        s = params.getStringValue(AVKey.INACTIVE_LEVELS);
        if (s == null || s.length() == 0)
        {
            s = getInactiveLevels(levelSet);
            if (s != null && s.length() > 0)
            {
                params.setValue(AVKey.INACTIVE_LEVELS, s);
            }
        }

        o = params.getValue(AVKey.SECTOR);
        if (o == null)
        {
            Sector sector = levelSet.getSector();
            if (sector != null)
            {
                params.setValue(AVKey.SECTOR, sector);
            }
        }

        o = params.getValue(AVKey.SECTOR_RESOLUTION_LIMITS);
        if (o == null)
        {
            LevelSet.SectorResolution[] srs = levelSet.getSectorLevelLimits();
            if (srs != null && srs.length > 0)
            {
                params.setValue(AVKey.SECTOR_RESOLUTION_LIMITS, srs);
            }
        }

        o = params.getValue(AVKey.TILE_ORIGIN);
        if (o == null)
        {
            LatLon ll = levelSet.getTileOrigin();
            if (ll != null)
            {
                params.setValue(AVKey.TILE_ORIGIN, ll);
            }
        }

        o = params.getValue(AVKey.TILE_WIDTH);
        if (o == null)
        {
            params.setValue(AVKey.TILE_WIDTH, firstLevel.getTileWidth());
        }

        o = params.getValue(AVKey.TILE_HEIGHT);
        if (o == null)
        {
            params.setValue(AVKey.TILE_HEIGHT, firstLevel.getTileHeight());
        }

        o = params.getValue(AVKey.LEVEL_ZERO_TILE_DELTA);
        if (o == null)
        {
            LatLon ll = levelSet.getLevelZeroTileDelta();
            if (ll != null)
            {
                params.setValue(AVKey.LEVEL_ZERO_TILE_DELTA, ll);
            }
        }

        // Note: retrieval properties MAX_ABSENT_TILE_ATTEMPTS and MIN_ABSENT_TILE_CHECK_INTERVAL are initialized
        // through the AVList constructor on LevelSet and Level. Rather than expose those properties in Level, we rely
        // on the caller to gather those properties via the AVList used to construct the LevelSet.

        return params;
    }

    protected static int getNumEmptyLevels(LevelSet levelSet)
    {
        int i;
        for (i = 0; i < levelSet.getNumLevels(); i++)
        {
            if (!levelSet.getLevel(i).isEmpty())
            {
                break;
            }
        }

        return i;
    }

    protected static String getInactiveLevels(LevelSet levelSet)
    {
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < levelSet.getNumLevels(); i++)
        {
            if (!levelSet.getLevel(i).isActive())
            {
                if (sb.length() > 0)
                {
                    sb.append(",");
                }
                sb.append(i);
            }
        }

        return (sb.length() > 0) ? sb.toString() : null;
    }
}
