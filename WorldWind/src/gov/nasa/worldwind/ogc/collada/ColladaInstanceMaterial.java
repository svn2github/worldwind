/*
 * Copyright (C) 2012 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.ogc.collada;

/**
 * Represents the Collada <i>Instance_Material</i> element and provides access to its contents.
 *
 * @author pabercrombie
 * @version $Id$
 */
public class ColladaInstanceMaterial extends ColladaAbstractInstance<ColladaMaterial>
{
    public ColladaInstanceMaterial(String ns)
    {
        super(ns);
    }

    public String getTarget()
    {
        return (String) this.getField("target");
    }

    public String getSymbol()
    {
        return (String) this.getField("symbol");
    }

    /** Instance_material uses a "target" attribute instead of the "url" attribute used by other instance elements. */
    @Override
    public String getUrl()
    {
        return this.getTarget();
    }
}
