/*
 * Copyright (C) 2012 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.ogc.collada;

import java.util.*;

/**
 * Represents the Collada <i>Library_Images</i> element and provides access to its contents.
 *
 * @author pabercrombie
 * @version $Id$
 */
public class ColladaLibraryImages extends ColladaAbstractObject
{
    public ColladaLibraryImages(String ns)
    {
        super(ns);
    }

    protected List<ColladaImage> images = new ArrayList<ColladaImage>();

    public List<ColladaImage> getNewParams()
    {
        return this.images;
    }

    @Override
    public void setField(String keyName, Object value)
    {
        if (keyName.equals("image"))
        {
            this.images.add((ColladaImage) value);
        }
        else
        {
            super.setField(keyName, value);
        }
    }

    public ColladaImage getImageByName(String name)
    {
        for (ColladaImage image : this.images)
        {
            if (image.getField("id").equals(name))
            {
                return image;
            }
        }

        return null;
    }
}
