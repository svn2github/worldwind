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

import javax.media.opengl.GL2;
import java.util.*;

public class SurfaceBox extends AbstractSurfaceShape
{
    protected LatLon[] locations;
    protected LatLon[] corners;
    protected boolean enableStartCap = true;
    protected boolean enableEndCap = true;
    protected boolean enableCenterLine;
    protected List<List<LatLon>> activeCenterLineGeometry = new ArrayList<List<LatLon>>(); // re-determined each frame

    public SurfaceBox()
    {
    }

    public LatLon[] getLocations()
    {
        return this.locations;
    }

    public void setLocations(LatLon[] locations, LatLon[] corners)
    {
        this.locations = locations;
        this.corners = corners;
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

    public boolean isEnableCenterLine()
    {
        return this.enableCenterLine;
    }

    public void setEnableCenterLine(boolean enable)
    {
        this.enableCenterLine = enable;
    }

    @Override
    public Position getReferencePosition()
    {
        return this.locations != null ? new Position(this.locations[0].latitude, this.locations[0].longitude, 0) : null;
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
        if (this.locations == null)
            return null;

        double edgeIntervalsPerDegree = this.computeEdgeIntervalsPerDegree(sdc);
        ArrayList<List<LatLon>> geom = new ArrayList<List<LatLon>>();

        ArrayList<LatLon> interior = new ArrayList<LatLon>();
        geom.add(interior); // store interior geometry in index 0

        for (int i = 0; i < 4; i++) // iterate over this box's four segments
        {
            LatLon a = this.corners[i];
            LatLon b = this.corners[(i + 1) % 4];

            // Generate intermediate locations between the segment begin and end locations.
            ArrayList<LatLon> intermediate = new ArrayList<LatLon>();
            this.addIntermediateLocations(a, b, edgeIntervalsPerDegree, intermediate);

            // Add segment locations to the interior geometry.
            interior.add(a);
            interior.addAll(intermediate);

            // Add segment locations to the outline geometry.
            if ((i != 0 || this.enableStartCap) && (i != 2 || this.enableEndCap))
            {
                ArrayList<LatLon> outline = new ArrayList<LatLon>();
                outline.add(a);
                outline.addAll(intermediate);
                outline.add(b);
                geom.add(outline); // store outline geometry in indices 1+
            }
        }

        // Store the center line geometry at the end of the geometry list.
        ArrayList<LatLon> centerLine = new ArrayList<LatLon>();
        centerLine.add(this.locations[0]);
        this.addIntermediateLocations(this.locations[0], this.locations[1], edgeIntervalsPerDegree, centerLine);
        centerLine.add(this.locations[1]);
        geom.add(centerLine);

        return geom;
    }

    @Override
    protected void determineActiveGeometry(DrawContext dc, SurfaceTileDrawContext sdc)
    {
        this.activeGeometry.clear();
        this.activeOutlineGeometry.clear();
        this.activeCenterLineGeometry.clear();

        List<List<LatLon>> geom = this.getCachedGeometry(dc, sdc); // calls createGeometry
        if (geom == null)
            return;

        int index = 0; // interior geometry stored in index 0
        List<LatLon> interior = geom.get(index++);
        String pole = this.containsPole(interior);
        if (pole != null) // interior compensates for poles and dateline crossing, see WWJ-284
        {
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

        for (; index < geom.size() - 1; index++) // outline geometry stored in indices 1 through size-2
        {
            List<LatLon> outline = geom.get(index);
            if (LatLon.locationsCrossDateLine(outline)) // outlines compensate for dateline crossing, see WWJ-452
            {
                this.activeOutlineGeometry.addAll(this.repeatAroundDateline(outline));
            }
            else
            {
                this.activeOutlineGeometry.add(outline);
            }
        }

        if (index < geom.size()) // outline geometry stored in index size-1
        {
            List<LatLon> centerLine = geom.get(index);
            if (LatLon.locationsCrossDateLine(centerLine)) // outlines compensate for dateline crossing, see WWJ-452
            {
                this.activeCenterLineGeometry.addAll(this.repeatAroundDateline(centerLine));
            }
            else
            {
                this.activeCenterLineGeometry.add(centerLine);
            }
        }
    }

    protected void drawOutline(DrawContext dc, SurfaceTileDrawContext sdc)
    {
        super.drawOutline(dc, sdc);

        if (this.enableCenterLine)
        {
            this.drawCenterLine(dc);
        }
    }

    protected void drawCenterLine(DrawContext dc)
    {
        if (this.activeCenterLineGeometry.isEmpty())
            return;

        this.applyCenterLineState(dc, this.getActiveAttributes());

        for (List<LatLon> drawLocations : this.activeCenterLineGeometry)
        {
            this.drawLineStrip(dc, drawLocations);
        }
    }

    protected void applyCenterLineState(DrawContext dc, ShapeAttributes attributes)
    {
        GL2 gl = dc.getGL().getGL2(); // GL initialization checks for GL2 compatibility.

        if (!dc.isPickingMode() && attributes.getOutlineStippleFactor() <= 0) // don't override stipple in attributes
        {
            gl.glEnable(GL2.GL_LINE_STIPPLE);
            gl.glLineStipple(Box.DEFAULT_CENTER_LINE_STIPPLE_FACTOR, Box.DEFAULT_CENTER_LINE_STIPPLE_PATTERN);
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

        return this.corners != null ? Arrays.asList(this.corners) : null;
    }
}
