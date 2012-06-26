/*
 * Copyright (C) 2012 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.util;

import junit.framework.TestCase;
import org.junit.Test;

/**
 * Unit tests for the {@link EntityMap} class.
 *
 * @author pabercrombie
 * @version $Id$
 */
public class EntityMapTest
{
    /** Test basic entity replacement. */
    @Test
    public void testReplace()
    {
        String expected = "text < > & more text";
        String actual = EntityMap.replaceAll("text &lt; &gt; &amp; more text");

        TestCase.assertEquals(expected, actual);
    }

    /** Test with a missing entity. (Missing entity should NOT be replaced.) */
    @Test
    public void testMissingEntity()
    {
        String expected = "text &thisIsNotAnEntity; more text";
        String actual = EntityMap.replaceAll(expected);

        TestCase.assertEquals(expected, actual);
    }

    public static void main(String[] args)
    {
        new junit.textui.TestRunner().doRun(new junit.framework.TestSuite(EntityMapTest.class));
    }
}
