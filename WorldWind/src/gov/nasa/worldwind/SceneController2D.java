/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind;

import gov.nasa.worldwind.geom.Sector;
import gov.nasa.worldwind.globes.FlatGlobe;
import gov.nasa.worldwind.render.DrawContext;
import gov.nasa.worldwind.terrain.SectorGeometryList;

/**
 * @author tag
 * @version $Id$
 */
public class SceneController2D extends AbstractSceneController
{
    SectorGeometryList sglC, sglL, sglR;
    Sector visibleSectorC, visibleSectorL, visibleSectorR;

    public void doRepaint(DrawContext dc)
    {
        this.initializeFrame(dc);
        try
        {
            ((FlatGlobe) dc.getGlobe()).setOffset(0);

            this.applyView(dc);
            this.createPickFrustum(dc);
            this.clearFrame(dc);
            this.createTerrain(dc);
            this.preRender(dc);
            this.clearFrame(dc);
            this.pick(dc);
            this.clearFrame(dc);
            this.draw(dc);
        }
        finally
        {
            this.finalizeFrame(dc);
        }
    }

    protected void createTerrain(DrawContext dc)
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
        ((FlatGlobe) dc.getGlobe()).setOffset(1);
        if (dc.getGlobe().intersects(dc.getView().getFrustumInModelCoordinates()))
        {
            this.sglR = dc.getModel().getGlobe().tessellate(dc);
            this.visibleSectorR = this.sglR.getSector();
        }

        this.sglL = null;
        this.visibleSectorL = null;
        ((FlatGlobe) dc.getGlobe()).setOffset(-1);
        if (dc.getGlobe().intersects(dc.getView().getFrustumInModelCoordinates()))
        {
            this.sglL = dc.getModel().getGlobe().tessellate(dc);
            this.visibleSectorL = this.sglL.getSector();
        }
    }

    protected void makeCurrent(DrawContext dc, int offset)
    {
        ((FlatGlobe) dc.getGlobe()).setOffset(offset);

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

    protected void draw(DrawContext dc)
    {
        String drawing = "";
        if (this.sglC != null)
        {
            drawing += " 0 ";
            this.makeCurrent(dc, 0);
            super.draw(dc);
        }

        if (this.sglR != null)
        {
            drawing += " 1 ";
            this.makeCurrent(dc, 1);
            super.draw(dc);
        }

        if (this.sglL != null)
        {
            drawing += " -1 ";
            this.makeCurrent(dc, -1);
            super.draw(dc);
        }
//        System.out.println("DRAWING " + drawing);
    }

    protected void preRender(DrawContext dc)
    {
        if (this.sglC != null)
        {
            this.makeCurrent(dc, 0);
            super.preRender(dc);
        }

        if (this.sglR != null)
        {
            this.makeCurrent(dc, 1);
            super.preRender(dc);
        }

        if (this.sglL != null)
        {
            this.makeCurrent(dc, -1);
            super.preRender(dc);
        }
    }

    protected void pick(DrawContext dc)
    {
        if (this.sglC != null)
        {
            this.makeCurrent(dc, 0);
            super.pick(dc);
        }

        if (this.sglR != null)
        {
            this.makeCurrent(dc, 1);
            super.pick(dc);
        }

        if (this.sglL != null)
        {
            this.makeCurrent(dc, -1);
            super.pick(dc);
        }
    }
}
