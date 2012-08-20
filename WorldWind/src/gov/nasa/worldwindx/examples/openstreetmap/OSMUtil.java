/*
 * Copyright (C) 2012 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwindx.examples.openstreetmap;

import org.openstreetmap.osmosis.core.domain.v0_6.*;

import java.util.List;

/**
 * A collection of utility methods for working with Open Street Map data.
 *
 * @author tag
 * @version $Id$
 */
public class OSMUtil
{
    /**
     * Indicates whether a specified node or way contains a specified key in its a/v list.
     *
     * @param entity  the node or way in question.
     * @param keyName the key to search for.
     *
     * @return true if the node or way contains the key, otherwise false. Returns null if either argument is null.
     */
    public static boolean containsTagKey(Entity entity, String keyName)
    {
        if (entity == null || keyName == null)
            return false;

        for (Tag tag : entity.getTags())
        {
            if (tag.getKey().equals(keyName))
                return true;
        }

        return false;
    }

    /**
     * Indicates whether a specified a/v list contains a specified key.
     *
     * @param tags    the a/v list.
     * @param keyName the key to search for.
     *
     * @return true if the a/v list contains the key, otherwise false. Returns null if either argument is null.
     */
    public static boolean containsTagKey(List<OSMNodeProto.Tag> tags, String keyName)
    {
        if (tags == null || keyName == null)
            return false;

        for (OSMNodeProto.Tag tag : tags)
        {
            if (tag.getKey().equals(keyName))
                return true;
        }

        return false;
    }

    /**
     * Indicates whether a specified node or way contains a specified key/value pair.
     *
     * @param entity   the node or way in question.
     * @param tagKey   the key to search for.
     * @param tagValue the value associated with the key.
     *
     * @return true if the node or way contains the specified key/value pair, otherwise false. Returns null if any
     *         argument is null.
     */
    public static boolean containsTag(Entity entity, String tagKey, String tagValue)
    {
        if (entity == null || tagKey == null || tagValue == null)
            return false;

        for (Tag tag : entity.getTags())
        {
            if (tag.getKey().equals(tagKey) && tag.getValue().equals(tagValue))
                return true;
        }

        return false;
    }

    /**
     * Returns the value associated with a specified key in a specified a/v/ list.
     *
     * @param tags    the a/v list to search.
     * @param keyName the key whose value to return.
     *
     * @return the value associated with the key, or null if the key is not in the list. Returns null if either argument
     *         is null.
     */
    public static String getValue(List<OSMNodeProto.Tag> tags, String keyName)
    {
        if (tags == null || keyName == null)
            return null;

        for (OSMNodeProto.Tag tag : tags)
        {
            if (tag.getKey().equals(keyName))
                return tag.getValue();
        }

        return null;
    }
}
