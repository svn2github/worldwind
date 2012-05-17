/*
 * Copyright (C) 2012 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.ogc.collada;

import gov.nasa.worldwind.util.*;
import gov.nasa.worldwind.util.xml.XMLEventParserContext;

import javax.xml.stream.XMLStreamException;
import javax.xml.stream.events.*;
import java.nio.FloatBuffer;
import java.util.*;

/**
 * Represents the Collada <i>Accessor</i> element and provides access to its contents.
 *
 * @author pabercrombie
 * @version $Id$
 */
public class ColladaAccessor extends ColladaAbstractObject
{
    /** Parameters used by this accessor. */
    protected List<ColladaParam> params = new ArrayList<ColladaParam>();

    /**
     * Create a new accessor.
     *
     * @param ns Namespace.
     */
    public ColladaAccessor(String ns)
    {
        super(ns);
    }

    /**
     * Get the identifier of this accessor's source.
     *
     * @return Accessor source.
     */
    public String getSource()
    {
        return (String) this.getField("source");
    }

    /**
     * Indicates the number of elements that this accessor can read. An element is a tuple whose length depends on the
     * number of accessor parameters. For example, if the accessor has three float parameters, than an element is three
     * floats, and this method returns the number of float triplets.
     *
     * @return Number of elements that the accessor can read.
     */
    public int getCount()
    {
        Integer count = (Integer) this.getField("count");
        return count != null ? count : 0;
    }

    /**
     * Indicates the offset into the source data at which the accessor starts reading. Returns zero if this attribute
     * has not been set.
     *
     * @return Offset at which the accessor starts reading.
     */
    public int getOffset()
    {
        Integer offset = (Integer) this.getField("offset");
        return offset != null ? offset : 0;
    }

    /**
     * Indicates the number of tokens in the source data to advance between elements.
     *
     * @return Offset at which the accessor starts reading.
     */
    public int getStride()
    {
        Integer stride = (Integer) this.getField("stride");
        return stride != null ? stride : 1;
    }

    /**
     * Indicates the number of tokens that the accessor can read. For example, if the accessor reads floats, then this
     * method returns the number of floats that the accessor can read.
     *
     * @return Number of tokens that the accessor can read.
     */
    public int size()
    {
        int count = 0;
        for (ColladaParam param : this.params)
        {
            if (!WWUtil.isEmpty(param.getName()))
                count += 1;
        }
        return count * this.getCount();
    }

    /**
     * Copies this accessor's content to a buffer. This method begins writing data at the buffer's current position, and
     * continues until the accessor is out of data.
     *
     * @param buffer Buffer to fill. Must have remaining capacity at least equal to {@link #size()}.
     *
     * @return True if the buffer was filled successfully. False if the data source cannot be accessed.
     */
    public boolean fillBuffer(FloatBuffer buffer)
    {
        if (buffer == null)
        {
            String message = Logging.getMessage("nullValue.BufferIsNull");
            Logging.logger().severe(message);
            throw new IllegalArgumentException(message);
        }

        if (buffer.remaining() < this.size())
        {
            String message = Logging.getMessage("generic.BufferOverflow", buffer.remaining(), this.size());
            Logging.logger().severe(message);
            throw new IllegalArgumentException(message);
        }

        String source = this.getSource();
        if (source == null)
            return false;

        Object o = this.getRoot().resolveReference(source);
        if (o == null)
            return false; // Source not available

        // TODO: COLLADA spec says source can be a non-COLLADA document (pg 5-5)
        if (!(o instanceof ColladaAbstractObject))
            return false;

        Scanner scanner = new Scanner(((ColladaAbstractObject) o).getCharacters());

        // Skip values before the start offset
        for (int i = 0; i < this.getOffset(); i++)
        {
            scanner.next();
        }

        int stride = this.getStride();
        for (int i = 0; i < this.getCount() && scanner.hasNext(); i++)
        {
            for (ColladaParam param : this.params)
            {
                if (!scanner.hasNext())
                    break;

                // Parse the next value and add to the buffer. Skip unnamed parameters.
                // See COLLADA spec pg 5-5.
                if (!WWUtil.isEmpty(param.getName()))
                    buffer.put(scanner.nextFloat());
                else
                    scanner.next();
            }

            // Skip elements up to the stride. Has no effect if stride <= param count.
            int j = 0;
            while (scanner.hasNext() && j < stride - this.params.size())
            {
                scanner.next();
                j += 1;
            }
        }

        return true;
    }

    /** {@inheritDoc} */
    @Override
    public void setField(String keyName, Object value)
    {
        if (keyName.equals("param"))
            this.params.add((ColladaParam) value);
        else
            super.setField(keyName, value);
    }

    /** {@inheritDoc} */
    @Override
    protected void doAddEventAttribute(Attribute attr, XMLEventParserContext ctx, XMLEvent event, Object... args)
        throws XMLStreamException
    {
        String localName = attr.getName().getLocalPart();
        boolean isIntField = "count".equals(localName) || "offset".equals(localName) || "stride".equals(localName);

        if (isIntField)
            this.setField(localName, WWUtil.makeInteger(attr.getValue()));
        else
            super.doAddEventAttribute(attr, ctx, event, args);
    }
}
