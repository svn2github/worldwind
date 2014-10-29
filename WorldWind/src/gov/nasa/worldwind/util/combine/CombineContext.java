/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */
package gov.nasa.worldwind.util.combine;

import gov.nasa.worldwind.Disposable;
import gov.nasa.worldwind.geom.*;
import gov.nasa.worldwind.globes.Globe;
import gov.nasa.worldwind.util.*;

import javax.media.opengl.GL;
import javax.media.opengl.glu.*;
import java.util.*;

/**
 * @author dcollins
 * @version $Id$
 */
public class CombineContext implements Disposable
{
    protected static class TessCallbackAdapter extends GLUtessellatorCallbackAdapter
    {
        protected CombineContext cc;

        public TessCallbackAdapter(CombineContext cc)
        {
            this.cc = cc;
        }

        @Override
        public void begin(int type)
        {
            this.cc.tessBegin(type);
        }

        @Override
        public void vertex(Object vertexData)
        {
            this.cc.tessVertex(vertexData);
        }

        @Override
        public void end()
        {
            this.cc.tessEnd();
        }

        @Override
        public void combine(double[] coords, Object[] vertexData, float[] weight, Object[] outData)
        {
            this.cc.tessCombine(coords, vertexData, weight, outData);
        }

        @Override
        public void error(int errno)
        {
            this.cc.tessError(errno);
        }
    }

    protected Globe globe;
    protected Sector sector = Sector.FULL_SPHERE;
    protected double resolution;
    protected GLUtessellator tess;
    protected ContourList contours = new ContourList();
    protected ArrayList<LatLon> currentContour;
    protected boolean isBoundingSectorMode;
    protected ArrayList<Sector> boundingSectors = new ArrayList<Sector>();

    public CombineContext(Globe globe, double resolution)
    {
        if (globe == null)
        {
            String msg = Logging.getMessage("nullValue.GlobeIsNull");
            Logging.logger().severe(msg);
            throw new IllegalArgumentException(msg);
        }

        GLUtessellatorCallback cb = new TessCallbackAdapter(this); // forward GLU tessellator callbacks to tess* methods
        GLUtessellator tess = GLU.gluNewTess();
        GLU.gluTessCallback(tess, GLU.GLU_TESS_BEGIN, cb);
        GLU.gluTessCallback(tess, GLU.GLU_TESS_VERTEX, cb);
        GLU.gluTessCallback(tess, GLU.GLU_TESS_END, cb);
        GLU.gluTessCallback(tess, GLU.GLU_TESS_COMBINE, cb);
        GLU.gluTessCallback(tess, GLU.GLU_TESS_ERROR, cb);
        GLU.gluTessProperty(tess, GLU.GLU_TESS_BOUNDARY_ONLY, GL.GL_TRUE);
        GLU.gluTessNormal(tess, 0, 0, 1);

        this.globe = globe;
        this.resolution = resolution;
        this.tess = tess;
    }

    @Override
    public void dispose()
    {
        GLU.gluDeleteTess(this.tess);
        this.tess = null;
    }

    public Globe getGlobe()
    {
        return this.globe;
    }

    public void setGlobe(Globe globe)
    {
        if (globe == null)
        {
            String msg = Logging.getMessage("nullValue.GlobeIsNull");
            Logging.logger().severe(msg);
            throw new IllegalArgumentException(msg);
        }

        this.globe = globe;
    }

    public Sector getSector()
    {
        return this.sector;
    }

    public void setSector(Sector sector)
    {
        if (sector == null)
        {
            String msg = Logging.getMessage("nullValue.SectorIsNull");
            Logging.logger().severe(msg);
            throw new IllegalArgumentException(msg);
        }

        this.sector = sector;
    }

    public double getResolution()
    {
        return this.resolution;
    }

    public void setResolution(double resolution)
    {
        this.resolution = resolution;
    }

    public GLUtessellator getTessellator()
    {
        return this.tess;
    }

    public ContourList getContours()
    {
        return this.contours;
    }

    public void addContour(List<LatLon> contour)
    {
        if (contour == null)
        {
            String msg = Logging.getMessage("nullValue.ListIsNull");
            Logging.logger().severe(msg);
            throw new IllegalArgumentException(msg);
        }

        this.contours.addContour(contour);
    }

    public void removeAllContours()
    {
        this.contours.removeAllContours();
    }

    @SuppressWarnings("UnusedParameters")
    protected void tessBegin(int type)
    {
        this.currentContour = new ArrayList<LatLon>();
    }

    protected void tessVertex(Object vertexData)
    {
        double[] vertex = (double[]) vertexData; // longitude, latitude, 0
        this.currentContour.add(LatLon.fromDegrees(vertex[1], vertex[0])); // latitude, longitude
    }

    protected void tessEnd()
    {
        this.addContour(this.currentContour);
        this.currentContour = null;
    }

    @SuppressWarnings("UnusedParameters")
    protected void tessCombine(double[] coords, Object[] vertexData, float[] weight, Object[] outData)
    {
        outData[0] = coords;
    }

    protected void tessError(int errno)
    {
        String errstr = GLUTessellatorSupport.convertGLUTessErrorToString(errno);
        String msg = Logging.getMessage("generic.ExceptionWhileTessellating", errstr);
        Logging.logger().severe(msg);
    }

    public boolean isBoundingSectorMode()
    {
        return this.isBoundingSectorMode;
    }

    public void setBoundingSectorMode(boolean tf)
    {
        this.isBoundingSectorMode = tf;
    }

    public List<Sector> getBoundingSectors()
    {
        return this.boundingSectors;
    }

    public void addBoundingSector(Sector sector)
    {
        if (sector == null)
        {
            String msg = Logging.getMessage("nullValue.SectorIsNull");
            Logging.logger().severe(msg);
            throw new IllegalArgumentException(msg);
        }

        this.boundingSectors.add(sector);
    }

    public void removeAllBoundingSectors()
    {
        this.boundingSectors.clear();
    }
}