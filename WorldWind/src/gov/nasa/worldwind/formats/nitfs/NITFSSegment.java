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
public class NITFSSegment
{
    protected java.nio.ByteBuffer buffer;
    protected NITFSSegmentType segmentType;
    protected int savedBufferOffset;
    
    protected int headerStartOffset;
    protected int headerLength;
    protected int dataStartOffset;
    protected int dataLength;

    public NITFSSegment(NITFSSegmentType segmentType, java.nio.ByteBuffer buffer,
        int headerStartOffset, int headerLength, int dataStartOffset, int dataLength)
    {
        this.buffer = buffer;
        this.segmentType = segmentType;
        this.headerStartOffset = headerStartOffset;
        this.headerLength = headerLength;
        this.dataStartOffset = dataStartOffset;
        this.dataLength = dataLength;
        this.savedBufferOffset = buffer.position();
    }

    protected void restoreBufferPosition()
    {
        this.buffer.position(this.savedBufferOffset);
    }
}

