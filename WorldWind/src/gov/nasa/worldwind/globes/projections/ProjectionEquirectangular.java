/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.globes.projections;

import gov.nasa.worldwind.geom.*;
import gov.nasa.worldwind.globes.*;

/**
 * Implements an Equirectangular projection, also known as Equidistant Cylindrical, Plate Carree and Rectangular.
 *
 * @author tag
 * @version $Id$
 */
public class ProjectionEquirectangular implements GeographicProjection
{
    @Override
    public String getName()
    {
        return "Equirectangular";
    }

    @Override
    public boolean isContinuous()
    {
        return true;
    }

    @Override
    public Vec4 geographicToCartesian(Globe globe, Angle latitude, Angle longitude, double metersElevation, Vec4 offset)
    {
        return new Vec4(globe.getEquatorialRadius() * longitude.radians + offset.x,
            globe.getEquatorialRadius() * latitude.radians, metersElevation);
    }

    @Override
    public Position cartesianToGeographic(Globe globe, Vec4 cart, Vec4 offset)
    {
        return Position.fromRadians(cart.y / globe.getEquatorialRadius(),
            (cart.x - offset.x) / globe.getEquatorialRadius(), cart.z);
    }
}
