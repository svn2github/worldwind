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
 * A layer to display Open Street Map nodes.
 *
 * @author tag
 * @version $Id$
 */
public class OSMNodeLayer extends OSMAbstractLayer
{
    public OSMNodeLayer(OSMShapeFactory shapeFactory)
    {
        super(shapeFactory);
    }

    @Override
    protected String getCacheFilePrefix()
    {
        return OSMCacheBuilder.NODE_FILE_PREFIX;
    }

    protected List<Renderable> makeShapes(InputStream inputStream) throws IOException
    {
        List<Renderable> shapes = new ArrayList<Renderable>();

        if (inputStream.available() > 0)
        {
            OSMNodeProto.Node node = OSMNodeProto.Node.parseDelimitedFrom(inputStream);
            while (node != null)
            {
                OSMNodeShape shape = this.shapeFactory.createShape(node);
                if (shape != null)
                    shapes.add(shape);

                node = OSMNodeProto.Node.parseDelimitedFrom(inputStream);
            }
        }

        return shapes;
    }

    @Override
    public String toString()
    {
        return "Open Street Map Nodes";
    }
}
