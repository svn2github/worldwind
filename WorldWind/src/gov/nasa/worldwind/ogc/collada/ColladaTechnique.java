/*
 * Copyright (C) 2012 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.ogc.collada;

import java.util.*;

/**
 * Represents the Collada <i>Technique</i> element and provides access to its contents.
 *
 * @author pabercrombie
 * @version $Id$
 */
public class ColladaTechnique extends ColladaAbstractObject
{
    protected List<ColladaNewParam> params = new ArrayList<ColladaNewParam>();

    public ColladaTechnique(String ns)
    {
        super(ns);
    }

    public List<ColladaNewParam> getNewParams()
    {
        return this.params;
    }

    @Override
    public void setField(String keyName, Object value)
    {
        if (keyName.equals("newparam"))
        {
            this.params.add((ColladaNewParam) value);
        }
        else
        {
            super.setField(keyName, value);
        }
    }
}
