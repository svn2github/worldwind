/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.globes.projections;

import gov.nasa.worldwind.avlist.AVKey;
import gov.nasa.worldwind.geom.*;
import gov.nasa.worldwind.globes.*;
import gov.nasa.worldwind.util.Logging;

/**
 * Defines a polar equidistant projection centered on a specified pole.
 *
 * @author tag
 * @version $Id$
 */
public class ProjectionPolarEquidistant implements GeographicProjection
{
    protected static final int NORTH = 0;
    protected static final int SOUTH = 1;

    protected int pole = NORTH;

    /**
     * Creates a projection centered on the North pole.
     */
    public ProjectionPolarEquidistant()
    {
    }

    /**
     * Creates a projection centered on the specified pole, which can be either {@link AVKey#NORTH} or {@link
     * AVKey#SOUTH}.
     *
     * @param pole The pole to center on, either {@link AVKey#NORTH} or {@link AVKey#SOUTH}.
     *
     * @throws IllegalArgumentException if the specified pole is null.
     */
    public ProjectionPolarEquidistant(String pole)
    {
        if (pole == null)
        {
            String message = Logging.getMessage("nullValue.HemisphereIsNull");
            Logging.logger().severe(message);
            throw new IllegalArgumentException(message);
        }

        this.pole = pole.equals(AVKey.SOUTH) ? SOUTH : NORTH;
    }

    public String getName()
    {
        return (this.pole == SOUTH ? "South " : "North ") + "Polar Equidistant";
    }

    @Override
    public boolean isContinuous()
    {
        return false;
    }

    /**
     * Indicates the pole on which this projection is centered.
     *
     * @return The pole on which this projection is centered, either {@link AVKey#NORTH} or {@link AVKey#SOUTH}.
     */
    public String getPole()
    {
        return this.pole == SOUTH ? AVKey.SOUTH : AVKey.NORTH;
    }

    @Override
    public Vec4 geographicToCartesian(Globe globe, Angle latitude, Angle longitude, double metersElevation, Vec4 offset)
    {
        // Formulae taken from "Map Projections -- A Working Manual", Snyder, USGS paper 1395, pg. 195.

        if ((this.pole == NORTH && latitude.degrees == 90) || (this.pole == SOUTH && latitude.degrees == -90))
            return new Vec4(0, 0, metersElevation);

        double a = globe.getRadius() * (Math.PI / 2 + latitude.radians * (this.pole == SOUTH ? 1 : -1));
        double x = a * Math.sin(longitude.radians);
        double y = a * Math.cos(longitude.radians) * (this.pole == SOUTH ? 1 : -1);

        return new Vec4(x, y, metersElevation);
    }

    @SuppressWarnings("SuspiciousNameCombination")
    @Override
    public Position cartesianToGeographic(Globe globe, Vec4 cart, Vec4 offset)
    {
        // Formulae taken from "Map Projections -- A Working Manual", Snyder, USGS paper 1395, pg. 196.

        double rho = Math.sqrt(cart.x * cart.x + cart.y * cart.y);
        if (rho < 1.0e-4)
            return Position.fromDegrees((this.pole == SOUTH ? -90 : 90), 0, cart.z);

        double c = rho / globe.getRadius();
        double lat = Math.asin(Math.cos(c) * (this.pole == SOUTH ? -1 : 1));
        double lon = Math.atan2(cart.x, cart.y * (this.pole == SOUTH ? 1 : -1)); // use atan2(x,y) instead of atan(x/y)

        return Position.fromRadians(lat, lon, cart.z);
    }

    @Override
    public boolean equals(Object o)
    {
        if (this == o)
            return true;
        if (o == null || getClass() != o.getClass())
            return false;

        ProjectionPolarEquidistant that = (ProjectionPolarEquidistant) o;

        if (pole != that.pole)
            return false;

        return true;
    }

    @Override
    public int hashCode()
    {
        return pole;
    }
}
