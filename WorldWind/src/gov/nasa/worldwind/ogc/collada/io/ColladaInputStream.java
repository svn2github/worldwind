/*
 * Copyright (C) 2012 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.ogc.collada.io;

import gov.nasa.worldwind.util.Logging;

import java.io.*;

/**
 * @author pabercrombie
 * @version $Id$
 */
public class ColladaInputStream implements ColladaDoc
{
    /** The {@link java.io.InputStream} specified to the constructor. */
    protected InputStream inputStream;

    /**
     * Construct a <code>ColladaInputStream</code> instance.
     *
     * @param sourceStream the COLLADA stream.
     *
     * @throws IllegalArgumentException if the specified input stream is null.
     * @throws IOException              if an error occurs while attempting to read from the stream.
     */
    public ColladaInputStream(InputStream sourceStream) throws IOException
    {
        if (sourceStream == null)
        {
            String message = Logging.getMessage("nullValue.InputStreamIsNull");
            Logging.logger().severe(message);
            throw new IllegalArgumentException(message);
        }

        this.inputStream = sourceStream;
    }

    /**
     * Returns the input stream reference passed to the constructor.
     *
     * @return the input stream reference passed to the constructor.
     */
    public InputStream getInputStream() throws IOException
    {
        return this.inputStream;
    }
}
