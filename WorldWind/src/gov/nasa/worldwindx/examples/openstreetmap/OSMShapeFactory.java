/*
 * Copyright (C) 2012 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwindx.examples.openstreetmap;

import gov.nasa.worldwind.exception.WWRuntimeException;
import gov.nasa.worldwind.util.*;
import gov.nasa.worldwind.util.xml.*;
import org.openstreetmap.osmosis.core.domain.v0_6.*;

import javax.xml.stream.*;
import javax.xml.stream.events.XMLEvent;
import java.awt.*;
import java.io.*;
import java.util.*;
import java.util.List;

/**
 * Creates shapes for Open Street Map nodes and ways. Assigns them attributes based on one or more specified attribute
 * configuration files.
 * <p/>
 * Configuration files may contain either {@code attribute} of {@code exclude} elements. See {@code
 * config/Earth/OSMAttributes.xml} for examples. Attribute elements define appearance attributes for OSM nodes and ways.
 * Exclude elements direct nodes and ways to be excluded based on attribute/value criteria specified in the {@code
 * exclude} element.
 * <p/>
 * Attribute and exclude elements apply to OSM nodes and ways based on the a/v list pairs contained in the nodes and
 * ways. See {@code config/Earth/OSMAttributes.xml} for their documentation.
 *
 * @author tag
 * @version $Id$
 */
public class OSMShapeFactory extends AbstractXMLEventParser
{
    /** The default attributes for nodes and ways. */
    protected OSMShapeAttributes defaultAttributes = new OSMShapeAttributes();

    /** These maps associate attributes with node and way features. */
    protected Map<String, OSMShapeAttributes> nodeAttributesMap = new HashMap<String, OSMShapeAttributes>();
    protected Map<String, OSMShapeAttributes> wayAttributesMap = new HashMap<String, OSMShapeAttributes>();

    /** This set is used to prevent duplicate ways that were assigned to adjacent sectors during caching. */
    protected Set<String> wayMap = new HashSet<String>();

    /** These sets are used to exclude nodes and ways. */
    protected Set<String> wayExclusionSet = new HashSet<String>();
    protected Set<String> nodeExclusionSet = new HashSet<String>();

    /**
     * Create a shape factory instance. Configure node and way attributes according to specified configuration
     * information..
     *
     * @param attributeStream an input stream for the node and way configuration data. See {@code
     *                        config/Earth/OSMAttributes.xml} for an example configuration file. This constructor closes
     *                        the stream before returning.
     *
     * @throws XMLStreamException       if an exception occurs while reading the specified configuration stream.
     * @throws IllegalArgumentException if the specified stream is null.
     */
    public OSMShapeFactory(InputStream attributeStream) throws XMLStreamException
    {
        if (attributeStream == null)
        {
            String message = Logging.getMessage("nullValue.InputStreamIsNull");
            Logging.logger().severe(message);
            throw new IllegalArgumentException(message);
        }

        this.initializeDefaultAttributes(this.defaultAttributes);
        this.initializeAttributes(attributeStream);
    }

    /**
     * Parses a specified configuration stream. This method closes the stream before returning.
     *
     * @param attributeStream the configuration stream.
     *
     * @throws XMLStreamException if an exception occurs while reading the stream.
     */
    protected void initializeAttributes(InputStream attributeStream) throws XMLStreamException
    {
        XMLEventReader eventReader = WWXML.openEventReader(attributeStream, true);
        if (eventReader == null)
            throw new WWRuntimeException(Logging.getMessage("OSM.UnableToOpenAttributeDocument"));

        try
        {
            this.parseAttributeDoc(eventReader);
        }
        finally
        {
            eventReader.close();
            this.closeEventStream(attributeStream);
        }
    }

    /**
     * Parses a configuration attribute document represented by an XML event reader.
     *
     * @param eventReader the event reader.
     *
     * @return {@code this}. Returns null if the event reader has no content.
     *
     * @throws XMLStreamException if an error occurs while reading from the XML event reader.
     */
    public OSMShapeFactory parseAttributeDoc(XMLEventReader eventReader) throws XMLStreamException
    {
        OSMAttributesParserContext ctx = this.createParserContext(eventReader);

        for (XMLEvent event = ctx.nextEvent(); ctx.hasNext(); event = ctx.nextEvent())
        {
            if (event == null)
                continue;

            if (event.isStartElement() && event.asStartElement().getName().getLocalPart().equals("attributes"))
            {
                super.parse(ctx, event);
                return this;
            }
        }

        return null;
    }

    /**
     * Returns an OSM attributes parser context, creating one if one does not currently exist.
     *
     * @param reader the reader for which to create the parser context.
     *
     * @return the parser context, either an existing one or a new one if no such context exists.
     */
    protected OSMAttributesParserContext createParserContext(XMLEventReader reader)
    {
        OSMAttributesParserContext ctx = (OSMAttributesParserContext)
            XMLEventParserContextFactory.createParserContext(OSMAttributesParserContext.MIME_TYPE,
                OSMAttributesParserContext.NAMESPACE);

        if (ctx == null)
        {
            // Register a parser context for this root's default namespace
            String[] mimeTypes = new String[] {OSMAttributesParserContext.MIME_TYPE};
            XMLEventParserContextFactory.addParserContext(mimeTypes, new OSMAttributesParserContext());
            ctx = (OSMAttributesParserContext) XMLEventParserContextFactory.createParserContext(
                OSMAttributesParserContext.MIME_TYPE, OSMAttributesParserContext.NAMESPACE);
        }

        ctx.setEventReader(reader);

        return ctx;
    }

    /**
     * Simply closes an event stream and captures and logs the potential exception thrown from the close operation.
     *
     * @param eventStream the event stream to close.
     */
    protected void closeEventStream(InputStream eventStream)
    {
        try
        {
            eventStream.close();
        }
        catch (IOException e)
        {
            String message = Logging.getMessage("generic.ExceptionClosingXmlEventReader");
            Logging.logger().warning(message);
        }
    }

    @Override
    protected void doAddEventContent(Object o, XMLEventParserContext ctx, XMLEvent event, Object... args)
        throws XMLStreamException
    {
        if (event.asStartElement().getName().getLocalPart().equals("exclude"))
            this.addExclusion((OSMAttributesParserContext.Exclusion) o);
        else if (event.asStartElement().getName().getLocalPart().equals("attribute"))
            this.addAttribute((OSMAttributesParserContext.Attribute) o);
        else
            super.doAddEventContent(o, ctx, event, args);
    }

    /**
     * Adds an exclusion directive for nodes and/or ways with a specified a/v list pair. If the exclude element has a
     * {@code featureType} XML attribute then the exclusion is for that specific entity type, otherwise the exclusion is
     * for both nodes and ways. The exclusion applies to nodes and/or ways with the a/v list pair specified in the
     * exclude element. See {@code config/Earth/OSMAttributes.xml} for more information.
     *
     * @param exclusion the exclude element to apply.
     */
    protected void addExclusion(OSMAttributesParserContext.Exclusion exclusion)
    {
        String key = exclusion.getKey();

        if (WWUtil.isEmpty(key))
            return;

        String featureType = exclusion.getFeatureType();
        String value = exclusion.getValue();
        String flag = exclusion.getFlag();

        String s = key + (value != null ? ":" + value : "");

        if (WWUtil.isEmpty(featureType)) // apply to both nodes and ways if feature type not specified
        {
            if (flag != null && flag.startsWith("f"))
            {
                this.wayExclusionSet.remove(s);
                this.nodeExclusionSet.remove(s);
            }
            else // default to excluded
            {
                this.wayExclusionSet.add(s);
                this.nodeExclusionSet.add(s);
            }
        }
        else if (featureType.equals("node"))
        {
            if (!WWUtil.isEmpty(flag) && flag.startsWith("f"))
                this.nodeExclusionSet.remove(s);
            else // default to excluded
                this.nodeExclusionSet.add(s);
        }
        else if (featureType.equals("way"))
        {
            if (flag != null && flag.startsWith("f"))
                this.wayExclusionSet.remove(s);
            else // default to excluded
                this.wayExclusionSet.add(s);
        }
    }

    /**
     * Adds an attribute bundle for nodes and/or ways with a specified a/v list pair. If the attribute element has a
     * {@code featureType} XML attribute of either "node" or "way" then the attribute is for that specific entity type,
     * otherwise the attribute applies to both nodes and ways. The attribute applies to nodes and/or ways with the a/v
     * list pair specified in the attribute element. See {@code config/Earth/OSMAttributes.xml} for more information.
     *
     * @param attribute the attribute element to apply.
     */
    protected void addAttribute(OSMAttributesParserContext.Attribute attribute)
    {
        if (WWUtil.isEmpty(attribute.getKey()))
            return;

        String s = attribute.getKey() + (attribute.getValue() != null ? ":" + attribute.getValue() : "");

        // Attribute elements may not contain all fields, so use the fields of a current attribute of the same
        // name for unspecified fields, or the global default attributes otherwise.
        OSMShapeAttributes nodeDefaults = this.nodeAttributesMap.get(s);
        if (nodeDefaults == null)
            nodeDefaults = this.nodeAttributesMap.get(attribute.getKey());
        if (nodeDefaults == null)
            nodeDefaults = this.getDefaultNodeAttributes();

        OSMShapeAttributes wayDefaults = this.wayAttributesMap.get(s);
        if (wayDefaults == null)
            wayDefaults = this.wayAttributesMap.get(attribute.getKey());
        if (wayDefaults == null)
            wayDefaults = this.getDefaultWayAttributes();

        if (WWUtil.isEmpty(attribute.getFeatureType())) // set both node and way attrs if no feature type specified
        {
            this.nodeAttributesMap.put(s, new OSMShapeAttributes(nodeDefaults, attribute));
            this.wayAttributesMap.put(s, new OSMShapeAttributes(wayDefaults, attribute));
        }
        else if (attribute.getFeatureType().equals("node"))
        {
            this.nodeAttributesMap.put(s, new OSMShapeAttributes(nodeDefaults, attribute));
        }
        else if (attribute.getFeatureType().equals("way"))
        {
            this.wayAttributesMap.put(s, new OSMShapeAttributes(wayDefaults, attribute));
        }
    }

    /**
     * Return the default node attributes. The defaults may be those hardcoded in this class or specified via the
     * configuration file via a {@code default} key.
     *
     * @return the default node attributes.
     */
    protected OSMShapeAttributes getDefaultNodeAttributes()
    {
        OSMShapeAttributes attributes = this.nodeAttributesMap.get("default");

        return attributes != null ? attributes : this.defaultAttributes;
    }

    /**
     * Return the default way attributes. The defaults may be those hardcoded in this class or specified via the
     * configuration file via a {@code default} key.
     *
     * @return the default way attributes.
     */
    protected OSMShapeAttributes getDefaultWayAttributes()
    {
        OSMShapeAttributes attributes = this.wayAttributesMap.get("default");

        return attributes != null ? attributes : this.defaultAttributes;
    }

    /**
     * Creates a shape for a specified OSM node.
     *
     * @param node the node to create a shape for.
     *
     * @return a new shape for the specified node, or null if one of the node's a/v list pairs has been explicitly
     *         excluded in this factory's configuration.
     *
     * @throws IllegalArgumentException if the specified node is null.
     */
    public OSMNodeShape createShape(OSMNodeProto.Node node)
    {
        if (node == null)
        {
            String message = Logging.getMessage("OSM.NodeIsNull");
            Logging.logger().severe(message);
            throw new IllegalArgumentException(message);
        }

        if (this.isExcluded(this.nodeExclusionSet, node.getTagsList()))
            return null;

        OSMShapeAttributes attributes = this.determineAttributes(this.nodeAttributesMap,
            this.getDefaultNodeAttributes(), node.getTagsList());

        return new OSMNodeShape(node, attributes);
    }

    /**
     * Creates a shape for a specified OSM way.
     *
     * @param way the way to create a shape for.
     *
     * @return a new shape for the specified way, or null if one of the way's a/v list pairs has been explicitly
     *         excluded in this factory's configuration. Null is also returned if the way has fewer than two locations
     *         or it is a duplicate of a way previously created by this factory. (This latter rule eliminates creation
     *         of duplicate ways merely because the way spans sectors in the cache files.)
     *
     * @throws IllegalArgumentException if the specified way is null.
     */
    public OSMWayShape createShape(OSMNodeProto.Way way)
    {
        if (way == null)
        {
            String message = Logging.getMessage("OSM.WayIsNull");
            Logging.logger().severe(message);
            throw new IllegalArgumentException(message);
        }

        if (way.getLocationsCount() < 2)
            return null;

        if (this.isDuplicate(way))
            return null;

        if (this.isExcluded(this.wayExclusionSet, way.getTagsList()))
            return null;

        if (this.isEmptyWay(way))
            return null;

        OSMShapeAttributes attributes = this.determineAttributes(this.wayAttributesMap,
            this.getDefaultWayAttributes(), way.getTagsList());

        return new OSMWayShape(way, attributes);
    }

    /**
     * Indicates whether the a shape for the way has already been created by this factory.
     *
     * @param way the way in question.
     *
     * @return true if a shape has already been created for the specified way, otherwise false.
     */
    protected synchronized boolean isDuplicate(OSMNodeProto.Way way)
    {
        String id = way.getId();

        if (WWUtil.isEmpty(id))
            return false;

        if (this.wayMap.contains(id))
        {
            return true;
        }
        else
        {
            this.wayMap.add(id);
            return false;
        }
    }

    /**
     * Indicates whether a node or way is to be excluded based on exclusions set in this factory's configuration.
     *
     * @param exclusionSet the exclusion set to test, wither that for nodes or that for ways.
     * @param tags         the node's or way's tags.
     *
     * @return true if the node or way is excluded, otherwise false.
     */
    protected boolean isExcluded(Set<String> exclusionSet, List<OSMNodeProto.Tag> tags)
    {
        // Check for primary feature exclusion.
        for (OSMNodeProto.Tag tag : tags)
        {
            if (exclusionSet.contains(tag.getKey()))
            {
                return true;
            }
        }

        // Check for specific feature exclusion
        for (OSMNodeProto.Tag tag : tags)
        {
            String s = tag.getKey() + ":" + tag.getValue();
            if (exclusionSet.contains(s))
                return true;
        }

        return false;
    }

    protected boolean isEmptyWay(OSMNodeProto.Way way)
    {
        // Determine whether has nothing more than an "id" element.

        return way.getTagsList().size() == 0;// && way.getTags(0).getKey().equals("id");
    }

    /**
     * Initializes the global, hardcoded node and way attributes. Returns those default attributes and also sets them in
     * both the node and way attribute maps.
     *
     * @param attrs the initialized attribute bundle.
     */
    protected void initializeDefaultAttributes(OSMShapeAttributes attrs)
    {
        attrs.setLevel(OSMCacheBuilder.MAX_LEVEL);
        attrs.setInteriorColor(Color.GRAY);
        attrs.setOutlineColor(Color.WHITE);
        attrs.setLabelColor(Color.WHITE);
        attrs.setMarkerColor(Color.WHITE);
        attrs.setWidth(3d); // in meters for ways
        attrs.setFont(Font.decode("Arial-BOLD-10"));

        this.nodeAttributesMap.put("default", attrs);
        this.wayAttributesMap.put("default", attrs);
    }

    /**
     * Determines the attributes to associate with a node or way during caching. Note: even though this method returns a
     * full attribute bundle, only the "level" field is consulted during caching.
     * <p/>
     * {@link #determineAttributes(java.util.Map, OSMShapeAttributes, java.util.List)} is the method used to determine
     * attributes during display.
     *
     * @param entity the node or way for which to determine attributes.
     *
     * @return the attribute bundle for the specified node or way.
     */
    public OSMShapeAttributes determineAttributes(Entity entity)
    {
        OSMShapeAttributes attributes;

        Map<String, OSMShapeAttributes> map;
        if (entity instanceof Node)
        {
            map = this.nodeAttributesMap;
            attributes = this.getDefaultNodeAttributes();
        }
        else if (entity instanceof Way)
        {
            map = this.wayAttributesMap;
            attributes = this.getDefaultWayAttributes();
        }
        else
            return null;

        // Apply default attributes for the primary feature, e.g., "sport".
        for (Tag tag : entity.getTags())
        {
            String s = tag.getKey();
            OSMShapeAttributes attrs = map.get(s);
            if (attrs != null)
            {
                attributes = attrs;
                break;
            }
        }

        // Apply attributes for the specific feature, e.g., "sport:soccer".
        for (Tag tag : entity.getTags())
        {
            String s = tag.getKey() + ":" + tag.getValue();
            OSMShapeAttributes attrs = map.get(s);
            if (attrs != null)
            {
                attributes = attrs;
                break;
            }
        }

        return attributes;
    }

    /**
     * Determine the attribute used to display a specified node or way.
     *
     * @param map               either the node map or the way map.
     * @param defaultAttributes the default attributes to return if the specified map does not contain an entry for the
     *                          specified set of tags.
     * @param tags              the a/v list to use to determine the attributes. The first match of this list with the
     *                          specified map is returned.
     *
     * @return the attribute bundle for the node or way.
     */
    protected OSMShapeAttributes determineAttributes(Map<String, OSMShapeAttributes> map,
        OSMShapeAttributes defaultAttributes, List<OSMNodeProto.Tag> tags)
    {
        OSMShapeAttributes attributes = defaultAttributes;

        // Apply default attributes for the primary feature, e.g., "sport".
        for (OSMNodeProto.Tag tag : tags)
        {
            String s = tag.getKey();
            OSMShapeAttributes attrs = map.get(s);
            if (attrs != null)
            {
                attributes = attrs;
                break;
            }
        }

        // Apply attributes for the specific feature, e.g., "sport:soccer".
        for (OSMNodeProto.Tag tag : tags)
        {
            String s = tag.getKey() + ":" + tag.getValue();
            OSMShapeAttributes attrs = map.get(s);
            if (attrs != null)
            {
                attributes = attrs;
                break;
            }
        }

        return attributes;
    }
}
