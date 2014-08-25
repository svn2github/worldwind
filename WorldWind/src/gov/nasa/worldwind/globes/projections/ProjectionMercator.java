/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.globes.projections;

import gov.nasa.worldwind.geom.*;
import gov.nasa.worldwind.globes.Globe;

/**
 * Provides a Mercator projection of an ellipsoidal globe.
 *
 * @author tag
 * @version $Id$
 */
public class ProjectionMercator extends AbstractGeographicProjection
{
    public ProjectionMercator()
    {
        super(Sector.fromDegrees(-78, 78, -180, 180));
    }

    @Override
    public String getName()
    {
        return "Mercator";
    }

    @Override
    public boolean isContinuous()
    {
        return true;
    }

    @Override
    public Vec4 geographicToCartesian(Globe globe, Angle latitude, Angle longitude, double metersElevation, Vec4 offset)
    {
        if (latitude.degrees > this.getProjectionLimits().getMaxLatitude().degrees)
            latitude = this.getProjectionLimits().getMaxLatitude();
        if (latitude.degrees < this.getProjectionLimits().getMinLatitude().degrees)
            latitude = this.getProjectionLimits().getMinLatitude();
        if (longitude.degrees > this.getProjectionLimits().getMaxLongitude().degrees)
            longitude = this.getProjectionLimits().getMaxLongitude();
        if (longitude.degrees < this.getProjectionLimits().getMinLongitude().degrees)
            longitude = this.getProjectionLimits().getMinLongitude();

        double xOffset = offset != null ? offset.x : 0;

        // See "Map Projections: A Working Manual", page 44 for the source of the below formulas.

        double x = globe.getEquatorialRadius() * longitude.radians + xOffset;

        double ecc = Math.sqrt(globe.getEccentricitySquared());
        double sinPhi = Math.sin(latitude.radians);
        double s = ((1 + sinPhi) / (1 - sinPhi)) * Math.pow((1 - ecc * sinPhi) / (1 + ecc * sinPhi), ecc);
        double y = 0.5 * globe.getEquatorialRadius() * Math.log(s);

        return new Vec4(x, y, metersElevation);
    }

    @Override
    public Position cartesianToGeographic(Globe globe, Vec4 cart, Vec4 offset)
    {
        double xOffset = offset != null ? offset.x : 0;

        // See "Map Projections: A Working Manual", pages 45 and 19 for the source of the below formulas.

        double ecc2 = globe.getEccentricitySquared();
        double ecc4 = ecc2 * ecc2;
        double ecc6 = ecc4 * ecc2;
        double ecc8 = ecc6 * ecc2;
        double t = Math.pow(Math.E, -cart.y / globe.getEquatorialRadius());

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

        return Position.fromRadians(lat, (cart.x - xOffset) / globe.getEquatorialRadius(), cart.z);
    }

    @Override
    public Vec4 northPointingTangent(Globe globe, Angle latitude, Angle longitude)
    {
        return Vec4.UNIT_Y;
    }
}
