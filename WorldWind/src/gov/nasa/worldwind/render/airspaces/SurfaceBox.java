/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.render.airspaces;

import gov.nasa.worldwind.geom.*;
import gov.nasa.worldwind.globes.Globe;
import gov.nasa.worldwind.render.*;
import gov.nasa.worldwind.util.*;

import java.util.*;

public class SurfaceBox extends AbstractSurfaceShape
{
    protected LatLon[] vertices;
    protected boolean enableStartCap = true;
    protected boolean enableEndCap = true;

    public SurfaceBox()
    {
    }

    public LatLon[] getVertices()
    {
        return vertices;
    }

    public void setVertices(LatLon[] vertices)
    {
        this.vertices = vertices;
        this.onShapeChanged();
    }

    public boolean[] isEnableCaps()
    {
        return new boolean[] {this.enableStartCap, this.enableEndCap};
    }

    public void setEnableCaps(boolean enableStartCap, boolean enableEndCap)
    {
        this.enableStartCap = enableStartCap;
        this.enableEndCap = enableEndCap;
        this.onShapeChanged();
    }

    @Override
    public Position getReferencePosition()
    {
        return this.vertices != null ? new Position(vertices[0].latitude, vertices[0].longitude, 0) : null;
    }

    @Override
    protected void doMoveTo(Position oldReferencePosition, Position newReferencePosition)
    {
        // Intentionally left blank.
    }

    @Override
    protected void doMoveTo(Globe globe, Position oldReferencePosition, Position newReferencePosition)
    {
        // Intentionally left blank.
    }

    @Override
    protected List<List<LatLon>> createGeometry(Globe globe, SurfaceTileDrawContext sdc)
    {
        if (this.vertices == null)
            return null;

        double edgeIntervalsPerDegree = this.computeEdgeIntervalsPerDegree(sdc);
        ArrayList<List<LatLon>> geom = new ArrayList<List<LatLon>>();

        ArrayList<LatLon> interior = new ArrayList<LatLon>();
        geom.add(interior); // place interior vertices first in the geometry list

        for (int i = 0; i < 4; i++)
        {
            LatLon a = this.vertices[i];
            LatLon b = this.vertices[(i + 1) % 4];

            ArrayList<LatLon> intermediate = new ArrayList<LatLon>();
            this.addIntermediateLocations(a, b, edgeIntervalsPerDegree, intermediate);
            interior.add(a);
            interior.addAll(intermediate);

            if ((i != 0 || this.enableStartCap) && (i != 2 || this.enableEndCap))
            {
                ArrayList<LatLon> outline = new ArrayList<LatLon>();
                outline.add(a);
                outline.addAll(intermediate);
                outline.add(b);
                geom.add(outline);
            }
        }

        return geom;
    }

    @Override
    protected void determineActiveGeometry(DrawContext dc, SurfaceTileDrawContext sdc)
    {
        this.activeGeometry.clear();
        this.activeOutlineGeometry.clear();

        List<List<LatLon>> geom = this.getCachedGeometry(dc, sdc); // calls createGeometry
        if (geom == null)
            return;

        List<LatLon> interior = geom.get(0);
        String pole = this.containsPole(interior);
        if (pole != null)
        {
            // Wrap the shape interior around the pole and along the anti-meridian. See WWJ-284.
            this.activeGeometry.add(this.cutAlongDateLine(interior, pole, dc.getGlobe()));
        }
        else if (LatLon.locationsCrossDateLine(interior))
        {
            this.activeGeometry.addAll(this.repeatAroundDateline(interior));
        }
        else
        {
            this.activeGeometry.add(interior);
        }

        for (int i = 1; i < geom.size(); i++)
        {
            List<LatLon> outline = geom.get(i);
            if (LatLon.locationsCrossDateLine(
                interior)) // The outline need only compensate for dateline crossing. See WWJ-452.
            {
                this.activeOutlineGeometry.addAll(this.repeatAroundDateline(outline));
            }
            else
            {
                this.activeOutlineGeometry.add(outline);
            }
        }
    }

    @Override
    public Iterable<? extends LatLon> getLocations(Globe globe)
    {
        if (globe == null)
        {
            String message = Logging.getMessage("nullValue.GlobeIsNull");
            Logging.logger().severe(message);
            throw new IllegalArgumentException(message);
        }

        return this.vertices != null ? Arrays.asList(this.vertices) : null;
    }
}
