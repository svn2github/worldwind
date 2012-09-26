/* Copyright (C) 2001, 2012 United States Government as represented by
the Administrator of the National Aeronautics and Space Administration.
All Rights Reserved.
*/
package gov.nasa.worldwind.terrain;

import gov.nasa.worldwind.geom.*;
import gov.nasa.worldwind.globes.Globe;
import gov.nasa.worldwind.render.DrawContext;
import gov.nasa.worldwind.util.Logging;

/**
 * @author dcollins
 * @version $Id$
 */
public class VisibleTerrain implements Terrain
{
    protected DrawContext dc;
    protected Vec4 point = new Vec4();

    public VisibleTerrain(DrawContext dc)
    {
        this.dc = dc;
    }

    /** {@inheritDoc} */
    public Globe getGlobe()
    {
        return this.dc.getGlobe();
    }

    /** {@inheritDoc} */
    public double getVerticalExaggeration()
    {
        return this.dc.getVerticalExaggeration();
    }

    /** {@inheritDoc} */
    public Double getElevation(Angle latitude, Angle longitude)
    {
        if (latitude == null)
        {
            String msg = Logging.getMessage("nullValue.LatitudeIsNull");
            Logging.error(msg);
            throw new IllegalArgumentException(msg);
        }

        if (longitude == null)
        {
            String msg = Logging.getMessage("nullValue.LongitudeIsNull");
            Logging.error(msg);
            throw new IllegalArgumentException(msg);
        }

        Vec4 pt = this.getSurfacePoint(latitude, longitude, 0);
        if (pt == null)
            return null;

        Vec4 p = this.getGlobe().computePointFromPosition(latitude, longitude, 0);

        return p.distanceTo3(pt);
    }

    /** {@inheritDoc} */
    public Vec4 getSurfacePoint(Position position)
    {
        if (position == null)
        {
            String msg = Logging.getMessage("nullValue.PositionIsNull");
            Logging.error(msg);
            throw new IllegalArgumentException(msg);
        }

        return this.getSurfacePoint(position.latitude, position.longitude, position.elevation);
    }

    /** {@inheritDoc} */
    public Vec4 getSurfacePoint(Angle latitude, Angle longitude, double metersOffset)
    {
        if (latitude == null)
        {
            String msg = Logging.getMessage("nullValue.LatitudeIsNull");
            Logging.error(msg);
            throw new IllegalArgumentException(msg);
        }

        if (longitude == null)
        {
            String msg = Logging.getMessage("nullValue.LongitudeIsNull");
            Logging.error(msg);
            throw new IllegalArgumentException(msg);
        }

        SectorGeometryList sectorGeometry = this.dc.getSurfaceGeometry();
        if (sectorGeometry == null)
            return null;

        Vec4 pt = new Vec4(); // TODO: modify the getSurfacePoint methods on Terrain to accept an output parameter.

        if (sectorGeometry.getSurfacePoint(latitude, longitude, pt))
        {
            this.getGlobe().computeSurfaceNormalAtPoint(pt, this.point);
            this.point.multiply3AndSet(metersOffset);
            pt.add3AndSet(this.point);

            return pt;
        }

        double elevation = this.getGlobe().getElevation(latitude, longitude);
        this.getGlobe().computePointFromPosition(latitude, longitude,
            metersOffset + elevation * this.getVerticalExaggeration(), pt);

        return pt;
    }
};
