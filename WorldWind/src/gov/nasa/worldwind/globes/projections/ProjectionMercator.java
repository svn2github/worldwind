/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.globes.projections;

import gov.nasa.worldwind.geom.*;
import gov.nasa.worldwind.globes.*;

/**
 * @author tag
 * @version $Id$
 */
public class ProjectionMercator implements GeographicProjection
{
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
        if (latitude.degrees > 75)
            latitude = Angle.fromDegrees(75);
        if (latitude.degrees < -75)
            latitude = Angle.fromDegrees(-75);

        double xOffset = offset != null ? offset.x : 0;

        return new Vec4(globe.getEquatorialRadius() * longitude.radians + xOffset,
            globe.getEquatorialRadius() * Math.log(Math.tan(Math.PI / 4 + latitude.radians / 2)),
            metersElevation);
    }

    @Override
    public Position cartesianToGeographic(Globe globe, Vec4 cart, Vec4 offset)
    {
        double xOffset = offset != null ? offset.x : 0;

        return Position.fromRadians(
            Math.atan(Math.sinh(cart.y / globe.getEquatorialRadius())),
            (cart.x - xOffset) / globe.getEquatorialRadius(),
            cart.z);
    }

    @Override
    public Vec4 northPointingTangent(Globe globe, Angle latitude, Angle longitude)
    {
        return Vec4.UNIT_Y;
    }
}
