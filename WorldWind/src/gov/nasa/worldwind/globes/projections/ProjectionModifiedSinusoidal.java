/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.globes.projections;

import gov.nasa.worldwind.geom.*;
import gov.nasa.worldwind.globes.*;
import gov.nasa.worldwind.util.WWMath;

/**
 * Provides a Modified Sinusoidal spherical projection.
 *
 * @author tag
 * @version $Id$
 */
public class ProjectionModifiedSinusoidal extends AbstractGeographicProjection
{
    public ProjectionModifiedSinusoidal()
    {
        super(Sector.FULL_SPHERE);
    }

    @Override
    public String getName()
    {
        return "Modified Sinusoidal";
    }

    @Override
    public boolean isContinuous()
    {
        return false;
    }

    @Override
    public Vec4 geographicToCartesian(Globe globe, Angle latitude, Angle longitude, double metersElevation, Vec4 offset)
    {
        double latCos = latitude.cos();
        double x = latCos > 0 ? globe.getEquatorialRadius() * longitude.radians * Math.pow(latCos, .3) : 0;
        double y = globe.getEquatorialRadius() * latitude.radians;

        return new Vec4(x, y, metersElevation);
    }

    @Override
    public Position cartesianToGeographic(Globe globe, Vec4 cart, Vec4 offset)
    {
        double latRadians = cart.y / globe.getEquatorialRadius();
        latRadians = WWMath.clamp(latRadians, -Math.PI / 2, Math.PI / 2);

        double latCos = Math.cos(latRadians);
        double lonRadians = latCos > 0 ? cart.x / globe.getEquatorialRadius() / Math.pow(latCos, .3) : 0;
        lonRadians = WWMath.clamp(lonRadians, -Math.PI, Math.PI);

        return Position.fromRadians(latRadians, lonRadians, cart.z);
    }

    @Override
    public Vec4 northPointingTangent(Globe globe, Angle latitude, Angle longitude)
    {
        // Computed by taking the partial derivative of the x and y components in geographicToCartesian with
        // respect to latitude (keeping longitude a constant).

        double x = globe.getEquatorialRadius() * longitude.radians * .3 * Math.pow(latitude.cos(), .3 - 1)
            * -latitude.sin();
        double y = globe.getEquatorialRadius();

        return new Vec4(x, y, 0).normalize3();
    }
}
