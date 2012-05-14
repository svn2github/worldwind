/*
 * Copyright (C) 2012 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.ogc.collada;

import java.util.*;

/**
 * Represents the Collada <i>Technique_Common</i> element and provides access to its contents.
 *
 * @author pabercrombie
 * @version $Id$
 */
public class ColladaTechniqueCommon extends ColladaAbstractObject
{
    protected List<ColladaInstanceMaterial> materials = new ArrayList<ColladaInstanceMaterial>();

    public ColladaTechniqueCommon(String ns)
    {
        super(ns);
    }

    public List<ColladaInstanceMaterial> getMaterials()
    {
        return this.materials;
    }

    @Override
    public void setField(String keyName, Object value)
    {
        if (keyName.equals("instance_material"))
        {
            this.materials.add((ColladaInstanceMaterial) value);
        }
        else
        {
            super.setField(keyName, value);
        }
    }
}
