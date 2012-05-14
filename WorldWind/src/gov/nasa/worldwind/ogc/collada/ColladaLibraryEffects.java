/*
 * Copyright (C) 2012 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.ogc.collada;

import java.util.*;

/**
 * Represents the Collada <i>Library_Effects</i> element and provides access to its contents.
 *
 * @author pabercrombie
 * @version $Id$
 */
public class ColladaLibraryEffects extends ColladaAbstractObject
{
    public ColladaLibraryEffects(String ns)
    {
        super(ns);
    }

    protected List<ColladaEffect> effects = new ArrayList<ColladaEffect>();

    public List<ColladaEffect> getEffects()
    {
        return this.effects;
    }

    @Override
    public void setField(String keyName, Object value)
    {
        if (keyName.equals("effect"))
        {
            this.effects.add((ColladaEffect) value);
        }
        else
        {
            super.setField(keyName, value);
        }
    }

    public ColladaEffect getEffectByName(String name)
    {
        for (ColladaEffect effect : effects)
        {
            if (effect.getField("id").equals(name.substring(1)))
            {
                return effect;
            }
        }

        return null;
    }
}
