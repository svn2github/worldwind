/*
 * Copyright (C) 2012 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */
package gov.nasa.worldwind;

import gov.nasa.worldwind.geom.Sector;
import gov.nasa.worldwind.globes.*;
import gov.nasa.worldwind.render.DrawContext;
import gov.nasa.worldwind.terrain.SectorGeometryList;

/**
 * @author Tom Gaskins
 * @version $Id$
 */
public class BasicSceneController extends AbstractSceneController
{
    SectorGeometryList sglC, sglL, sglR;
    Sector visibleSectorC, visibleSectorL, visibleSectorR;

    public void doRepaint(DrawContext dc)
    {
        this.initializeFrame(dc);
        try
        {
            if (dc.getGlobe() instanceof Globe2D)
                this.do2DRepaint(dc);
            else
                this.do3DRepaint(dc);
        }
        finally
        {
            this.finalizeFrame(dc);
        }
    }

    protected void do3DRepaint(DrawContext dc)
    {
        this.applyView(dc);
        this.createPickFrustum(dc);
        this.createTerrain(dc);
        this.preRender(dc);
        this.clearFrame(dc);
        this.pick(dc);
        this.clearFrame(dc);
        this.draw(dc);
    }

    protected void do2DRepaint(DrawContext dc)
    {
        ((FlatGlobe) dc.getGlobe()).setOffset(0);

        this.applyView(dc);
        this.createPickFrustum(dc);
        this.createTerrain2D(dc);
        this.preRender2D(dc);
        this.clearFrame(dc);
        this.pick2D(dc);
        this.clearFrame(dc);
        this.draw2D(dc);
    }

    protected void makeCurrent(DrawContext dc, int offset)
    {
        ((Globe2D) dc.getGlobe()).setOffset(offset);

        switch (offset)
        {
            case -1:
                dc.setSurfaceGeometry(this.sglL);
                dc.setVisibleSector(this.visibleSectorL);
                break;
            case 0:
                dc.setSurfaceGeometry(this.sglC);
                dc.setVisibleSector(this.visibleSectorC);
                break;
            case 1:
                dc.setSurfaceGeometry(this.sglR);
                dc.setVisibleSector(this.visibleSectorR);
                break;
        }
    }

    protected void createTerrain2D(DrawContext dc)
    {
        this.sglC = null;
        this.visibleSectorC = null;
        ((FlatGlobe) dc.getGlobe()).setOffset(0);
        if (dc.getGlobe().intersects(dc.getView().getFrustumInModelCoordinates()))
        {
            this.sglC = dc.getModel().getGlobe().tessellate(dc);
            this.visibleSectorC = this.sglC.getSector();
        }

        this.sglR = null;
        this.visibleSectorR = null;
        ((Globe2D) dc.getGlobe()).setOffset(1);
        if (dc.getGlobe().intersects(dc.getView().getFrustumInModelCoordinates()))
        {
            this.sglR = dc.getModel().getGlobe().tessellate(dc);
            this.visibleSectorR = this.sglR.getSector();
        }

        this.sglL = null;
        this.visibleSectorL = null;
        ((Globe2D) dc.getGlobe()).setOffset(-1);
        if (dc.getGlobe().intersects(dc.getView().getFrustumInModelCoordinates()))
        {
            this.sglL = dc.getModel().getGlobe().tessellate(dc);
            this.visibleSectorL = this.sglL.getSector();
        }
    }

    protected void draw2D(DrawContext dc)
    {
        String drawing = "";
        if (this.sglC != null)
        {
            drawing += " 0 ";
            this.makeCurrent(dc, 0);
            this.draw(dc);
        }

        if (this.sglR != null)
        {
            drawing += " 1 ";
            this.makeCurrent(dc, 1);
            this.draw(dc);
        }

        if (this.sglL != null)
        {
            drawing += " -1 ";
            this.makeCurrent(dc, -1);
            this.draw(dc);
        }
//        System.out.println("DRAWING " + drawing);
    }

    protected void preRender2D(DrawContext dc)
    {
        if (this.sglC != null)
        {
            this.makeCurrent(dc, 0);
            this.preRender(dc);
        }

        if (this.sglR != null)
        {
            this.makeCurrent(dc, 1);
            this.preRender(dc);
        }

        if (this.sglL != null)
        {
            this.makeCurrent(dc, -1);
            this.preRender(dc);
        }
    }

    protected void pick2D(DrawContext dc)
    {
        if (this.sglC != null)
        {
            this.makeCurrent(dc, 0);
            this.pick(dc);
        }

        if (this.sglR != null)
        {
            this.makeCurrent(dc, 1);
            this.pick(dc);
        }

        if (this.sglL != null)
        {
            this.makeCurrent(dc, -1);
            this.pick(dc);
        }
    }
}
