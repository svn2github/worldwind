/*
 * Copyright (C) 2012 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */
package gov.nasa.worldwind.cache;

/**
 * @author dcollins
 * @version $Id$
 */
public interface MemoryCacheSet
{
    MemoryCache get(String key);

    MemoryCache put(String key, MemoryCache cache);

    boolean contains(String key);

    void clear();
}
