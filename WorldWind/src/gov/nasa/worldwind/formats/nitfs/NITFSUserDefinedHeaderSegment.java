/*
 * Copyright (C) 2012 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.formats.nitfs;

/**
 * @author Lado Garakanidze
 * @version $Id$
 */
public abstract class NITFSUserDefinedHeaderSegment extends NITFSSegment
{
    protected  int overflow;
    protected  String dataTag;

    public NITFSUserDefinedHeaderSegment(java.nio.ByteBuffer buffer)
    {
        super(NITFSSegmentType.USER_DEFINED_HEADER_SEGMENT, buffer, 0, 0, 0, 0);

        this.headerLength = Integer.parseInt(NITFSUtil.getString(buffer, 5));
        this.overflow = Integer.parseInt(NITFSUtil.getString(buffer, 3));
        this.dataTag = NITFSUtil.getString(buffer, 6);
        this.dataLength = Integer.parseInt(NITFSUtil.getString(buffer, 5));
    }
}
