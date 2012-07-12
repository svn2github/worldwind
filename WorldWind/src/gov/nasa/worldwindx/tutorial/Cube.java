/*
 * Copyright (C) 2012 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwindx.tutorial;

import gov.nasa.worldwind.*;
import gov.nasa.worldwind.avlist.AVKey;
import gov.nasa.worldwind.awt.WorldWindowGLCanvas;
import gov.nasa.worldwind.geom.*;
import gov.nasa.worldwind.layers.RenderableLayer;
import gov.nasa.worldwind.pick.PickSupport;
import gov.nasa.worldwind.render.*;
import gov.nasa.worldwind.render.Cylinder;
import gov.nasa.worldwind.util.*;

import javax.media.opengl.GL;
import java.awt.*;

/**
 * Example of a custom {@link Renderable} that draws a cube at a geographic position. This class shows the simplest
 * possible example of a Renderable, while still following World Wind best practices.
 * <p/>
 * What happens when the cube is rendered:
 * <p/>
 * 1) Scene controller calls render in picking mode. 2) Scene controller calls render in normal rendering mode. 3) Scene
 * controller calls render in ordered rendering mode.
 *
 * @author pabercrombie
 * @version $Id$
 */
public class Cube implements OrderedRenderable
{
    /** Geographic position of the cube. */
    protected Position position;
    /** Length of each face, in meters. */
    protected double size;

    protected OGLStackHandler BEogsh = new OGLStackHandler(); // used for beginDrawing/endDrawing state
    protected PickSupport pickSupport = new PickSupport();

    // Determined each frame
    protected long frameTimestamp = -1L;
    /** Cartesian position of the cube, computed from {@link #position}. */
    protected Vec4 placePoint;
    /** Distance from the eye point to the cube. */
    protected double eyeDistance;

    public Cube(Position position, double sizeInMeters)
    {
        this.position = position;
        this.size = sizeInMeters;
    }

    public void render(DrawContext dc)
    {
        // Render is called three times:
        // 1) During picking. The cube is drawn in a single color.
        // 2) As a normal renderable. The cube is added to the ordered renderable queue.
        // 3) As an OrderedRenderable. The cube is drawn.

        if (dc.isOrderedRenderingMode())
            this.drawOrderedRenderable(dc, this.pickSupport);
        else
            this.makeOrderedRenderable(dc);
    }

    public double getDistanceFromEye()
    {
        return this.eyeDistance;
    }

    public void pick(DrawContext dc, Point pickPoint)
    {
        this.render(dc);
    }

    public Material material;
    protected void beginDrawing(DrawContext dc)
    {
        GL gl = dc.getGL();
        this.BEogsh.clear();

        int attrMask = GL.GL_CURRENT_BIT
            | GL.GL_DEPTH_BUFFER_BIT
            | GL.GL_COLOR_BUFFER_BIT;

        this.BEogsh.pushAttrib(gl, attrMask);

        if (!dc.isPickingMode())
        {
            dc.beginStandardLighting();
            gl.glEnable(GL.GL_BLEND);
            OGLUtil.applyBlending(gl, false);
        }

        dc.getView().pushReferenceCenter(dc, this.placePoint);

//        gl.glMatrixMode(GL.GL_MODELVIEW);
//
//        Matrix matrix = dc.getGlobe().computeSurfaceOrientationAtPosition(this.position);
//        double[] matrixArray = new double[16];
//        matrix.toArray(matrixArray, 0, false);
//        gl.glLoadMatrixd(matrixArray, 0);
    }

    protected void endDrawing(DrawContext dc)
    {
        GL gl = dc.getGL();

        dc.getView().popReferenceCenter(dc);

        if (!dc.isPickingMode())
        {
            dc.endStandardLighting();
        }

        this.BEogsh.pop(gl);
    }

    protected void makeOrderedRenderable(DrawContext dc)
    {
        // This method is called twice each frame: once during picking and once during rendering. We only need to
        // compute the placePoint and eye distance once per frame, so check the frame timestamp to see if this is a
        // new frame.
        if (dc.getFrameTimeStamp() != this.frameTimestamp)
        {
            // Convert the cube's geographic position to a position in Cartesian coordinates.
            this.placePoint = dc.getGlobe().computePointFromPosition(this.position);

            // Compute the distance from the eye to the cube's position.
            this.eyeDistance = dc.getView().getEyePoint().distanceTo3(this.placePoint);

            this.frameTimestamp = dc.getFrameTimeStamp();
        }

        // Add the cube to the ordered renderable list. The SceneController sorts the ordered renderables by eye
        // distance, and then renders them back to front. render will be called again in ordered rendering mode, and at
        // that point we will actually draw the cube.
        dc.addOrderedRenderable(this);
    }

    /**
     * Set up drawing state, and draw the cube. This method is called when the cube is rendered in ordered rendering
     * mode.
     *
     * @param dc Current draw context.
     */
    protected void drawOrderedRenderable(DrawContext dc, PickSupport pickCandidates)
    {
        this.beginDrawing(dc);
        try
        {
            GL gl = dc.getGL();
            if (dc.isPickingMode())
            {
                Color pickColor = dc.getUniquePickColor();
                pickCandidates.addPickableObject(pickColor.getRGB(), this, this.position);
                gl.glColor3ub((byte) pickColor.getRed(), (byte) pickColor.getGreen(), (byte) pickColor.getBlue());
            }
            else
            {
                material.apply(gl, GL.GL_FRONT_AND_BACK, (float) 0.7);
            }

            // Render a unit cube and apply a scaling factor to scale the cube to the appropriate size.
            gl.glScaled(this.size, this.size, this.size);
            this.drawUnitCube(dc);
        }
        finally
        {
            this.endDrawing(dc);
        }
    }

    /**
     * Draw a unit cube, using the active modelview matrix to orient the shape.
     *
     * @param dc Current draw context.
     */
    protected void drawUnitCube(DrawContext dc)
    {
        // Vertices of a unit cube, centered on the origin.
        float[][] v = {{-1f, 1f, 0f}, {-1f, 1f, 2f}, {1f, 1f, 2f}, {1f, 1f, 0f},
            {-1f, -1f, 2f}, {1f, -1f, 2f}, {1f, -1f, 0f}, {-1f, -1f, 0f}};

        // Array to group vertices into faces
        int[][] faces = {{0, 1, 2, 3}, {2, 5, 6, 3}, {1, 4, 5, 2}, {0, 7, 4, 1}, {0, 7, 6, 3}, {4, 7, 6, 5}};

        // Normal vectors for each face
        float[][] n = {{0, 1, 0}, {1, 0, 0}, {0, 0, 1}, {-1, 0, 0}, {0, 0, -1}, {0, -1, 0}};

        // Note: draw the cube in OpenGL immediate mode for simplicity. Real applications should use vertex arrays
        // or vertex buffer objects to achieve better performance.
        GL gl = dc.getGL();
        gl.glBegin(GL.GL_QUADS);
        try
        {
            for (int i = 0; i < faces.length; i++)
            {
                gl.glNormal3f(n[i][0], n[i][1], n[i][2]);

                for (int j = 0; j < faces[0].length; j++)
                {
                    gl.glVertex3f(v[faces[i][j]][0], v[faces[i][j]][1], v[faces[i][j]][2]);
                }
            }
        }
        finally
        {
            gl.glEnd();
        }
    }

    // An inner class is used rather than directly subclassing JFrame in the main class so
    // that the main can configure system properties prior to invoking Swing. This is
    // necessary for instance on OS X (Macs) so that the application name can be specified.

    protected static class AppFrame extends javax.swing.JFrame
    {
        public AppFrame()
        {
            WorldWindowGLCanvas wwd = new WorldWindowGLCanvas();
            wwd.setPreferredSize(new java.awt.Dimension(1000, 800));
            this.getContentPane().add(wwd, java.awt.BorderLayout.CENTER);
            this.pack();

            wwd.setModel(new BasicModel());

            RenderableLayer layer = new RenderableLayer();
            Cube cube = new Cube(Position.fromDegrees(35.0, -120.0, 5000), 1000);
            layer.addRenderable(cube);
            cube.material = Material.RED;

            cube = new Cube(Position.fromDegrees(35.0, -120.05, 5000), 1000);
            layer.addRenderable(cube);
            cube.material = Material.BLUE;

            wwd.getModel().getLayers().add(layer);
        }
    }

    public static void main(String[] args)
    {
        if (Configuration.isMacOS())
        {
            System.setProperty("com.apple.mrj.application.apple.menu.about.name", "World Wind Cube Tutorial");
        }

        Configuration.setValue(AVKey.INITIAL_LATITUDE, 35.0);
        Configuration.setValue(AVKey.INITIAL_LONGITUDE, -120.0);
        Configuration.setValue(AVKey.INITIAL_ALTITUDE, 15500);

        java.awt.EventQueue.invokeLater(new Runnable()
        {
            public void run()
            {
                // Create an AppFrame and immediately make it visible. As per Swing convention, this
                // is done within an invokeLater call so that it executes on an AWT thread.
                new AppFrame().setVisible(true);
            }
        });
    }
}
