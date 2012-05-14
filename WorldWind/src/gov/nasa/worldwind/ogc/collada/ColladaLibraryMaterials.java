/*
 * Copyright (C) 2012 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.ogc.collada;

import java.util.*;

/**
 * Represents the Collada <i>Library_Materials</i> element and provides access to its contents.
 *
 * @author pabercrombie
 * @version $Id$
 */
public class ColladaLibraryMaterials extends ColladaAbstractObject
{
    protected List<ColladaMaterial> materials = new ArrayList<ColladaMaterial>();

    public ColladaLibraryMaterials(String ns)
    {
        super(ns);
    }

    public List<ColladaMaterial> getMaterials()
    {
        return this.materials;
    }

    @Override
    public void setField(String keyName, Object value)
    {
        if (keyName.equals("material"))
        {
            this.materials.add((ColladaMaterial) value);
        }
        else
        {
            super.setField(keyName, value);
        }
    }

    public ColladaMaterial getMaterialByName(String name)
    {
        for (ColladaMaterial material : this.materials)
        {

            if (material.getField("id").equals(name))
            {
                return material;
            }
        }

        return null;
    }
}
