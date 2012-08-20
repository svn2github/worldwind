/*
 * Copyright (C) 2012 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwindx.examples.openstreetmap;

import gov.nasa.worldwind.render.Renderable;

import java.io.*;
import java.util.*;

/**
 * A layer to display Open Street Map ways.
 *
 * @author tag
 * @version $Id$
 */
public class OSMWayLayer extends OSMAbstractLayer
{
    public OSMWayLayer(OSMShapeFactory shapeFactory)
    {
        super(shapeFactory);
    }

    @Override
    protected String getCacheFilePrefix()
    {
        return OSMCacheBuilder.WAY_FILE_PREFIX;
    }

    @Override
    protected List<Renderable> makeShapes(InputStream inputStream) throws IOException
    {
        List<Renderable> shapes = new ArrayList<Renderable>();

        if (inputStream.available() > 0)
        {
            OSMNodeProto.Way way = OSMNodeProto.Way.parseDelimitedFrom(inputStream);
            while (way != null)
            {
                OSMWayShape shape = this.shapeFactory.createShape(way);
                if (shape != null)
                    shapes.add(shape);

                way = OSMNodeProto.Way.parseDelimitedFrom(inputStream);
            }
        }

        return shapes;
    }

    @Override
    public String toString()
    {
        return "Open Street Map Ways";
    }
}
