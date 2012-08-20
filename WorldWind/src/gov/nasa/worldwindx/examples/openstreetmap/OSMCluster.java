/*
 * Copyright (C) 2012 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwindx.examples.openstreetmap;

import gov.nasa.worldwind.geom.*;
import gov.nasa.worldwind.util.*;

/**
 * A cluster represents one tile -- a sector of data -- for {@link OSMAbstractLayer}.
 *
 * @author tag
 * @version $Id$
 */
public class OSMCluster
{
    protected String clusterName;
    protected String fileCachePath;
    protected LatLon tileDelta;
    protected double minDisplayDistance;
    protected double maxDisplayDistance;
    protected int numColumns;
    private final AbsentResourceList absentTiles = new AbsentResourceList(1, Integer.MAX_VALUE);

    public OSMCluster(String clusterName, String fileCachePath, LatLon tileDelta, double minDisplayDistance,
        double maxDisplayDistance)
    {
        this.clusterName = clusterName;
        this.fileCachePath = fileCachePath;
        this.tileDelta = tileDelta;
        this.minDisplayDistance = minDisplayDistance;
        this.maxDisplayDistance = maxDisplayDistance;

        this.numColumns = this.numColumnsInLevel();
    }

    protected int numColumnsInLevel()
    {
        int firstCol = Tile.computeColumn(this.tileDelta.getLongitude(), Angle.NEG180, Angle.NEG180);
        int lastCol = Tile.computeColumn(this.tileDelta.getLongitude(),
            Angle.POS180.subtract(this.tileDelta.getLongitude()), Angle.NEG180);

        return lastCol - firstCol + 1;
    }

    public String getClusterName()
    {
        return clusterName;
    }

    public String getFileCachePath()
    {
        return fileCachePath;
    }

    public LatLon getTileDelta()
    {
        return tileDelta;
    }

    public double getMinDisplayDistance()
    {
        return minDisplayDistance;
    }

    public double getMaxDisplayDistance()
    {
        return maxDisplayDistance;
    }

    public long getTileNumber(int row, int column)
    {
        return row * this.numColumns + column;
    }

    public synchronized final void markResourceAbsent(long tileNumber)
    {
        this.absentTiles.markResourceAbsent(tileNumber);
    }

    public synchronized final boolean isResourceAbsent(long resourceNumber)
    {
        return this.absentTiles.isResourceAbsent(resourceNumber);
    }

    public synchronized final void unmarkResourceAbsent(long tileNumber)
    {
        this.absentTiles.unmarkResourceAbsent(tileNumber);
    }

    @Override
    public boolean equals(Object o)
    {
        if (this == o)
            return true;
        if (o == null || getClass() != o.getClass())
            return false;

        OSMCluster that = (OSMCluster) o;

        if (Double.compare(that.maxDisplayDistance, maxDisplayDistance) != 0)
            return false;
        if (Double.compare(that.minDisplayDistance, minDisplayDistance) != 0)
            return false;
        if (numColumns != that.numColumns)
            return false;
        if (clusterName != null ? !clusterName.equals(that.clusterName) : that.clusterName != null)
            return false;
        if (fileCachePath != null ? !fileCachePath.equals(that.fileCachePath) : that.fileCachePath != null)
            return false;
        if (tileDelta != null ? !tileDelta.equals(that.tileDelta) : that.tileDelta != null)
            return false;

        return true;
    }

    @Override
    public int hashCode()
    {
        int result;
        long temp;
        result = clusterName != null ? clusterName.hashCode() : 0;
        result = 31 * result + (fileCachePath != null ? fileCachePath.hashCode() : 0);
        result = 31 * result + (tileDelta != null ? tileDelta.hashCode() : 0);
        temp = minDisplayDistance != +0.0d ? Double.doubleToLongBits(minDisplayDistance) : 0L;
        result = 31 * result + (int) (temp ^ (temp >>> 32));
        temp = maxDisplayDistance != +0.0d ? Double.doubleToLongBits(maxDisplayDistance) : 0L;
        result = 31 * result + (int) (temp ^ (temp >>> 32));
        result = 31 * result + numColumns;
        return result;
    }
}
