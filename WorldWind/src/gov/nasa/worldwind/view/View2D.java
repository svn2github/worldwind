/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.view;

import gov.nasa.worldwind.*;
import gov.nasa.worldwind.avlist.AVKey;
import gov.nasa.worldwind.geom.*;
import gov.nasa.worldwind.render.DrawContext;
import gov.nasa.worldwind.util.Logging;

import javax.media.opengl.GL2;
import java.awt.*;

/**
 * @author dcollins
 * @version $Id$
 */
public class View2D extends BasicView
{
    public View2D()
    {
        Double latDegrees = Configuration.getDoubleValue(AVKey.INITIAL_LATITUDE, 0d);
        Double lonDegrees = Configuration.getDoubleValue(AVKey.INITIAL_LONGITUDE, 0d);
        Double metersAltitude = Configuration.getDoubleValue(AVKey.INITIAL_ALTITUDE, 0d);
        this.setEyePosition(Position.fromDegrees(latDegrees, lonDegrees, metersAltitude));

        Double headingDegrees = Configuration.getDoubleValue(AVKey.INITIAL_HEADING, 0d);
        this.setHeading(Angle.fromDegrees(headingDegrees));

        Double fovDegrees = Configuration.getDoubleValue(AVKey.FOV, 45d);
        this.setFieldOfView(Angle.fromDegrees(fovDegrees));

        // TODO: Make this configurable.
        //ViewInputHandler inputHandler = (ViewInputHandler) WorldWind.createConfigurationComponent(
        //    AVKey.VIEW_INPUT_HANDLER_CLASS_NAME);
        //this.setViewInputHandler(inputHandler);
        this.setViewInputHandler(new View2DInputHandler());

        this.viewLimits = new BasicViewPropertyLimits();
    }

    @Override
    public Angle getPitch()
    {
        return Angle.ZERO; // View2D does not support the pitch property.
    }

    @Override
    public void setPitch(Angle pitch)
    {
        // Intentionally left blank. View2D does not support the pitch property.
    }

    @Override
    public Angle getRoll()
    {
        return Angle.ZERO; // View2D does not support the pitch property.
    }

    @Override
    public void setRoll(Angle roll)
    {
        // Intentionally left blank. View2D does not support the roll property.
    }

    @Override
    public Position getCurrentEyePosition()
    {
        return this.getEyePosition();
    }

    @Override
    public void setOrientation(Position eyePosition, Position centerPosition)
    {
        if (eyePosition == null)
        {
            String message = Logging.getMessage("nullValue.PositionIsNull");
            Logging.logger().severe(message);
            throw new IllegalArgumentException(message);
        }

        this.setEyePosition(eyePosition); // ignore the center position property
    }

    public void copyViewState(View view)
    {
        if (view == null)
        {
            String message = Logging.getMessage("nullValue.ViewIsNull");
            Logging.logger().severe(message);
            throw new IllegalArgumentException(message);
        }

        this.setEyePosition(view.getEyePosition());
        this.setHeading(view.getHeading());
    }

    @Override
    protected void doApply(DrawContext dc)
    {
        // Update this view's per-frame draw context and globe properties.
        this.dc = dc;
        this.globe = dc.getGlobe();

        // Compute the current modelview matrix based on this view's eye position and heading, as well as per-frame
        // properties that depend on the modelview matrix.
        this.modelview = ViewUtil.computeTransformMatrix(this.globe, this.eyePosition, this.heading, this.pitch,
            this.roll);
        this.modelviewInv = this.modelview.getInverse();
        this.lastEyePoint = Vec4.UNIT_W.transformBy4(this.modelviewInv);
        this.lastEyePosition = this.eyePosition;
        this.lastUpVector = Vec4.UNIT_Y.transformBy4(this.modelviewInv);
        this.lastForwardVector = Vec4.UNIT_NEGATIVE_Z.transformBy4(this.modelviewInv);
        this.horizonDistance = Double.MAX_VALUE; // Horizon distance doesn't make sense for the 2D globe/view.

        // Compute the current projection matrix and the frustum based on this view's perspective properties and the
        // current viewport. Note that the far clip distance must be computed before the near clip distance, since the
        // near clip distance depends on the far clip distance. Use the greater of the computed distance and its
        // respective minimum value.
        this.viewport = new Rectangle(0, 0, dc.getDrawableWidth(), dc.getDrawableHeight());
        this.farClipDistance = Math.max(this.computeFarClipDistance(), MINIMUM_FAR_DISTANCE);
        this.nearClipDistance = Math.max(this.computeNearClipDistance(), MINIMUM_NEAR_DISTANCE);
        this.projection = Matrix.fromPerspective(this.fieldOfView, this.viewport.width, this.viewport.height,
            this.nearClipDistance, this.farClipDistance);
        this.frustum = Frustum.fromProjectionMatrix(this.projection);
        this.lastFrustumInModelCoords = this.frustum.transformBy(this.modelview.getTranspose());

        // Set the current OpenGL modelview and projection matrix state to this view's modelview and projection
        // matrices, respectively.
        double[] matrixArray = new double[16];
        GL2 gl = dc.getGL().getGL2();
        gl.glMatrixMode(GL2.GL_PROJECTION);
        gl.glLoadMatrixd(this.projection.toArray(matrixArray, 0, false), 0);
        gl.glMatrixMode(GL2.GL_MODELVIEW);
        gl.glLoadMatrixd(this.modelview.toArray(matrixArray, 0, false), 0);
    }

    @Override
    protected double computeNearClipDistance()
    {
        // Compute the near clip distance in order to achieve a desired depth resolution at the far clip distance. This
        // distance automatically scales with the resolution of the OpenGL depth buffer.
        double farResolution = DEFAULT_DEPTH_RESOLUTION;
        int depthBits = this.dc.getGLRuntimeCapabilities().getDepthBits();
        double near = ViewUtil.computePerspectiveNearDistance(this.farClipDistance, farResolution, depthBits);

        // Return the lesser of the desired near distance and the height above the surface. We make a best effort to use
        // the desired near distance, but use surface height when the resultant near plane would clip the terrain.
        double height = ViewUtil.computeElevationAboveSurface(this.dc, this.eyePosition) - 1;
        return Math.min(near, height);
    }

    @Override
    protected double computeFarClipDistance()
    {
        // Return the distance from the eye point to lowest possible point on the globe, plus one.
        double minElevation = this.globe.getMinElevation() * this.dc.getVerticalExaggeration();
        return this.lastEyePoint.z - minElevation + MINIMUM_FAR_DISTANCE;
    }
}