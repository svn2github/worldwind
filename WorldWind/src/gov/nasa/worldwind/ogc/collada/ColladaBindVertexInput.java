/*
 * Copyright (C) 2012 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.ogc.collada;

/**
 * Represents the Collada <i>Bind_Vertex_Input</i> element and provides access to its contents.
 *
 * @author pabercrombie
 * @version $Id$
 */
public class ColladaBindVertexInput extends ColladaAbstractObject
{
    /**
     * Construct an instance.
     *
     * @param namespaceURI the qualifying namespace URI. May be null to indicate no namespace qualification.
     */
    public ColladaBindVertexInput(String namespaceURI)
    {
        super(namespaceURI);
    }

    public String getSemantic()
    {
        return (String) this.getField("semantic");
    }

    public String getInputSemantic()
    {
        return (String) this.getField("input_semantic");
    }
}
