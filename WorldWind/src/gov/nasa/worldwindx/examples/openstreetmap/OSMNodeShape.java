/*
 * Copyright (C) 2012 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwindx.examples.openstreetmap;

import gov.nasa.worldwind.*;
import gov.nasa.worldwind.avlist.AVKey;
import gov.nasa.worldwind.geom.Position;
import gov.nasa.worldwind.render.*;
import gov.nasa.worldwind.util.*;

/**
 * A shape to represent Open Street Map nodes. A node is displayed as a {@link PointPlacemark}s, whose attributes are
 * governed by the configuration given in the {@link OSMShapeFactory} passed to the layer containing the shape.
 *
 * @author tag
 * @version $Id$
 */
public class OSMNodeShape extends WWObjectImpl implements Renderable
{
    protected PointPlacemark placemark;

    /**
     * Construct a node shape.
     *
     * @param node               the cache representation of the node.
     * @param osmShapeAttributes the OSM attributes to apply to the node.
     *
     * @throws IllegalArgumentException if either the node or the attributes reference is null.
     */
    public OSMNodeShape(OSMNodeProto.Node node, OSMShapeAttributes osmShapeAttributes)
    {
        if (node == null)
        {
            String message = Logging.getMessage("OSM.NodeIsNull");
            Logging.logger().severe(message);
            throw new IllegalArgumentException(message);
        }

        if (osmShapeAttributes == null)
        {
            String message = Logging.getMessage("OSM.AttributesIsNull");
            Logging.logger().severe(message);
            throw new IllegalArgumentException(message);
        }

        this.placemark = this.initializePlacemark(Position.fromDegrees(node.getLat(), node.getLon()),
            this.initializeAttributes(osmShapeAttributes));

        // Make the tooltip string.

        StringBuilder sb = new StringBuilder();

        sb.append("id=").append(node.getId());
        this.placemark.setValue("id", node.getId());

        for (OSMNodeProto.Tag tag : node.getTagsList())
        {
            this.appendTag(tag.getKey(), tag.getValue(), sb);
            this.placemark.setValue(tag.getKey(), tag.getValue());
        }

        this.placemark.setValue(AVKey.DISPLAY_NAME, sb.toString());
    }

    /**
     * Maps the attribute bundle configured in the {@link OSMShapeFactory} to {@link PointPlacemarkAttributes}.
     *
     * @param osmShapeAttributes the Open Street Map attribute bundle.
     *
     * @return the point-placemark attributes.
     */
    protected PointPlacemarkAttributes initializeAttributes(OSMShapeAttributes osmShapeAttributes)
    {
        PointPlacemarkAttributes attributes = new PointPlacemarkAttributes();

        attributes.setUsePointAsDefaultImage(true);
        attributes.setScale(5d);
        attributes.setLineMaterial(Material.YELLOW);

        if (osmShapeAttributes.getFont() != null)
            attributes.setLabelFont(osmShapeAttributes.getFont());

        if (osmShapeAttributes.getLabelColor() != null)
            attributes.setLabelMaterial(new Material(osmShapeAttributes.getLabelColor()));

        if (!WWUtil.isEmpty(osmShapeAttributes.getIconPath()))
        {
            attributes.setImageAddress(osmShapeAttributes.getIconPath());
            attributes.setScale(1d);
        }

        return attributes;
    }

    /**
     * Creates this node's {@link PointPlacemark} and sets its attributes.
     *
     * @param position   the node's position.
     * @param attributes the node's attributes.
     *
     * @return a new point placemark for the node.
     */
    protected PointPlacemark initializePlacemark(Position position, PointPlacemarkAttributes attributes)
    {
        PointPlacemark pp = new PointPlacemark(position);

        pp.setAltitudeMode(WorldWind.CLAMP_TO_GROUND);
        pp.setEnableDecluttering(true);
        pp.setAttributes(attributes);

        return pp;
    }

    /**
     * Appends key/value pairs to the display string for this node.
     *
     * @param key   the key.
     * @param value the value.
     * @param sb    the string builder used to accumulate key/value pair descriptions.
     *
     * @return the string builder with the key/value pair appended. The returned string builder is the one passed in if
     *         it was non-null, or a new one if null was passed.
     */
    protected StringBuilder appendTag(String key, String value, StringBuilder sb)
    {
        if (sb == null)
            sb = new StringBuilder();

        this.placemark.setValue(key, value);

        sb.append(key).append(" = ").append(value).append("\n");

        if (key.equals("name"))
            this.placemark.setLabelText(value);

        return sb;
    }

    /**
     * Returns the node's geographic position. The position's altitude is always 0.
     *
     * @return the node's position.
     */
    public Position getPosition()
    {
        return this.placemark.getPosition();
    }

    /**
     * Returns the node's label, as displayed by the representing {@link PointPlacemark}.
     *
     * @return the node's label.
     */
    public String getLabel()
    {
        return this.placemark != null ? this.placemark.getLabelText() : null;
    }

    public void render(DrawContext dc)
    {
        if (this.placemark == null)
            return;

        this.placemark.render(dc);
    }
}
