/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.globes.projections;

import gov.nasa.worldwind.geom.*;
import gov.nasa.worldwind.globes.*;

/**
 * Implements a Cautra projection.
 *
 * @author tag
 * @version $Id$
 */
public class ProjectionCautra implements GeographicProjection
{
    public static final double WGS84_ES = 0.00669437999014; // eccentricity squared, semi-major axis
    public static final double WGS84_E = 0.081819190842622; //eccentricity
    private static final double R0 = 6366757.037688594; //rayon de la sphre conforme au point d'origine, en mtres
    private static final double y0 = -5040511.788585899; //ordonne de P0 dans le plan tangent, en mtres

    @Override
    public String getName()
    {
        return "Cautra";
    }

    @Override
    public boolean isContinuous()
    {
        return false;
    }

    @Override
    public Vec4 geographicToCartesian(Globe globe, Angle latitude, Angle longitude, double metersElevation, Vec4 offset)
    {
        if (longitude.degrees > 160)
            longitude = Angle.fromDegrees(160);
        if (longitude.degrees < -160)
            longitude = Angle.fromDegrees(-160);

        double phi = latitude.radians;//latitude en radians
        double psi = longitude.radians;//longitude en radians
        double lConforme = latitudeConforme(phi);//Latitude conforme du point
        double L0 = latitudeConforme(47.0 / 180.0 * Math.PI);
        double k = 2 / (1 + Math.sin(L0) * Math.sin(lConforme) + Math.cos(L0) * Math.cos(lConforme) * Math.cos(psi));

        return new Vec4(k * R0 * Math.cos(lConforme) * Math.sin(psi),
            k * R0 * (Math.cos(L0) * Math.sin(lConforme) - Math.sin(L0) * Math.cos(lConforme) * Math.cos(psi)),
            metersElevation);
    }

    @Override
    public Position cartesianToGeographic(Globe globe, Vec4 cart, Vec4 offset)
    {
        double[] latlon = toStereo(cart.x, cart.y);

        return Position.fromRadians(latlon[0], latlon[1], cart.z);
    }

    protected static double latitudeConforme(double phi)
    {
        return 2 * Math.atan(
            Math.pow((1 - Math.sqrt(WGS84_ES) * Math.sin(phi)) / (1 + Math.sqrt(WGS84_ES) * Math.sin(phi)),
                Math.sqrt(WGS84_ES) / 2) * Math.tan(Math.PI / 4 + phi / 2)) - Math.PI / 2;
    }

    protected static double[] toStereo(double x, double y)
    {
        double[] latlon = {0, 0};

        //changement de plan stro
        double a = 4 * Math.pow(R0, 2) - y0 * y;
        double b = y0 * x;
        double c = 4 * Math.pow(R0, 2) * x;
        double d = 4 * Math.pow(R0, 2) * (y + y0);
        double u = (a * c + b * d) / (Math.pow(a, 2) + Math.pow(b, 2));
        double v = (a * d - b * c) / (Math.pow(a, 2) + Math.pow(b, 2));

        //latitude godsique
        double l = Math.PI / 2 - 2 * Math.atan(Math.sqrt(Math.pow(u, 2) + Math.pow(v, 2)) / (2 * R0));
        latlon[0] = 2 * Math.atan(
            Math.pow((1 + WGS84_E * Math.sin(l)) / (1 - WGS84_E * Math.sin(l)), WGS84_E / 2) * Math.tan(
                Math.PI / 4 + l / 2)) - Math.PI / 2;

        //longitude godsique
        if (v < 0)
        {
            latlon[1] = -Math.atan(u / v);
        }
        else if (v >= 0 && u > 0)
        {
            latlon[1] = Math.PI / 2 + Math.atan(v / u);
        }
        else if (v >= 0 && u < 0)
        {
            latlon[1] = -Math.PI / 2 + Math.atan(v / u);
        }

        return latlon;
    }
}
