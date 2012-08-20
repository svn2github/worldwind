/*
 * Copyright (C) 2012 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwindx.examples.openstreetmap;

import gov.nasa.worldwind.*;
import gov.nasa.worldwind.avlist.AVKey;
import gov.nasa.worldwind.geom.*;
import gov.nasa.worldwind.globes.*;
import gov.nasa.worldwind.render.*;
import gov.nasa.worldwind.util.*;

import java.util.*;

/**
 * A shape to represent Open Street Map ways. A way is displayed as a {@link SurfacePolygon} with one or more {@link
 * PointPlacemark} labels. The attributes associated with the surface polygon and point placemarks are governed by the
 * configuration given in the {@link OSMShapeFactory} passed to the layer containing the shape.
 * <p/>
 * Multiple point placemarks are used to label the way multiply at floating-point interval specified in the World Wind
 * configuration as "gov.nasa.worldwind.avkey.OSMLabelDistance", in meters.
 *
 * @author tag
 * @version $Id$
 */
public class OSMWayShape extends WWObjectImpl implements Renderable, PreRenderable, Highlightable
{
    /**
     * The distance between successive labels for a way. The default distance is specified by the
     * "gov.nasa.worldwind.avkey.OSMLabelInterval" property in the World Wind configuration file. If not specified
     * there, it defaults to 400 meters.
     */
    protected static final double LABEL_DISTANCE = Configuration.getDoubleValue(AVKey.OSM_LABEL_INTERVAL, 400d);

    /**
     * The width of a highway lane, in meters. The default distance is specified by the
     * "gov.nasa.worldwind.avkey.OSMLaneWidth" property in the World Wind configuration file. If not specified there, it
     * defaults to 3 meters.
     */
    protected static final double LANE_WIDTH = Configuration.getDoubleValue(AVKey.OSM_LANE_WIDTH, 3d);

    /** Used during the computation of surface polygons that represent ways. */
    protected static final Globe globe = new Earth();

    /** SurfacePolygons are used to represent ways. */
    protected SurfacePolygon surfacePolygon;
    /**
     * PointPlacemarks are used to label ways. There may be more than one label associated with a way because the way
     * may be long and warrant name placement at intervals.
     */
    protected List<PointPlacemark> namePlacemarks;
    protected boolean closed;

    /**
     * Contstructs a way shape.
     *
     * @param way        the cache represenation of the way.
     * @param attributes the OSM attributes to apply to the way.
     *
     * @throws IllegalArgumentException if the way or the attributes reference is null.
     */
    public OSMWayShape(OSMNodeProto.Way way, OSMShapeAttributes attributes)
    {
        if (way == null)
        {
            String message = Logging.getMessage("OSM.WayIsNull");
            Logging.logger().severe(message);
            throw new IllegalArgumentException(message);
        }

        if (attributes == null)
        {
            String message = Logging.getMessage("nullValue.AttributesIsNull");
            Logging.logger().severe(message);
            throw new IllegalArgumentException(message);
        }

        if (way.getLocationsCount() < 2)
        {
            String message = Logging.getMessage("OSM.WayTooShort");
            Logging.logger().severe(message);
            throw new IllegalArgumentException(message);
        }

        // Create WW version of the way locations.
        List<Position> positions = new ArrayList<Position>(way.getLocationsCount());
        for (int i = 0; i < way.getLocationsCount(); i++)
        {
            OSMNodeProto.Location protoLocation = way.getLocations(i);
            positions.add(Position.fromDegrees(protoLocation.getLat(), protoLocation.getLon()));
        }

        // A way is closed if it's first point is the same as its last and it is not a highway.
        this.closed = positions.get(0).equals(positions.get(positions.size() - 1));
        this.closed = this.closed && !OSMUtil.containsTagKey(way.getTagsList(), "highway");
        if (this.closed)
        {
            // Create a general polygon to represent the way.
            this.surfacePolygon = new SurfacePolygon(positions);
            this.surfacePolygon.setDelegateOwner(this);
        }
        else
        {
            // Make a long, wide, thin surface polygon to represent the way.
            List<Position> leftPositions = new ArrayList<Position>(positions.size());
            List<Position> rightPositions = new ArrayList<Position>(positions.size());

            double width = this.computeWidth(way, attributes);
            WWMath.generateParallelLines(positions, leftPositions, rightPositions, width, globe);

            List<Position> polygonPositions = new ArrayList<Position>(leftPositions.size() + rightPositions.size());
            polygonPositions.addAll(leftPositions);
            Collections.reverse(rightPositions);
            polygonPositions.addAll(rightPositions);

            this.surfacePolygon = new SurfacePolygon(polygonPositions);
            this.surfacePolygon.setDelegateOwner(this);

            // Ways are usually named with their "name" attribute, but many use the "ref" attribute instead.
            String name = OSMUtil.getValue(way.getTagsList(), "name");
            if (name == null)
                name = OSMUtil.getValue(way.getTagsList(), "ref");

            // Create one or more labels for the way if it has a name.
            if (name != null)
            {
                List<Position> labelPositions = this.getLabelPositions(positions, LABEL_DISTANCE);

                for (Position position : labelPositions)
                {
                    PointPlacemark pp = new PointPlacemark(position);
                    pp.setLabelText(name);
                    pp.setAltitudeMode(WorldWind.CLAMP_TO_GROUND);
                    pp.setEnableDecluttering(true);

                    if (this.namePlacemarks == null)
                        this.namePlacemarks = new ArrayList<PointPlacemark>(1);

                    this.namePlacemarks.add(pp);
                }
            }
        }

        this.setAttributes(attributes);

        // Copy the OSM a/v pairs to this shape as the display name string, used in the example to show the a/v pairs
        // on rollover.
        StringBuilder sb = new StringBuilder();

        sb.append("id=").append(way.getId()).append("\n");
        this.setValue("id", way.getId());

        for (OSMNodeProto.Tag tag : way.getTagsList())
        {
            sb.append(tag.getKey());
            sb.append(" = ");
            sb.append(tag.getValue());
            sb.append("\n");
        }

        if (sb.length() > 0)
            this.setValue(AVKey.DISPLAY_NAME, sb.toString());
    }

    /**
     * Maps the OSM attributes to surface polygon and point placemark attributes and sets them on those objects for this
     * shape. Also sets the surface polygon's highlight attributes to the same an the non-highlighted but with an
     * opacity of 0.9.
     *
     * @param osmAttributes the OSM attributes.
     */
    protected void setAttributes(OSMShapeAttributes osmAttributes)
    {
        if (this.surfacePolygon != null)
        {
            this.surfacePolygon.setAttributes(this.getSurfacePolygonAttributes(osmAttributes));

            ShapeAttributes highlightAttributes = new BasicShapeAttributes(this.surfacePolygon.getAttributes());
            highlightAttributes.setInteriorOpacity(0.9);
            this.surfacePolygon.setHighlightAttributes(highlightAttributes);
        }

        if (this.namePlacemarks != null)
        {
            PointPlacemarkAttributes nameAttributes = this.getNamePlacemarkAttributes(osmAttributes);

            for (PointPlacemark pp : this.namePlacemarks)
            {
                pp.setAttributes(nameAttributes);
            }
        }
    }

    /**
     * In order to avoid the memory overhead of a separate instance of shape attributes for each way's surface polygon,
     * we keep a map of those already created for a given set of OSM attributes and re-use those. The map is static and
     * access is synchronized.
     */
    static protected Map<OSMShapeAttributes, ShapeAttributes> surfacePolygonAttributeMap
        = new HashMap<OSMShapeAttributes, ShapeAttributes>();

    /**
     * Returns the surface polygon attributes to use for a specified bundle of OSM attributes. The returned instance may
     * be a shared instance of an attribute bundle that corresponds to the same bundle of specified OSM attributes.
     * <p/>
     * Note: this method is synchronized and utilizes the static map of shared surface polygon attributes.
     *
     * @param osmAttributes the OSM attributes for which to create surface polygon attributes.
     *
     * @return the surface polygon attributes corresponding to the specified OSM attributes.
     */
    protected synchronized ShapeAttributes getSurfacePolygonAttributes(OSMShapeAttributes osmAttributes)
    {
        ShapeAttributes shapeAttributes = surfacePolygonAttributeMap.get(osmAttributes);

        if (shapeAttributes != null)
            return shapeAttributes;

        shapeAttributes = new BasicShapeAttributes();

        shapeAttributes.setInteriorMaterial(new Material(osmAttributes.getInteriorColor()));
        shapeAttributes.setOutlineMaterial(new Material(osmAttributes.getOutlineColor()));
        shapeAttributes.setOutlineWidth(1);//attributes.getWidth());
        shapeAttributes.setDrawOutline(true);
        shapeAttributes.setOutlineOpacity(0.6);
        shapeAttributes.setInteriorOpacity(0.6);

        surfacePolygonAttributeMap.put(osmAttributes, shapeAttributes);

        return shapeAttributes;
    }

    /**
     * In order to avoid the memory overhead of a separate instance of shape attributes for each way's point placemarks,
     * we keep a map of those already created for a given set of OSM attributes and re-use those. The map is static and
     * access is synchronized.
     */
    static protected Map<OSMShapeAttributes, PointPlacemarkAttributes> namePlacemarkAttributeMap
        = new HashMap<OSMShapeAttributes, PointPlacemarkAttributes>();

    /**
     * Returns the point placemark attributes to use for a specified bundle of OSM attributes. The returned instance may
     * be a shared instance of an attribute bundle that corresponds to the same bundle of specified OSM attributes.
     * <p/>
     * Note: this method is synchronized and utilizes the static map of shared surface polygon attributes.
     *
     * @param osmAttributes the OSM attributes for which to create point placemark attributes.
     *
     * @return the point placemark attributes corresponding to the specified OSM attributes.
     */
    protected synchronized PointPlacemarkAttributes getNamePlacemarkAttributes(OSMShapeAttributes osmAttributes)
    {
        PointPlacemarkAttributes nameAttributes = namePlacemarkAttributeMap.get(osmAttributes);
        if (nameAttributes != null)
            return nameAttributes;

        nameAttributes = new PointPlacemarkAttributes();

        nameAttributes.setUsePointAsDefaultImage(true);
        nameAttributes.setLabelFont(osmAttributes.getFont());
        nameAttributes.setLabelMaterial(new Material(osmAttributes.getLabelColor()));
        nameAttributes.setLineMaterial(new Material(osmAttributes.getMarkerColor()));

        return nameAttributes;
    }

    /**
     * Determines the width of a way, based on either the "width" attribute specified in the OSM attribute configuration
     * or, if specified with the OSM way, the value of the "lanes" a/v pair. The latter takes precedence.
     *
     * @param way        the way for which to determine the width.
     * @param attributes the OSM attributes containing the "width" field.
     *
     * @return the way width, in meters.
     */
    protected double computeWidth(OSMNodeProto.Way way, OSMShapeAttributes attributes)
    {
        String width = OSMUtil.getValue(way.getTagsList(), "width");
        if (width != null)
        {
            Double w = WWUtil.convertStringToDouble(width);
            if (w != null)
                return w;
            else
                return attributes.getWidth();
        }

        String lanes = OSMUtil.getValue(way.getTagsList(), "lanes");
        if (lanes != null)
        {
            Integer n = WWUtil.convertStringToInteger(lanes);
            if (n != null)
                return n * LANE_WIDTH;
            else
                return attributes.getWidth();
        }

        return attributes.getWidth();
    }

    /**
     * Determines the positions along the way at which to place name labels.
     *
     * @param positions   the way's positions.
     * @param deltaMeters the desired distance in meters between labels. Note that the actual distance is modified as
     *                    needed in order to balance the labels along the line.
     *
     * @return a list of positions at which to place name labels. Note that the altitude value of all returned positions
     *         is 0.
     */
    protected List<Position> getLabelPositions(List<Position> positions, double deltaMeters)
    {
        if (positions.size() == 2)
            return this.getTwoPointWayLabelPositions(positions, deltaMeters);
        else
            return this.getNPointLabelPositions(positions, deltaMeters);
    }

    /**
     * Computes the locations along the way at which to put way name labels when the way contains only two positions.
     * This is an optimization of the general case.
     *
     * @param positions   the way positions.
     * @param deltaMeters the desired distance in meters between labels. Note that the actual distance is modified as
     *                    needed in order to balance the labels along the line.
     *
     * @return a list of positions at which to place name labels. Note that the altitude value of all returned positions
     *         is 0.
     */
    protected List<Position> getTwoPointWayLabelPositions(List<Position> positions, double deltaMeters)
    {
        // Compute the number of labels to place along the way.
        Angle distanceRadians = LatLon.rhumbDistance(positions.get(0), positions.get(1));
        double distanceMeters = distanceRadians.radians * Earth.WGS84_EQUATORIAL_RADIUS;
        int nLabels = (int) Math.max(distanceMeters / deltaMeters, 1);

        // Create the return list.
        List<Position> positionList = new ArrayList<Position>(nLabels);

        // Special case the occurrence of a two-position line with only one label.
        if (nLabels == 1)
        {
            double lat = 0.5 * (positions.get(0).getLatitude().degrees + positions.get(1).getLatitude().degrees);
            double lon = 0.5 * (positions.get(0).getLongitude().degrees + positions.get(1).getLongitude().degrees);

            positionList.add(Position.fromDegrees(lat, lon));

            return positionList;
        }

        // From the requested delta, compute the actual delta after balancing the positions along the way.
        Angle deltaRadiansActual = Angle.fromRadians((distanceMeters / nLabels) / Earth.WGS84_EQUATORIAL_RADIUS);

        // March along the way and place a label at the computed deltas. Note that the labels are placed at the
        // mid-points of the delta intervals.
        Angle azimuth = LatLon.rhumbAzimuth(positions.get(0), positions.get(1));
        for (int i = 0; i < nLabels; i++)
        {
            LatLon location = LatLon.rhumbEndPosition(positions.get(0), azimuth, deltaRadiansActual.multiply(i + 0.5));
            positionList.add(new Position(location, 0));
        }

        return positionList;
    }

    /**
     * Computes the locations along the way at which to put way name labels.
     *
     * @param positions   the way positions.
     * @param deltaMeters the distance in meters between labels.
     *
     * @return a list of positions at which to place name labels. Note that the altitude value of all returned positions
     *         is 0.
     */
    protected List<Position> getNPointLabelPositions(List<Position> positions, double deltaMeters)
    {
        // Compute the overall way length
        double wayLengthRadians = 0;
        for (int i = 1; i < positions.size(); i++)
        {
            wayLengthRadians += LatLon.rhumbDistance(positions.get(i - 1), positions.get(i)).radians;
        }

        // From the requested delta, compute the actual delta after balancing the positions along the way.
        double deltaRadians = deltaMeters / Earth.WGS84_EQUATORIAL_RADIUS;
        int nLabels = (int) Math.max(wayLengthRadians / deltaRadians, 1);
        double deltaRadiansActual = Angle.fromRadians(wayLengthRadians / nLabels).radians;

        // Create the return list.
        List<Position> positionList = new ArrayList<Position>(nLabels);

        // Walk through the way and compute the label positions. This code computes successive target distances -- the
        // distance along the way from its origin at which to place labels -- and marches through each way segment to
        // determine the corresponding label position. There are several cases to accommodate: 1) the target distance
        // is not within the current segment, 2) the target distance is at the end of the current segment, and 3) the
        // target distance is within the current segment. Other cases to catch are multiple target distances (labels)
        // within an individual segment and multiple segments without labels.
        int i = 1;
        Double segmentLengthRemaining = null;
        double currentDistance = 0; // current distance in radians along the way

        // Compute the distance in radians at which to place the first label. Note that the label positions are
        // computed at the mid-point of each delta segment.
        double targetDistance = deltaRadiansActual / 2;

        while (targetDistance < wayLengthRadians)
        {
            Position pa = positions.get(i - 1);
            Position pb = positions.get(i);

            double segmentLength = LatLon.rhumbDistance(pa, pb).radians;

            if (segmentLengthRemaining == null)
                segmentLengthRemaining = segmentLength;

            if (currentDistance + segmentLengthRemaining < targetDistance)
            {
                // Current target is not within the current segment, so skip to the next segment.
                currentDistance += segmentLengthRemaining;
                segmentLengthRemaining = null; // null is the sentinel to force this variable to be reinitialized
                ++i;
            }
            else if (currentDistance + segmentLengthRemaining == targetDistance)
            {
                // Current target is at the end of the current segment, so just add that position as a label position.
                // Set the current distance to the target distance, increment the target distance, then skip to the
                // next segment.
                positionList.add(pb);
                currentDistance = targetDistance;
                targetDistance += deltaRadiansActual;
                segmentLengthRemaining = null;
                ++i;
            }
            else // currentDistance + segmentLengthRemaining > targetDistance
            {
                // Current target is within the current segment, so compute its position within the segment. The
                // variable "s" indicates the distance along the segment at which to place the label.
                double s = (segmentLength - segmentLengthRemaining) + (targetDistance - currentDistance);
                Angle azimuth = LatLon.rhumbAzimuth(pa, pb);
                LatLon location = LatLon.rhumbEndPosition(pa, azimuth, Angle.fromRadians(s));
                positionList.add(new Position(location, 0));

                // Bring the current distance up to the target distance then increment the target distance. Update
                // the remaining segment length to reflect the portion of the segment beyond the new label position.
                // Do not move to the next segment because the current one may warrant more than one label.
                currentDistance = targetDistance;
                targetDistance += deltaRadiansActual;
                segmentLengthRemaining = segmentLength - s;
            }
        }

        return positionList;
    }

    /**
     * Returns the locations assocaiated with this way.
     *
     * @return this way's location.
     */
    public Iterable<? extends LatLon> getLocations()
    {
        return this.surfacePolygon.getLocations();
    }

    /**
     * Indicates whether this way is closed -- its first and last locations are identical.
     *
     * @return true if this way is closed, otherwise false.
     */
    public boolean isClosed()
    {
        return this.closed;
    }

    public boolean isHighlighted()
    {
        if (this.surfacePolygon != null)
            return this.surfacePolygon.isHighlighted();
        else
            return false;
    }

    public void setHighlighted(boolean highlighted)
    {
        if (this.surfacePolygon != null)
            this.surfacePolygon.setHighlighted(highlighted);
    }

    public void preRender(DrawContext dc)
    {
        if (this.surfacePolygon != null)
            this.surfacePolygon.preRender(dc);
    }

    public void render(DrawContext dc)
    {
        if (this.surfacePolygon != null)
            this.surfacePolygon.render(dc);

        if (this.namePlacemarks != null)
        {
            for (PointPlacemark pp : this.namePlacemarks)
            {
                pp.render(dc);
            }
        }
    }
}
