/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.view;

import gov.nasa.worldwind.View;
import gov.nasa.worldwind.animation.*;
import gov.nasa.worldwind.avlist.AVKey;
import gov.nasa.worldwind.geom.Angle;

/**
 * @author dcollins
 * @version $Id$
 */
public class ViewHeadingAnimator extends BasicAnimator
{
    protected View view;
    protected Angle beginHeading;
    protected Angle endHeading;

    public ViewHeadingAnimator(View view, Angle heading, long duration, boolean easeInEaseOut)
    {
        this.view = view;
        this.beginHeading = view.getHeading();
        this.endHeading = heading;
        this.interpolator = new DurationInterpolator(duration, easeInEaseOut);
    }

    @Override
    protected void setImpl(double interpolant)
    {
        if (interpolant < 1)
        {
            Angle heading = Angle.mix(interpolant, this.beginHeading, this.endHeading);
            this.view.setHeading(heading);
            this.view.firePropertyChange(AVKey.VIEW, null, this.view);
        }
        else
        {
            this.view.setHeading(this.endHeading);
            this.view.firePropertyChange(AVKey.VIEW, null, this.view);
            this.stop();
        }
    }
}