/*
 * Copyright (C) 2012 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.ogc.collada.io;

import java.io.*;

/**
 * @author pabercrombie
 * @version $Id$
 */
public interface ColladaDoc
{
    /**
     * Returns an {@link java.io.InputStream} to the associated Collada document.
     * <p/>
     * Implementations of this interface do not close the stream; the user of the class must close the stream.
     *
     * @return an input stream positioned to the head of the Collada document.
     *
     * @throws java.io.IOException if an error occurs while attempting to create or open the input stream.
     */
    InputStream getInputStream() throws IOException;
}
