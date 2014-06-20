/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */
package gov.nasa.worldwind.util;

/**
 * Range describes a contiguous region in a series of items. Ranges are typically used to describe a subset of a
 * java.nio.Buffer when creating a slice is inappropriate.
 *
 * @author dcollins
 * @version $Id$
 */
public class Range
{
    /** The start index of the range. 0 indicates the first item in the series. */
    public int location;
    /** The number of items in the range. May be 0 to indicate an empty range. */
    public int length;

    /**
     * Creates a new range with the specified start index and number of items.
     *
     * @param location The start index of the range.
     * @param length The number of items in the range. May be 0 to indicate an empty range.
     */
    public Range(int location, int length)
    {
        this.location = location;
        this.length = length;
    }
}