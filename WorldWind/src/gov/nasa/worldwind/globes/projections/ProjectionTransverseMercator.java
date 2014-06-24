/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.globes.projections;

import gov.nasa.worldwind.Configuration;
import gov.nasa.worldwind.avlist.AVKey;
import gov.nasa.worldwind.geom.*;
import gov.nasa.worldwind.geom.coords.TMCoord;
import gov.nasa.worldwind.globes.*;
import gov.nasa.worldwind.util.Logging;

/**
 * Provides a Transverse Mercator ellipsoidal projection using the WGS84 ellipsoid. The projection's central meridian
 * may be specified and defaults to the Prime Meridian (0 longitude). By default, the projection computes values for 30
 * degrees either side of the central meridian. This may be changed via the {@link
 * #setWidth(gov.nasa.worldwind.geom.Angle)} method, but the projection may fail for widths larger than that.
 *
 * @author tag
 * @version $Id$
 */
public class ProjectionTransverseMercator implements GeographicProjection
{
    protected Angle width = Angle.fromDegrees(30);
    protected Angle centralMeridian = Angle.fromDegrees(Configuration.getDoubleValue(AVKey.INITIAL_LONGITUDE));

    /** Creates a projection whose central meridian is the Prime Meridian. */
    public ProjectionTransverseMercator()
    {
    }

    /**
     * Creates a projection with a specified central meridian.
     *
     * @param centralMeridian The projection's central meridian.
     */
    public ProjectionTransverseMercator(Angle centralMeridian)
    {
        if (centralMeridian == null)
        {
            String message = Logging.getMessage("nullValue.CentralMeridianIsNull");
            Logging.logger().severe(message);
            throw new IllegalArgumentException(message);
        }

        this.centralMeridian = centralMeridian;
    }

    @Override
    public String getName()
    {
        return "Transverse Mercator";
    }

    /**
     * Indicates this projection's central meridian.
     *
     * @return This projection's central meridian.
     */
    public Angle getCentralMeridian()
    {
        return centralMeridian;
    }

    /**
     * Specifies this projections central meridian.
     *
     * @param centralMeridian This projection's central meridian.
     */
    public void setCentralMeridian(Angle centralMeridian)
    {
        this.centralMeridian = centralMeridian;
    }

    /**
     * Indicates the region in which positions are mapped. The default is 30 degrees either side of this projection's
     * central meridian.
     *
     * @return This projection's width.
     */
    public Angle getWidth()
    {
        return width;
    }

    /**
     * Specifies the region in which positions are mapped. The default is 30 degrees either side of this projection's
     * central meridian.
     *
     * @param width This projection's width.
     */
    public void setWidth(Angle width)
    {
        if (width == null)
        {
            String message = Logging.getMessage("nullValue.AngleIsNull");
            Logging.logger().severe(message);
            throw new IllegalArgumentException(message);
        }

        this.width = width;
    }

    protected double getScale()
    {
        return 1.0;
    }

    @Override
    public Vec4 geographicToCartesian(Globe globe, Angle latitude, Angle longitude, double metersElevation, Vec4 offset)
    {
        if (latitude.degrees > 86)
            latitude = Angle.fromDegrees(86);
        else if (latitude.degrees < -82)
            latitude = Angle.fromDegrees(-82);

        if (longitude.degrees > this.centralMeridian.degrees + this.width.degrees)
            longitude = Angle.fromDegrees(this.centralMeridian.degrees + this.width.degrees);
        else if (longitude.degrees < this.centralMeridian.degrees - this.width.degrees)
            longitude = Angle.fromDegrees(this.centralMeridian.degrees - this.width.degrees);

        TMCoord tm = TMCoord.fromLatLon(latitude, longitude,
            globe, null, null, Angle.ZERO, this.centralMeridian,
            0, 0, this.getScale());

        return new Vec4(tm.getEasting(), tm.getNorthing(), metersElevation);
    }

    @Override
    public Position cartesianToGeographic(Globe globe, Vec4 cart, Vec4 offset)
    {
        TMCoord tm = TMCoord.fromTM(cart.x, cart.y, globe, Angle.ZERO, this.centralMeridian, 0, 0, this.getScale());

        return new Position(tm.getLatitude(), tm.getLongitude(), cart.z);
    }

    @Override
    public boolean isContinuous()
    {
        return false;
    }

    @Override
    public boolean equals(Object o)
    {
        if (this == o)
            return true;
        if (o == null || getClass() != o.getClass())
            return false;

        ProjectionTransverseMercator that = (ProjectionTransverseMercator) o;

        if (centralMeridian != null ? !centralMeridian.equals(that.centralMeridian) : that.centralMeridian != null)
            return false;
        if (width != null ? !width.equals(that.width) : that.width != null)
            return false;

        return true;
    }

    @Override
    public int hashCode()
    {
        int result = width != null ? width.hashCode() : 0;
        result = 31 * result + (centralMeridian != null ? centralMeridian.hashCode() : 0);
        return result;
    }
}
