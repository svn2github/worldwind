/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.ogc.ows;

import gov.nasa.worldwind.util.xml.*;

import javax.xml.stream.XMLStreamException;
import javax.xml.stream.events.XMLEvent;
import java.util.*;

/**
 * @author tag
 * @version $Id$
 */
public class OWSOperation extends AbstractXMLEventParser
{
    // TODO: Operation Metadata element

    protected Set<OWSDCP> dcps = new HashSet<OWSDCP>(2);
    protected Set<OWSParameter> parameters = new HashSet<OWSParameter>(1);
    protected Set<OWSConstraint> constraints = new HashSet<OWSConstraint>(1);

    public OWSOperation(String namespaceURI)
    {
        super(namespaceURI);
    }

    public String getName()
    {
        return (String) this.getField("name");
    }

    public Set<OWSDCP> getDCPs()
    {
        return this.dcps;
    }

    public Set<OWSParameter> getParameters()
    {
        return this.parameters;
    }

    public Set<OWSConstraint> getConstraints()
    {
        return this.constraints;
    }

    protected void doParseEventContent(XMLEventParserContext ctx, XMLEvent event, Object... args)
        throws XMLStreamException
    {
        if (ctx.isStartElement(event, "DCP"))
        {
            XMLEventParser parser = this.allocate(ctx, event);
            if (parser != null)
            {
                Object o = parser.parse(ctx, event, args);
                if (o != null && o instanceof OWSDCP)
                    this.dcps.add((OWSDCP) o);
            }
        }
        else if (ctx.isStartElement(event, "Parameter"))
        {
            XMLEventParser parser = this.allocate(ctx, event);
            if (parser != null)
            {
                Object o = parser.parse(ctx, event, args);
                if (o != null && o instanceof OWSParameter)
                    this.parameters.add((OWSParameter) o);
            }
        }
        else if (ctx.isStartElement(event, "Constraint"))
        {
            XMLEventParser parser = this.allocate(ctx, event);
            if (parser != null)
            {
                Object o = parser.parse(ctx, event, args);
                if (o != null && o instanceof OWSConstraint)
                    this.constraints.add((OWSConstraint) o);
            }
        }
        else
        {
            super.doParseEventContent(ctx, event, args);
        }
    }
}
