/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.animation;

import gov.nasa.worldwind.util.*;

/**
 * @author dcollins
 * @version $Id$
 */
public class DurationInterpolator implements Interpolator
{
    protected long duration;
    protected boolean easeInEaseOut;
    protected long beginTime = -1;
    protected long endTime = -1;

    public DurationInterpolator(long duration, boolean easeInEaseOut)
    {
        if (duration < 0)
        {
            String msg = Logging.getMessage("generic.TimeNegative", duration);
            Logging.logger().severe(msg);
            throw new IllegalArgumentException(msg);
        }

        this.duration = duration;
        this.easeInEaseOut = easeInEaseOut;
    }

    @Override
    public double nextInterpolant()
    {
        long now = System.currentTimeMillis();

        if (this.beginTime < 0)
        {
            this.beginTime = now;
            this.endTime = this.beginTime + this.duration;
        }

        if (this.easeInEaseOut)
        {
            return WWMath.smoothStepValue(now, this.beginTime, this.endTime);
        }
        else
        {
            return WWMath.stepValue(now, this.beginTime, this.endTime);
        }
    }
}