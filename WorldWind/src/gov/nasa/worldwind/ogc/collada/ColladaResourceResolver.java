/*
 * Copyright (C) 2012 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.ogc.collada;

import java.io.IOException;

/**
 * @author pabercrombie
 * @version $Id$
 */
public interface ColladaResourceResolver
{
    String resolveFilePath(String path) throws IOException;
}
