/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.view;

import gov.nasa.worldwind.View;
import gov.nasa.worldwind.animation.*;
import gov.nasa.worldwind.avlist.AVKey;
import gov.nasa.worldwind.geom.*;
import gov.nasa.worldwind.globes.Globe;

/**
 * @author dcollins
 * @version $Id$
 */
public class ViewTranslationAnimator extends BasicAnimator
{
    protected View view;
    protected Vec4 translation;
    protected Matrix beginModelview;

    public ViewTranslationAnimator(View view, Vec4 translation, long duration, boolean easeInEaseOut)
    {
        super(new DurationInterpolator(duration, easeInEaseOut));

        this.view = view;
        this.translation = translation;
        this.beginModelview = view.getModelviewMatrix();
    }

    @Override
    protected void setImpl(double interpolant)
    {
        Vec4 vector = this.translation.multiply3(interpolant);
        Matrix matrix = Matrix.fromTranslation(vector);
        Matrix modelview = this.beginModelview.multiply(matrix);

        // Compute the eye point and eye position corresponding to the specified modelview matrix.
        Globe globe = this.view.getGlobe();
        Vec4 eyePoint = Vec4.UNIT_W.transformBy4(modelview.getInverse());
        Position eyePos = globe.computePositionFromPoint(eyePoint);

        // Transform the modelview matrix to the local coordinate origin at the specified eye position. The result is a
        // matrix relative to the local origin, who's z rotation angle is the desired heading in view local coordinates.
        Matrix modelviewLocal = modelview.multiply(globe.computeModelCoordinateOriginTransform(eyePos));
        Angle heading = modelviewLocal.getRotationZ();

        // Apply the eye position and heading that will result in the desired modelview matrix.
        this.view.setEyePosition(eyePos);
        this.view.setHeading(heading);
        this.view.firePropertyChange(AVKey.VIEW, null, this.view);

        if (interpolant >= 1)
        {
            this.stop();
        }
    }
}