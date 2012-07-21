/*
 * Copyright (C) 2012 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.util;

import java.awt.geom.*;
import java.util.*;

/**
 * Provides a mechanism to track the screen region of rendered items and determine whether that region overlaps with
 * regions already rendered. This filter is used by global text decluttering.
 *
 * @author tag
 * @version $Id$
 */
public class ClutterFilter
{
    /** Holds the rectangles of the regions already drawn. */
    protected List<Rectangle2D> rectList = new ArrayList<Rectangle2D>();

    /**
     * Adds a region to this filter to denote that the region has been rendered to and should not be rendered to again.
     *
     * @param rect the region to add.
     */
    public void addRegion(Rectangle2D rect)
    {
        if (rect == null)
        {
            String msg = Logging.getMessage("nullValue.RectangleIsNull");
            Logging.logger().fine(msg);
            throw new IllegalArgumentException(msg);
        }

        this.rectList.add(rect);
    }

    /**
     * Indicates whether a specified region intersects a region in the filter.
     *
     * @param rectangle the region to test.
     *
     * @return true if the region intersects one or more other regions in the filter, otherwise false.
     */
    public boolean intersects(Rectangle2D rectangle)
    {
        if (rectangle == null)
            return false;

        for (Rectangle2D rect : this.rectList)
        {
            if (rectangle.intersects(rect))
                return true;
        }

        return false;
    }
}
