/*
 * Copyright (C) 2012 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.ogc.collada;

import java.util.*;

/**
 * Represents the Collada <i>Library_Geometries</i> element and provides access to its contents.
 *
 * @author pabercrombie
 * @version $Id$
 */
public class ColladaLibraryGeometries extends ColladaAbstractObject
{
    protected List<ColladaGeometry> geometries = new ArrayList<ColladaGeometry>();

    public ColladaLibraryGeometries(String ns)
    {
        super(ns);
    }

    public ColladaGeometry getGeometryByID(String urlForGeom)
    {
        for (ColladaGeometry geom : this.geometries)
        {
            Object id = geom.getField("id");
            if (id.equals(urlForGeom.substring(1)))
            {
                return geom;
            }
        }

        return null;
    }

    public List<ColladaGeometry> getGeometries()
    {
        return this.geometries;
    }

    @Override
    public void setField(String keyName, Object value)
    {
        if (keyName.equals("geometry"))
        {
            this.geometries.add((ColladaGeometry) value);
        }
        else
        {
            super.setField(keyName, value);
        }
    }
}
