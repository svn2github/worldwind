/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.view;

import gov.nasa.worldwind.View;
import gov.nasa.worldwind.animation.*;
import gov.nasa.worldwind.avlist.AVKey;
import gov.nasa.worldwind.awt.*;
import gov.nasa.worldwind.geom.*;
import gov.nasa.worldwind.globes.Globe;
import gov.nasa.worldwind.terrain.SectorGeometryList;

import java.awt.*;
import java.awt.event.*;
import java.beans.PropertyChangeEvent;

/**
 * TODO: avoid moving the eye beneath the terrain TODO: avoid moving the eye beyond the map boundary
 *
 * @author dcollins
 * @version $Id$
 */
public class View2DInputHandler extends AbstractViewInputHandler
{
    protected double panPixelsPerSecond = 500;
    protected double zoomPixelsPerSecond = 3000;
    protected double zoomPixelsPerScrollUnit = 25;
    protected double zoomToPixelsPerSecond = 3000;
    protected double rotateDegreesPerSecond = 90;
    protected double rotateToDegreesPerSecond = 270;
    protected double slowModifier = 0.25;

    protected int mouseBeginButton;
    protected Vec4 mouseBeginScreenPoint;
    protected Vec4 mouseScreenPoint;
    protected Vec4 mouseScreenTranslation;
    protected Vec4 mouseBeginPoint;
    protected Vec4 mouseBeginNormal;
    protected Vec4 mouseBeginEyeVector;
    protected Matrix mouseBeginModelview;

    protected AnimationController animationController = new AnimationController();
    protected long animationUniqueId;

    public View2DInputHandler()
    {
        this.setPerFrameInputInterval(30); // perform per frame input at 33hz; Mac OS X interval is typically 32-33
    }

    @Override
    public void goTo(Position lookAtPos, double elevation)
    {
        // TODO
    }

    @Override
    public void stopAnimators()
    {
        this.animationController.stopAnimations();
        this.animationController.clear();
    }

    @Override
    public boolean isAnimating()
    {
        return this.animationController.hasActiveAnimation();
    }

    @Override
    public void addAnimator(Animator animator)
    {
        if (animator == null)
            return;

        String name = String.valueOf(++this.animationUniqueId);
        this.animationController.put(name, animator);
    }

    @Override
    protected boolean handlePerFrameAnimation(String target)
    {
        super.handlePerFrameAnimation(target);

        if (GENERATE_EVENTS.equals(target))
        {
            if (this.animationController.stepAnimators())
            {
                return true;
            }
            else
            {
                this.animationController.clear();
                return false;
            }
        }
        else
        {
            return this.animationController.hasActiveAnimation();
        }
    }

    /******************************************************************************************************************/
    /** Property Change Events **/
    /** ************************************************************************************************************* */

    protected void handlePropertyChange(PropertyChangeEvent e)
    {
        super.handlePropertyChange(e);

        if (View.VIEW_STOPPED.equals(e.getPropertyName()))
        {
            this.stopAnimators();
        }
    }

    /******************************************************************************************************************/
    /** Keyboard Events **/
    /** ************************************************************************************************************* */

    @Override
    protected void handleKeyPressed(KeyEvent e)
    {
        super.handleKeyPressed(e);

        if (e.getKeyCode() == KeyEvent.VK_N || e.getKeyCode() == KeyEvent.VK_R)
        {
            this.stopAnimators();
            this.rotateToHeading(Angle.ZERO);
        }
        else if (e.getKeyCode() == KeyEvent.VK_SPACE)
        {
            this.stopAnimators();
        }
    }

    @Override
    protected boolean handlePerFrameKeyState(KeyEventState keys, String target)
    {
        super.handlePerFrameKeyState(keys, target);

        if (this.keyEventState.getNumButtonsDown() > 0)
        {
            return false; // ignore per-frame key events while a mouse drag is active
        }

        double slowScale = (keys.getModifiersEx() & KeyEvent.ALT_DOWN_MASK) != 0 ? this.slowModifier : 1;

        if (keys.isKeyDown(KeyEvent.VK_LEFT) || keys.isKeyDown(KeyEvent.VK_RIGHT)
            || keys.isKeyDown(KeyEvent.VK_DOWN) || keys.isKeyDown(KeyEvent.VK_UP))
        {
            if (GENERATE_EVENTS.equals(target))
            {
                int dx = keys.keyState(KeyEvent.VK_RIGHT) - keys.keyState(KeyEvent.VK_LEFT);
                int dy = keys.keyState(KeyEvent.VK_UP) - keys.keyState(KeyEvent.VK_DOWN);
                this.stopAnimators();

                if ((keys.getModifiersEx() & KeyEvent.SHIFT_DOWN_MASK) != 0)
                {
                    this.rotateWithKeys(new Vec4(dx, dy, 0).normalize3().multiply3(slowScale));
                }
                else if ((keys.getModifiersEx() & KeyEvent.CTRL_DOWN_MASK) != 0 &&
                    (keys.isKeyDown(KeyEvent.VK_DOWN) || keys.isKeyDown(KeyEvent.VK_UP)))
                {
                    this.zoomWithKeys(new Vec4(0, 0, dy).multiply3(slowScale));
                }
                else
                {
                    this.panWithKeys(new Vec4(dx, dy, 0).normalize3().multiply3(slowScale));
                }
            }

            return true;
        }
        else if (keys.isKeyDown(KeyEvent.VK_ADD) || keys.isKeyDown(KeyEvent.VK_SUBTRACT))
        {
            if (GENERATE_EVENTS.equals(target))
            {
                int dz = keys.keyState(KeyEvent.VK_ADD) - keys.keyState(KeyEvent.VK_SUBTRACT);
                this.stopAnimators();
                this.zoomWithKeys(new Vec4(0, 0, dz).multiply3(slowScale));
            }

            return true;
        }
        else if (keys.isKeyDown(KeyEvent.VK_EQUALS) || keys.isKeyDown(KeyEvent.VK_MINUS))
        {
            if (GENERATE_EVENTS.equals(target))
            {
                int dz = keys.keyState(KeyEvent.VK_EQUALS) - keys.keyState(KeyEvent.VK_MINUS);
                this.stopAnimators();
                this.zoomWithKeys(new Vec4(0, 0, dz).multiply3(slowScale));
            }

            return true;
        }

        return false;
    }

    /******************************************************************************************************************/
    /** Mouse Events **/
    /** ************************************************************************************************************* */

    @Override
    protected void handleMousePressed(MouseEvent e)
    {
        if (this.keyEventState.getNumButtonsDown() == 1) // setup the mouse state when the fist button is pressed
        {
            Vec4 surfacePoint = this.getSurfacePointAtCursor(); // try to use the surface point under the cursor
            if (surfacePoint == null)
            {
                surfacePoint = this.getSurfacePointAtCenter(); // fall back to the surface point at the screen center
            }

            if (surfacePoint == null)
            {
                return; // the cursor and the screen center are both off the globe
            }

            Globe globe = this.getWorldWindow().getModel().getGlobe();
            Point p = constrainToSourceBounds(e.getPoint(), this.getWorldWindow());
            this.mouseBeginButton = e.getButton();
            this.mouseBeginScreenPoint = new Vec4(p.x, p.y, 0);
            this.mouseScreenPoint = new Vec4(p.x, p.y, 0);
            this.mouseScreenTranslation = new Vec4(0, 0, 0);
            this.mouseBeginPoint = surfacePoint;
            this.mouseBeginNormal = globe.computeSurfaceNormalAtPoint(this.mouseBeginPoint);
            this.mouseBeginEyeVector = this.getView().getEyePoint().subtract3(this.mouseBeginPoint);
            this.mouseBeginModelview = this.getView().getModelviewMatrix();
        }

        super.handleMousePressed(e); // process per-frame mouse state after updating current mouse state
    }

    @Override
    protected void handleMouseReleased(MouseEvent e)
    {
        if (this.keyEventState.getNumButtonsDown() == 0) // clear the mouse state when the last button is released
        {
            this.mouseBeginButton = 0;
            this.mouseBeginScreenPoint = null;
            this.mouseScreenPoint = null;
            this.mouseScreenTranslation = null;
            this.mouseBeginPoint = null;
            this.mouseBeginNormal = null;
            this.mouseBeginEyeVector = null;
            this.mouseBeginModelview = null;
        }

        super.handleMouseReleased(e); // process per-frame mouse state after updating current mouse state
    }

    @Override
    protected void handleMouseDragged(MouseEvent e)
    {
        super.handleMouseDragged(e);

        if (this.mouseBeginScreenPoint != null)
        {
            Point p = constrainToSourceBounds(e.getPoint(), this.getWorldWindow());
            this.mouseScreenPoint = new Vec4(p.x, p.y, 0);
            this.mouseScreenTranslation = this.mouseScreenPoint.subtract3(this.mouseBeginScreenPoint);
        }
    }

    @Override
    protected void handleMouseClicked(MouseEvent e)
    {
        super.handleMouseClicked(e);

        Position pos = this.getWorldWindow().getCurrentPosition();
        if (pos != null && e.getClickCount() == 2)
        {
            this.stopAnimators();
            this.zoomToPosition(pos);
        }
    }

    @Override
    protected void handleMouseWheelMoved(MouseWheelEvent e)
    {
        super.handleMouseWheelMoved(e);

        if (this.keyEventState.getNumButtonsDown() > 0)
        {
            return; // ignore mouse wheel events while a mouse drag is active
        }

        this.stopAnimators();
        this.zoomWithMouseWheel(new Vec4(0, 0, e.getWheelRotation()));
    }

    @Override
    protected boolean handlePerFrameMouseState(KeyEventState keys, String target)
    {
        super.handlePerFrameMouseState(keys, target);

        if (this.mouseBeginButton == MouseEvent.BUTTON1)
        {
            if (GENERATE_EVENTS.equals(target))
            {
                this.stopAnimators();

                if ((keys.getModifiersEx() & KeyEvent.SHIFT_DOWN_MASK) != 0)
                {
                    this.rotateWithMouse(this.mouseScreenTranslation);
                }
                else if ((keys.getModifiersEx() & KeyEvent.CTRL_DOWN_MASK) != 0)
                {
                    this.zoomWithMouse(this.mouseScreenTranslation);
                }
                else if ((keys.getModifiersEx() & KeyEvent.META_DOWN_MASK) != 0)
                {
                    this.zoomWithMouse(this.mouseScreenTranslation);
                }
                else
                {
                    this.panWithMouse(this.mouseScreenTranslation);
                }
            }

            return true;
        }
        else if (this.mouseBeginButton == MouseEvent.BUTTON2)
        {
            if (GENERATE_EVENTS.equals(target))
            {
                this.stopAnimators();
                this.zoomWithMouse(this.mouseScreenTranslation);
            }

            return true;
        }
        else if (this.mouseBeginButton == MouseEvent.BUTTON3)
        {
            if (GENERATE_EVENTS.equals(target))
            {
                this.stopAnimators();
                this.rotateWithMouse(this.mouseScreenTranslation);
            }

            return true;
        }

        return false;
    }

    /******************************************************************************************************************/
    /** Navigation Interface **/
    /** ************************************************************************************************************* */

    protected void panWithMouse(Vec4 translation)
    {
        if (this.mouseBeginPoint == null)
        {
            return; // the cursor and the screen center are both off the globe
        }

        // Convert the translation vector from screen coordinates to eye coordinates.
        double metersPerPixel = this.getView().computePixelSizeAtDistance(this.mouseBeginEyeVector.getLength3());
        translation = new Vec4(translation.x, -translation.y, 0).multiply3(metersPerPixel);

        // Convert the translation vector from eye coordinates to model coordinates.
        translation = translation.transformBy3(this.getView().getModelviewMatrix().getInverse());

        // Apply the translation vector to the modelview matrix and set the view's properties from the result.
        Matrix modelview = this.mouseBeginModelview;
        modelview = modelview.multiply(Matrix.fromTranslation(translation));
        this.setToModelview(modelview);
    }

    protected void panWithKeys(Vec4 translation)
    {
        Vec4 surfacePoint = this.getSurfacePointAtCenter(); // try the surface point at the center of the screen
        if (surfacePoint == null)
        {
            surfacePoint = this.getSurfacePointUnderEye();  // fall back to the surface point under the eye
        }

        if (surfacePoint == null)
        {
            return; // the screen center and the eye point are both off the globe
        }

        // Convert the translation vector from a unitless direction to eye coordinates.
        Vec4 eyePoint = this.getView().getEyePoint();
        double metersPerPixel = this.getView().computePixelSizeAtDistance(eyePoint.distanceTo3(surfacePoint));
        double seconds = this.getPerFrameInputInterval() / 1000.0;
        double meters = metersPerPixel * this.panPixelsPerSecond * seconds;
        translation = new Vec4(-translation.x, -translation.y, 0).multiply3(meters);

        // Convert the translation vector from eye coordinates to model coordinates.
        translation = translation.transformBy3(this.getView().getModelviewMatrix().getInverse());

        // Apply the translation vector to the modelview matrix and set the view's properties from the result.
        Matrix modelview = this.getView().getModelviewMatrix();
        modelview = modelview.multiply(Matrix.fromTranslation(translation));
        this.setToModelview(modelview);
    }

    protected void zoomWithMouse(Vec4 translation)
    {
        if (this.mouseBeginPoint == null)
        {
            return; // the cursor and the screen center are both off the globe
        }

        // TODO: Needs to respond with a scale
        // Convert the translation vector from screen coordinates to model coordinates.
        double metersPerPixel = this.getView().computePixelSizeAtDistance(this.mouseBeginEyeVector.getLength3());
        double pixels = translation.y;
        double meters = 3 * metersPerPixel * pixels;
        translation = this.mouseBeginEyeVector.normalize3().multiply3(meters);

        // Apply the translation vector to the modelview matrix and set the view's properties from the result.
        Matrix modelview = this.mouseBeginModelview;
        modelview = modelview.multiply(Matrix.fromTranslation(translation));
        this.setToModelview(modelview);
    }

    protected void zoomWithMouseWheel(Vec4 translation)
    {
        Vec4 surfacePoint = this.getSurfacePointAtCursor(); // try the surface point under the cursor
        if (surfacePoint == null)
        {
            surfacePoint = this.getSurfacePointAtCenter();  // fall back to the surface point at the screen center
        }

        if (surfacePoint == null)
        {
            return; // the cursor and the screen center are both off the globe
        }

        // Convert the translation vector from mouse wheel units to model coordinates.
        Vec4 eyePoint = this.getView().getEyePoint();
        double metersPerPixel = this.getView().computePixelSizeAtDistance(eyePoint.distanceTo3(surfacePoint));
        double scrollUnits = translation.z;
        double meters = metersPerPixel * this.zoomPixelsPerScrollUnit * scrollUnits;
        translation = surfacePoint.subtract3(eyePoint).normalize3().multiply3(meters);

        // Apply the translation vector to the modelview matrix and set the view's properties from the result.
        Matrix modelview = this.getView().getModelviewMatrix();
        modelview = modelview.multiply(Matrix.fromTranslation(translation));
        this.setToModelview(modelview);
    }

    protected void zoomWithKeys(Vec4 translation)
    {
        Vec4 surfacePoint = this.getSurfacePointAtCenter();
        if (surfacePoint == null)
        {
            return; // the screen center is off the globe
        }

        // Convert the translation vector from a unitless direction to model coordinates.
        Vec4 eyePoint = this.getView().getEyePoint();
        double metersPerPixel = this.getView().computePixelSizeAtDistance(eyePoint.distanceTo3(surfacePoint));
        double pixels = -translation.z;
        double seconds = this.getPerFrameInputInterval() / 1000.0;
        double meters = metersPerPixel * pixels * this.zoomPixelsPerSecond * seconds;
        translation = surfacePoint.subtract3(eyePoint).normalize3().multiply3(meters);

        // Apply the translation vector to the modelview matrix and set the view's properties from the result.
        Matrix modelview = this.getView().getModelviewMatrix();
        modelview = modelview.multiply(Matrix.fromTranslation(translation));
        this.setToModelview(modelview);
    }

    protected void zoomToPosition(Position position)
    {
        // Compute the translation in model coordinates to necessary to move the viewer 1/2 the distance from the eye
        // point to the specified position.
        // TODO: handle 2D globe dateline correctly
        Globe globe = this.getWorldWindow().getModel().getGlobe();
        Vec4 eyePoint = this.getView().getEyePoint();
        Vec4 point = globe.computePointFromPosition(position);
        Vec4 translation = point.subtract3(eyePoint).multiply3(-0.5);

        // Compute an animation duration based on a desired velocity in screen pixels per second.
        double metersPerPixel = this.getView().computePixelSizeAtDistance(eyePoint.distanceTo3(point));
        double metersPerSecond = metersPerPixel * this.zoomToPixelsPerSecond;
        double seconds = translation.getLength3() / metersPerSecond;

        // Add an animator that applies the translation vector to the modelview matrix over the computed duration.
        this.addAnimator(new ViewTranslationAnimator(this.getView(), translation, (long) (seconds * 1000), true));
        this.getView().firePropertyChange(AVKey.VIEW, null, this.getView());
    }

    protected void rotateWithMouse(Vec4 translation)
    {
        if (this.mouseBeginPoint == null)
        {
            return; // the cursor and the screen center are both off the globe
        }

        // Convert the translation from screen coordinates to a rotation in eye coordinates.
        double headingDegrees = 180.0 * -translation.x / ((Component) this.getWorldWindow()).getWidth();
        Angle headingAngle = Angle.fromDegrees(headingDegrees);

        // Compute the rotation point and rotation axis in model coordinates.
        Vec4 point = this.mouseBeginPoint;
        Vec4 normal = this.mouseBeginNormal;

        // Apply the rotation the modelview matrix and set the view's properties from the result.
        Matrix modelview = this.mouseBeginModelview;
        modelview = modelview.multiply(Matrix.fromTranslation(point.x, point.y, point.z));
        modelview = modelview.multiply(Matrix.fromAxisAngle(headingAngle, normal));
        modelview = modelview.multiply(Matrix.fromTranslation(-point.x, -point.y, -point.z));
        this.setToModelview(modelview);
    }

    protected void rotateWithKeys(Vec4 translation)
    {
        Vec4 point = this.getSurfacePointAtCenter();
        if (point == null)
        {
            return; // the screen center is off the globe
        }

        // Convert the translation vector from a unitless direction to a rotation in eye coordinates.
        double seconds = this.getPerFrameInputInterval() / 1000.0;
        double headingDegrees = translation.x * this.rotateDegreesPerSecond * seconds;
        Angle headingAngle = Angle.fromDegrees(headingDegrees);

        // Compute the rotation point and rotation axis in model coordinates.
        Globe globe = this.getWorldWindow().getModel().getGlobe();
        Vec4 normal = globe.computeSurfaceNormalAtPoint(point);

        // Apply the rotation the modelview matrix and set the view's properties from the result.
        Matrix modelview = this.getView().getModelviewMatrix();
        modelview = modelview.multiply(Matrix.fromTranslation(point.x, point.y, point.z));
        modelview = modelview.multiply(Matrix.fromAxisAngle(headingAngle, normal));
        modelview = modelview.multiply(Matrix.fromTranslation(-point.x, -point.y, -point.z));
        this.setToModelview(modelview);
    }

    protected void rotateToHeading(Angle heading)
    {
        // Compute an animation duration based on a desired velocity in degrees per second.
        double degrees = this.getView().getHeading().angularDistanceTo(heading).degrees;
        double seconds = degrees / this.rotateToDegreesPerSecond;

        // Add an animator that applies the heading change to the view over the computed duration.
        this.addAnimator(new ViewHeadingAnimator(this.getView(), heading, (long) (seconds * 1000), true));
        this.getView().firePropertyChange(AVKey.VIEW, null, this.getView());
    }

    protected void setToModelview(Matrix modelview)
    {
        // Compute the eye point and eye position corresponding to the specified modelview matrix.
        Globe globe = this.getWorldWindow().getModel().getGlobe();
        Vec4 eyePoint = Vec4.UNIT_W.transformBy4(modelview.getInverse());
        Position eyePos = globe.computePositionFromPoint(eyePoint);

        // Transform the modelview matrix to the local coordinate origin at the specified eye position. The result is a
        // matrix relative to the local origin, who's z rotation angle is the desired heading in view local coordinates.
        Matrix modelviewLocal = modelview.multiply(globe.computeModelCoordinateOriginTransform(eyePos));
        Angle heading = modelviewLocal.getRotationZ();

        // Apply the eye position and heading that will result in the desired modelview matrix.
        this.getView().setEyePosition(eyePos);
        this.getView().setHeading(heading);
        this.getView().firePropertyChange(AVKey.VIEW, null, this.getView());
    }

    protected Vec4 getSurfacePointAtCursor()
    {
        Globe globe = this.getWorldWindow().getModel().getGlobe();
        Position pos = this.getWorldWindow().getCurrentPosition();
        return pos != null ? globe.computePointFromPosition(pos) : null;
    }

    protected Vec4 getSurfacePointAtCenter()
    {
        View view = this.getView();
        Line ray = new Line(view.getEyePoint(), view.getForwardVector());

        // TODO: Repair terrain-line intersection on flat globe
        //SectorGeometryList sgeom = this.getWorldWindow().getSceneController().getTerrain();
        //if (sgeom != null)
        //{
        //    Intersection[] intersections = sgeom.intersect(ray);
        //    if (intersections != null)
        //    {
        //        return intersections[0].getIntersectionPoint();
        //    }
        //}

        Globe globe = this.getWorldWindow().getModel().getGlobe();
        Intersection[] intersections = globe.intersect(ray);
        return intersections != null ? intersections[0].getIntersectionPoint() : null;
    }

    protected Vec4 getSurfacePointUnderEye()
    {
        Position eyePos = this.getView().getEyePosition();

        SectorGeometryList sgeom = this.getWorldWindow().getSceneController().getTerrain();
        if (sgeom != null)
        {
            Vec4 point = sgeom.getSurfacePoint(eyePos.latitude, eyePos.longitude, 0);
            if (point != null)
            {
                return point;
            }
        }

        Globe globe = this.getWorldWindow().getModel().getGlobe();
        double ve = this.getWorldWindow().getSceneController().getVerticalExaggeration();
        double elev = globe.getElevation(eyePos.latitude, eyePos.longitude);
        return globe.computePointFromPosition(eyePos.latitude, eyePos.longitude, elev * ve);
    }
}