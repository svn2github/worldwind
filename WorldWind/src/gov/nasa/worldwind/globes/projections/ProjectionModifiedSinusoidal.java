/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.globes.projections;

import gov.nasa.worldwind.geom.*;
import gov.nasa.worldwind.globes.*;

/**
 * Provides a Modified Sinusoidal spherical projection.
 *
 * @author tag
 * @version $Id$
 */
public class ProjectionModifiedSinusoidal implements GeographicProjection
{
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

        return new Vec4(
            (latCos > 0 ? globe.getEquatorialRadius() * longitude.radians * Math.pow(latCos, .3) : 0),
            globe.getEquatorialRadius() * latitude.radians, metersElevation);
    }

    @Override
    public Position cartesianToGeographic(Globe globe, Vec4 cart, Vec4 offset)
    {
        double lat = cart.y / globe.getEquatorialRadius();
        double latCos = Math.cos(lat);
        return Position.fromRadians(lat, latCos > 0 ? cart.x / globe.getEquatorialRadius() / Math.pow(latCos, .3) : 0,
            cart.z);
    }
}
