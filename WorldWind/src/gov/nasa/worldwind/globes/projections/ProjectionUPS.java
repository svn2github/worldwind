/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.globes.projections;

import gov.nasa.worldwind.avlist.AVKey;
import gov.nasa.worldwind.geom.*;
import gov.nasa.worldwind.globes.Globe;
import gov.nasa.worldwind.util.*;

/**
 * Provides a Universal Polar Stereographic projection using the WGS84 ellipsoid and centered on a specified pole.
 *
 * @author tag
 * @version $Id$
 */
public class ProjectionUPS extends AbstractGeographicProjection
{
    protected static final int NORTH = 0;
    protected static final int SOUTH = 1;

    protected int pole = NORTH;

    /**
     * Creates a projection centered on the North pole.
     */
    public ProjectionUPS()
    {
        super(Sector.fromDegrees(0, 90, -180, 180));
    }

    /**
     * Creates a projection centered on the specified pole, which can be either {@link AVKey#NORTH} or {@link
     * AVKey#SOUTH}.
     *
     * @param pole The pole to center on, either {@link AVKey#NORTH} or {@link AVKey#SOUTH}.
     *
     * @throws IllegalArgumentException if the specified pole is null.
     */
    public ProjectionUPS(String pole)
    {
        super(Sector.fromDegrees(0, pole != null && pole.equals(AVKey.SOUTH) ? -90 : 90, -180, 180));

        if (pole == null)
        {
            String message = Logging.getMessage("nullValue.HemisphereIsNull");
            Logging.logger().severe(message);
            throw new IllegalArgumentException(message);
        }

        this.pole = pole.equals(AVKey.SOUTH) ? SOUTH : NORTH;
    }

    @Override
    public String getName()
    {
        return (this.pole == SOUTH ? "South " : "North ") + "Universal Polar Stereographic";
    }

    @Override
    public boolean isContinuous()
    {
        return false;
    }

    @Override
    public Vec4 geographicToCartesian(Globe globe, Angle latitude, Angle longitude, double metersElevation, Vec4 offset)
    {
        // Formulas taken from "Map Projections -- A Working Manual", Snyder, USGS paper 1395, pg. 161.

        if ((this.pole == NORTH && latitude.degrees == 90) || (this.pole == SOUTH && latitude.degrees == -90))
            return new Vec4(0, 0, metersElevation);

        double lat = latitude.radians * (this.pole == NORTH ? 1 : -1);
        double lon = longitude.radians * (this.pole == NORTH ? 1 : -1);

        if (this.pole == NORTH && lat < 0)
            lat = 0;
        else if (this.pole == SOUTH && -lat < 0)
            lat = 0;

        double k0 = 0.994; // standard UPS scale factor -- see above reference pg.157, pp 2.
        double ecc = Math.sqrt(globe.getEccentricitySquared());
        double sp = Math.sin(lat);

        double t = Math.sqrt(((1 - sp) / (1 + sp)) * Math.pow((1 + ecc * sp) / (1 - ecc * sp), ecc));
        double s = Math.sqrt(Math.pow(1 + ecc, 1 + ecc) * Math.pow(1 - ecc, 1 - ecc));
        double r = 2 * globe.getEquatorialRadius() * k0 * t / s;

        double x = r * Math.sin(lon);// * (this.pole == NORTH ? 1 : -1);
        double y = -r * Math.cos(lon);// * (this.pole == NORTH ? 1 : -1);

        return new Vec4(x, y, metersElevation);
//        return new Vec4(r * Math.sin(lon), -r * Math.cos(lon), metersElevation);
    }

    @Override
    public void geographicToCartesian(Globe globe, Sector sector, int numLat, int numLon, double[] metersElevation,
        Vec4 offset, Vec4[] out)
    {
        double minLat = sector.getMinLatitude().radians;
        double maxLat = sector.getMaxLatitude().radians;
        double minLon = sector.getMinLongitude().radians;
        double maxLon = sector.getMaxLongitude().radians;
        double deltaLat = (maxLat - minLat) / (numLat > 1 ? numLat - 1 : 1);
        double deltaLon = (maxLon - minLon) / (numLon > 1 ? numLon - 1 : 1);
        double minLatLimit = this.getProjectionLimits().getMinLatitude().radians;
        double maxLatLimit = this.getProjectionLimits().getMaxLatitude().radians;
        double minLonLimit = this.getProjectionLimits().getMinLongitude().radians;
        double maxLonLimit = this.getProjectionLimits().getMaxLongitude().radians;
        int pos = 0;

        // Iterate over the latitude and longitude coordinates in the specified sector, computing the Cartesian point
        // corresponding to each latitude and longitude.
        double lat = minLat;
        for (int j = 0; j < numLat; j++, lat += deltaLat)
        {
            if (j == numLat - 1) // explicitly set the last lat to the max latitude to ensure alignment
                lat = maxLat;
            lat = WWMath.clamp(lat, minLatLimit, maxLatLimit); // limit lat to projection limits

            double lon = minLon;
            for (int i = 0; i < numLon; i++, lon += deltaLon)
            {
                if (i == numLon - 1) // explicitly set the last lon to the max longitude to ensure alignment
                    lon = maxLon;
                lon = WWMath.clamp(lon, minLonLimit, maxLonLimit); // limit lon to projection limits

                out[pos] = this.geographicToCartesian(globe, Angle.fromRadiansLatitude(lat),
                    Angle.fromRadiansLongitude(lon), metersElevation[pos], offset);
                ++pos;
            }
        }
    }

    @Override
    public Position cartesianToGeographic(Globe globe, Vec4 cart, Vec4 offset)
    {
        double xOffset = offset != null ? offset.x : 0;
        double x = (cart.x - xOffset);// * (this.pole == NORTH ? 1 : -1);
        double y = cart.y;// * (this.pole == NORTH ? 1 : -1);

        double lon = Math.atan2(x, y * (this.pole == NORTH ? -1 : 1)); // TODO: this is for the sphere

        double k0 = 0.994; // standard UPS scale factor -- see above reference pg.157, pp 2.
        double ecc = Math.sqrt(globe.getEccentricitySquared());
        double r = Math.sqrt(x * x + y * y);
        double s = Math.sqrt(Math.pow(1 + ecc, 1 + ecc) * Math.pow(1 - ecc, 1 - ecc));
        double t = r * s / (2 * globe.getEquatorialRadius() * k0);

        double ecc2 = globe.getEccentricitySquared();
        double ecc4 = ecc2 * ecc2;
        double ecc6 = ecc4 * ecc2;
        double ecc8 = ecc6 * ecc2;

        double A = Math.PI / 2 - 2 * Math.atan(t);
        double B = ecc2 / 2 + 5 * ecc4 / 24 + ecc6 / 12 + 13 * ecc8 / 360;
        double C = 7 * ecc4 / 48 + 29 * ecc6 / 240 + 811 * ecc8 / 11520;
        double D = 7 * ecc6 / 120 + 81 * ecc8 / 1120;
        double E = 4279 * ecc8 / 161280;

        double Ap = A - C + E;
        double Bp = B - 3 * D;
        double Cp = 2 * C - 8 * E;
        double Dp = 4 * D;
        double Ep = 8 * E;

        double s2p = Math.sin(2 * A);

        double lat = Ap + s2p * (Bp + s2p * (Cp + s2p * (Dp + Ep * s2p)));

        lat = lat * (this.pole == NORTH ? 1 : -1);
        lon = lon * (this.pole == NORTH ? 1 : -1);

        return Position.fromRadians(lat, lon, cart.z);
    }

    @Override
    public Vec4 northPointingTangent(Globe globe, Angle latitude, Angle longitude)
    {
        // The north pointing tangent depends on the pole. With the south pole, the north pointing tangent points in the
        // same direction as the vector returned by cartesianToGeographic. With the north pole, the north pointing
        // tangent has the opposite direction.

        double x = Math.sin(longitude.radians) * (this.pole == SOUTH ? 1 : -1);
        double y = Math.cos(longitude.radians);

        return new Vec4(x, y, 0);
    }
}
