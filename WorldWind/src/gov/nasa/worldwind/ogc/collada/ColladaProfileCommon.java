/*
 * Copyright (C) 2012 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.ogc.collada;

import java.util.*;

/**
 * Represents the Collada <i>Profile_COMMON</i> element and provides access to its contents.
 *
 * @author pabercrombie
 * @version $Id$
 */
public class ColladaProfileCommon extends ColladaAbstractObject
{
    protected List<ColladaNewParam> newParams = new ArrayList<ColladaNewParam>();

    public ColladaProfileCommon(String ns)
    {
        super(ns);
    }

    public ColladaTechnique getTechnique()
    {
        return (ColladaTechnique) this.getField("technique");
    }

    public List<ColladaNewParam> getNewParams()
    {
        return this.newParams;
    }

    @Override
    public void setField(String keyName, Object value)
    {
        if ("newParam".equals(keyName))
        {
            this.newParams.add((ColladaNewParam) value);
        }
        else
        {
            super.setField(keyName, value);
        }
    }
}
