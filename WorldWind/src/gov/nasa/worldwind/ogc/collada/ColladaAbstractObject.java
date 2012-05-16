/*
 * Copyright (C) 2012 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.ogc.collada;

import gov.nasa.worldwind.util.xml.*;

/**
 * Base class for Collada parser classes.
 *
 * @author pabercrombie
 * @version $Id$
 */
public abstract class ColladaAbstractObject extends AbstractXMLEventParser
{
    /**
     * Construct an instance.
     *
     * @param namespaceURI the qualifying namespace URI. May be null to indicate no namespace qualification.
     */
    protected ColladaAbstractObject(String namespaceURI)
    {
        super(namespaceURI);
    }

    @Override
    public ColladaRoot getRoot()
    {
        XMLEventParser root = super.getRoot();
        return root instanceof ColladaRoot ? (ColladaRoot) root : null;
    }
}
