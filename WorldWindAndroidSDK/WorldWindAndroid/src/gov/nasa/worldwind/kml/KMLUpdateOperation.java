/*
 * Copyright (C) 2012 DreamHammer.com
 */

package gov.nasa.worldwind.kml;

/**
 * @author tag
 * @version $Id$
 */
public interface KMLUpdateOperation
{
    public void applyOperation(KMLRoot operationsRoot);
}