/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.formats.shapefile;

import gov.nasa.worldwind.WorldWind;
import gov.nasa.worldwind.avlist.*;
import gov.nasa.worldwind.geom.*;
import gov.nasa.worldwind.layers.*;
import gov.nasa.worldwind.render.*;
import gov.nasa.worldwind.util.*;
import org.w3c.dom.Element;

import javax.xml.xpath.*;
import java.awt.*;
import java.util.Map;

/**
 * Converts Shapefile geometry into World Wind renderable objects. Shapefile geometries are mapped to World Wind objects
 * as follows: <table> <tr><th>Shapefile Geometry</th><th>World Wind Object</th></tr> <tr><td>Point</td><td>{@link
 * gov.nasa.worldwind.render.PointPlacemark}</td></tr> <tr><td>MultiPoint</td><td>List of {@link
 * gov.nasa.worldwind.render.PointPlacemark}</td></tr> <tr><td>Polyline</td><td>{@link
 * gov.nasa.worldwind.render.SurfacePolylines}</td></tr> <tr><td>Polygon</td><td>{@link
 * gov.nasa.worldwind.render.SurfacePolygons}</td></tr> </table> In addition, if the attributes file associated with the
 * shapefile has an attribute named "height" or "hgt", the shapes in the shapefile are mapped to {@link
 * gov.nasa.worldwind.formats.shapefile.ShapefileExtrudedPolygons}.
 * <p/>
 * The attributes applied to the created shapes may be specified to this class, either via the attribute accessors of
 * this class or a configuration file passed to {@link #createLayerFromConfigDocument(org.w3c.dom.Element,
 * gov.nasa.worldwind.avlist.AVList)}.
 * <p/>
 * Shapefiles may have associated with them an attributes file. This class provides a mechanism for mapping attribute
 * names in that file to keys assigned to the created shapes. The mapping is specified as a key/value pair, the key is
 * the attribute name in the shapefile's attributes file, the value is the key name to attach to the created shape to
 * hold the value of the specified attribute. Thus, for example, the value of per-record "NAME" fields in the shapefile
 * attributes may be mapped to a {@link gov.nasa.worldwind.avlist.AVKey#DISPLAY_NAME} key in the av-list of the created
 * shapes corresponding to each record.
 *
 * @author tag
 * @version $Id$
 */
public class ShapefileLayerFactory
{
    protected AVList dBaseMappings;
    protected ShapeAttributes normalShapeAttributes;
    protected ShapeAttributes highlightShapeAttributes;
    protected PointPlacemarkAttributes normalPointAttributes;
    protected PointPlacemarkAttributes highlightPointAttributes;

    /**
     * Indicates the mappings between shapefile attribute names and av-list keys attached to created shapes.
     *
     * @return The mappings.
     */
    public AVList getDBaseMappings()
    {
        return dBaseMappings;
    }

    /**
     * Specifies the mapping of shapefile attribute names to keys attached to created shapes. For each shapefile record,
     * this class assigns the value of the named attribute for that record to the specified key on the shape created for
     * that record. The key is associated only when the shapefile record's attributes contains the specified attribute
     * name.
     *
     * @param dBaseMappings The mappings. May be null, in which case no mapping occurs.
     */
    public void setDBaseMappings(AVList dBaseMappings)
    {
        this.dBaseMappings = dBaseMappings;
    }

    /**
     * Indicates the normal shape attributes assigned to non-point shapes created by this class.
     *
     * @return The normal attributes assigned to non-point shapes.
     */
    public ShapeAttributes getNormalShapeAttributes()
    {
        return normalShapeAttributes;
    }

    /**
     * Specifies the normal attributes assigned to non-point shapes created by this class.
     *
     * @param normalShapeAttributes The normal attributes assigned to non-point shapes.
     */
    public void setNormalShapeAttributes(ShapeAttributes normalShapeAttributes)
    {
        this.normalShapeAttributes = normalShapeAttributes;
    }

    /**
     * Indicates the highlight shape attributes assigned to non-point shapes created by this class.
     *
     * @return The highlight attributes assigned to non-point shapes.
     */
    public ShapeAttributes getHighlightShapeAttributes()
    {
        return highlightShapeAttributes;
    }

    /**
     * Specifies the highlight attributes assigned to non-point shapes created by this class.
     *
     * @param highlightShapeAttributes The highlight attributes assigned to non-point shapes.
     */
    public void setHighlightShapeAttributes(ShapeAttributes highlightShapeAttributes)
    {
        this.highlightShapeAttributes = highlightShapeAttributes;
    }

    /**
     * Indicates the normal attributes assigned to point shapes created by this class.
     *
     * @return The normal attributes assigned to point shapes.
     */
    public PointPlacemarkAttributes getNormalPointAttributes()
    {
        return normalPointAttributes;
    }

    /**
     * Specifies the normal attributes assigned to point shapes created by this class.
     *
     * @param normalPointAttributes The normal attributes assigned to point shapes.
     */
    public void setNormalPointAttributes(PointPlacemarkAttributes normalPointAttributes)
    {
        this.normalPointAttributes = normalPointAttributes;
    }

    /**
     * Indicates the highlight attributes assigned to point shapes created by this class.
     *
     * @return The highlight attributes assigned to point shapes.
     */
    public PointPlacemarkAttributes getHighlightPointAttributes()
    {
        return highlightPointAttributes;
    }

    /**
     * Specifies the highlight attributes assigned to point shapes created by this class.
     *
     * @param highlightPointAttributes The highlight attributes assigned to point shapes.
     */
    public void setHighlightPointAttributes(PointPlacemarkAttributes highlightPointAttributes)
    {
        this.highlightPointAttributes = highlightPointAttributes;
    }

    /**
     * Creates a {@link gov.nasa.worldwind.layers.Layer} from a general Shapefile layer configuration element. The
     * element may contain elements specifying shapefile attribute mappings, shape attributes to assign to created
     * shapes, and layer properties.
     *
     * @param domElement The configuration element.
     * @param params     Key/value pairs to associate with the created layer. Values specified here override
     *                   corresponding values specified within the configuration element.
     *
     * @return A Layer that renders the Shapefile's contents.
     *
     * @throws IllegalArgumentException if the element is null, or if the Shapefile's primitive type or projection is
     *                                  unrecognized.
     */
    public Layer createLayerFromConfigDocument(Element domElement, AVList params)
    {
        if (domElement == null)
        {
            String message = Logging.getMessage("nullValue.ElementIsNull");
            Logging.logger().severe(message);
            throw new IllegalArgumentException(message);
        }

        String shapefileLocation = WWXML.getText(domElement, "ShapefileLocation");
        if (WWUtil.isEmpty(shapefileLocation))
        {
            String message = Logging.getMessage("SHP.ShapefileLocationUnspecified");
            Logging.logger().severe(message);
            return null;
        }

        Shapefile shp = null;
        Layer layer = null;
        try
        {
            shp = new Shapefile(shapefileLocation);

            if (params == null)
                params = new AVListImpl();

            // Common layer properties.
            AbstractLayer.getLayerConfigParams(domElement, params);

            XPathFactory xpFactory = XPathFactory.newInstance();
            XPath xpath = xpFactory.newXPath();

            this.setDBaseMappings(this.collectDBaseMappings(domElement, xpath));

            Element element = WWXML.getElement(domElement, "NormalShapeAttributes", xpath);
            this.setNormalShapeAttributes(element != null ? this.collectShapeAttributes(element) : null);

            element = WWXML.getElement(domElement, "HighlightShapeAttributes", xpath);
            this.setHighlightShapeAttributes(element != null ? this.collectShapeAttributes(element) : null);

            element = WWXML.getElement(domElement, "NormalPointAttributes", xpath);
            this.setNormalPointAttributes(element != null ? this.collectPointAttributes(element) : null);

            element = WWXML.getElement(domElement, "HighlightPointAttributes", xpath);
            this.setHighlightPointAttributes(element != null ? this.collectPointAttributes(element) : null);

            layer = this.createLayerFromShapefile(shp);
            layer.setValues(params);

            Double d = (Double) params.getValue(AVKey.OPACITY);
            if (d != null)
                layer.setOpacity(d);

            d = (Double) params.getValue(AVKey.MAX_ACTIVE_ALTITUDE);
            if (d != null)
                layer.setMaxActiveAltitude(d);

            d = (Double) params.getValue(AVKey.MIN_ACTIVE_ALTITUDE);
            if (d != null)
                layer.setMinActiveAltitude(d);

            Boolean b = (Boolean) params.getValue(AVKey.PICK_ENABLED);
            if (b != null)
                layer.setPickEnabled(b);
        }
        finally
        {
            WWIO.closeStream(shp, shapefileLocation);
        }

        return layer;
    }

    /**
     * Creates a {@link gov.nasa.worldwind.layers.Layer} from a general Shapefile.
     *
     * @param shp the Shapefile to create a layer for.
     *
     * @return A Layer that renders the Shapefile's contents.
     *
     * @throws IllegalArgumentException if the Shapefile is null, or if the Shapefile's primitive type is unrecognized.
     */
    public Layer createLayerFromShapefile(Shapefile shp)
    {
        if (shp == null)
        {
            String message = Logging.getMessage("nullValue.ShapefileIsNull");
            Logging.logger().severe(message);
            throw new IllegalArgumentException(message);
        }

        Layer layer = null;

        if (Shapefile.isPointType(shp.getShapeType()))
        {
            layer = new RenderableLayer();
            this.addRenderablesForPoints(shp, (RenderableLayer) layer);
        }
        else if (Shapefile.isMultiPointType(shp.getShapeType()))
        {
            layer = new RenderableLayer();
            this.addRenderablesForMultiPoints(shp, (RenderableLayer) layer);
        }
        else if (Shapefile.isPolylineType(shp.getShapeType()))
        {
            layer = new RenderableLayer();
            this.addRenderablesForPolylines(shp, (RenderableLayer) layer);
        }
        else if (Shapefile.isPolygonType(shp.getShapeType()))
        {
            layer = new RenderableLayer();
            this.addRenderablesForPolygons(shp, (RenderableLayer) layer);
        }
        else
        {
            Logging.logger().warning(Logging.getMessage("generic.UnrecognizedShapeType", shp.getShapeType()));
        }

        if (layer != null && shp.getBoundingRectangle() != null)
        {
            layer.setValue(AVKey.SECTOR, Sector.fromDegrees(shp.getBoundingRectangle()));
        }

        return layer;
    }

    /**
     * Creates a {@link gov.nasa.worldwind.layers.Layer} from a general Shapefile source. The source type may be one of
     * the following: <ul> <li>{@link java.io.InputStream}</li> <li>{@link java.net.URL}</li> <li>{@link
     * java.io.File}</li> <li>{@link String} containing a valid URL description or a file or resource name available on
     * the classpath.</li> </ul>
     *
     * @param source the source of the Shapefile.
     *
     * @return A Layer that renders the Shapefile's contents.
     *
     * @throws IllegalArgumentException if the source is null or an empty string, or if the Shapefile's primitive type
     *                                  is unrecognized.
     */
    public Layer createLayerFromSource(Object source)
    {
        if (WWUtil.isEmpty(source))
        {
            String message = Logging.getMessage("nullValue.SourceIsNull");
            Logging.logger().severe(message);
            throw new IllegalArgumentException(message);
        }

        Shapefile shp = null;
        Layer layer = null;
        try
        {
            shp = new Shapefile(source);
            layer = this.createLayerFromShapefile(shp);
        }
        finally
        {
            WWIO.closeStream(shp, source.toString());
        }

        return layer;
    }

    protected AVList collectDBaseMappings(Element domElement, XPath xpath)
    {
        try
        {
            Element[] elements = WWXML.getElements(domElement, "AttributeMapping", xpath);
            if (elements == null || elements.length == 0)
                return null;

            AVList attrMappings = new AVListImpl();

            for (Element el : elements)
            {
                String prop = xpath.evaluate("@attributeName", el);
                String value = xpath.evaluate("@mapToKey", el);
                if (WWUtil.isEmpty(prop) || WWUtil.isEmpty(value))
                    continue;

                attrMappings.setValue(prop, value);
            }

            return attrMappings;
        }
        catch (XPathExpressionException e) // should not occur, but log just if it does
        {
            String message = Logging.getMessage("XML.InvalidXPathExpression", "internal expression");
            Logging.logger().log(java.util.logging.Level.WARNING, message, e);
            return null;
        }
    }

    protected PointPlacemarkAttributes collectPointAttributes(Element attrElement)
    {
        XPathFactory xpFactory = XPathFactory.newInstance();
        XPath xpath = xpFactory.newXPath();

        PointPlacemarkAttributes attributes = new PointPlacemarkAttributes();

        String imageAddress = WWXML.getText(attrElement, "ImageAddress", xpath);
        if (!WWUtil.isEmpty(imageAddress))
            attributes.setImageAddress(imageAddress);

        Double scale = WWXML.getDouble(attrElement, "Scale", xpath);
        if (scale != null)
            attributes.setScale(scale);

        Color imageColor = WWXML.getColor(attrElement, "ImageColor", xpath);
        if (imageColor != null)
            attributes.setImageColor(imageColor);

        Double width = WWXML.getDouble(attrElement, "LineWidth", xpath);
        if (width != null)
            attributes.setLineWidth(width);

        Double labelScale = WWXML.getDouble(attrElement, "LabelScale", xpath);
        if (labelScale != null)
            attributes.setLabelScale(labelScale);

        Color labelColor = WWXML.getColor(attrElement, "LabelColor", xpath);
        if (labelColor != null)
            attributes.setLabelMaterial(new Material(labelColor));

        Color lineColor = WWXML.getColor(attrElement, "LineColor", xpath);
        if (lineColor != null)
            attributes.setLabelMaterial(new Material(lineColor));

        Boolean tf = WWXML.getBoolean(attrElement, "UsePointAsDefaultImage", xpath);
        if (tf != null)
            attributes.setUsePointAsDefaultImage(tf);

        return attributes;
    }

    protected ShapeAttributes collectShapeAttributes(Element attrElement)
    {
        XPathFactory xpFactory = XPathFactory.newInstance();
        XPath xpath = xpFactory.newXPath();

        ShapeAttributes shapeAttributes = new BasicShapeAttributes();

        Boolean tf = WWXML.getBoolean(attrElement, "DrawInterior", xpath);
        if (tf != null)
            shapeAttributes.setDrawInterior(tf);

        tf = WWXML.getBoolean(attrElement, "DrawOutline", xpath);
        if (tf != null)
            shapeAttributes.setDrawOutline(tf);

        Double opacity = WWXML.getDouble(attrElement, "InteriorOpacity", xpath);
        if (opacity != null)
            shapeAttributes.setInteriorOpacity(opacity);

        opacity = WWXML.getDouble(attrElement, "OutlineOpacity", xpath);
        if (opacity != null)
            shapeAttributes.setOutlineOpacity(opacity);

        Double width = WWXML.getDouble(attrElement, "OutlineWidth", xpath);
        if (opacity != null)
            shapeAttributes.setOutlineWidth(width);

        Color color = WWXML.getColor(attrElement, "InteriorColor", xpath);
        if (color != null)
            shapeAttributes.setInteriorMaterial(new Material(color));

        color = WWXML.getColor(attrElement, "OutlineColor", xpath);
        if (color != null)
            shapeAttributes.setOutlineMaterial(new Material(color));

        return shapeAttributes;
    }

    protected void addRenderablesForPoints(Shapefile shp, RenderableLayer layer)
    {
        while (shp.hasNext())
        {
            ShapefileRecord record = shp.nextRecord();

            if (!Shapefile.isPointType(record.getShapeType()))
                continue;

            AVList mappings = this.applyMappings(record.getAttributes(), this.dBaseMappings);

            double[] point = ((ShapefileRecordPoint) record).getPoint();
            layer.addRenderable(this.createPoint(record, point[1], point[0], mappings));
        }
    }

    protected void addRenderablesForMultiPoints(Shapefile shp, RenderableLayer layer)
    {
        while (shp.hasNext())
        {
            ShapefileRecord record = shp.nextRecord();

            if (!Shapefile.isMultiPointType(record.getShapeType()))
                continue;

            AVList mappings = this.applyMappings(record.getAttributes(), this.dBaseMappings);

            Iterable<double[]> iterable = ((ShapefileRecordMultiPoint) record).getPoints(0);

            for (double[] point : iterable)
            {
                layer.addRenderable(
                    this.createPoint(record, point[1], point[0], mappings));
            }
        }
    }

    @SuppressWarnings({"UnusedDeclaration"})
    protected Renderable createPoint(ShapefileRecord record, double latDegrees, double lonDegrees, AVList mappings)
    {
        PointPlacemark placemark = new PointPlacemark(Position.fromDegrees(latDegrees, lonDegrees, 0));
        placemark.setAltitudeMode(WorldWind.CLAMP_TO_GROUND);

        if (this.normalPointAttributes != null)
            placemark.setAttributes(this.normalPointAttributes);
        if (this.highlightPointAttributes != null)
            placemark.setHighlightAttributes(this.highlightPointAttributes);

        if (mappings != null)
            placemark.setValues(mappings);

        return placemark;
    }

    protected void addRenderablesForPolylines(Shapefile shp, RenderableLayer layer)
    {
        ShapefilePolylines shape = new ShapefilePolylines(shp, this.normalShapeAttributes,
            this.highlightShapeAttributes, new ShapefileRenderable.AttributeDelegate()
        {
            @Override
            public void assignAttributes(ShapefileRecord shapefileRecord, ShapefileRenderable.Record renderableRecord)
            {
                if (dBaseMappings != null)
                {
                    AVList mappings = applyMappings(shapefileRecord.getAttributes(), dBaseMappings);
                    if (mappings != null)
                        renderableRecord.setValues(mappings);
                }
            }
        });

        layer.addRenderable(shape);
    }

    protected void addRenderablesForPolygons(Shapefile shp, RenderableLayer layer)
    {
        if (ShapefileUtils.hasHeightAttribute(shp))
        {
            this.addRenderablesForExtrudedPolygons(shp, layer);
        }
        else
        {
            this.addRenderablesForSurfacePolygons(shp, layer);
        }
    }

    protected void addRenderablesForSurfacePolygons(Shapefile shp, RenderableLayer layer)
    {
        ShapefilePolygons shape = new ShapefilePolygons(shp, this.normalShapeAttributes,
            this.highlightShapeAttributes, new ShapefileRenderable.AttributeDelegate()
        {
            @Override
            public void assignAttributes(ShapefileRecord shapefileRecord, ShapefileRenderable.Record renderableRecord)
            {
                if (dBaseMappings != null)
                {
                    AVList mappings = applyMappings(shapefileRecord.getAttributes(), dBaseMappings);
                    if (mappings != null)
                        renderableRecord.setValues(mappings);
                }
            }
        });

        layer.addRenderable(shape);
    }

    protected void addRenderablesForExtrudedPolygons(Shapefile shp, RenderableLayer layer)
    {
        ShapefileExtrudedPolygons shape = new ShapefileExtrudedPolygons(shp, this.normalShapeAttributes,
            this.highlightShapeAttributes, new ShapefileRenderable.AttributeDelegate()
        {
            @Override
            public void assignAttributes(ShapefileRecord shapefileRecord, ShapefileRenderable.Record renderableRecord)
            {
                if (dBaseMappings != null)
                {
                    AVList mappings = applyMappings(shapefileRecord.getAttributes(), dBaseMappings);
                    if (mappings != null)
                        renderableRecord.setValues(mappings);
                }
            }
        });

        layer.addRenderable(shape);
    }

    protected AVList applyMappings(DBaseRecord attrRecord, AVList attrMappings)
    {
        if (attrRecord == null || attrMappings == null)
            return null;

        AVList mappings = new AVListImpl();
        for (Map.Entry<String, Object> mapping : attrMappings.getEntries())
        {
            Object attrValue = attrRecord.getValue(mapping.getKey());
            if (attrValue != null)
                mappings.setValue((String) mapping.getValue(), attrValue);
        }

        return mappings.getEntries().size() > 0 ? mappings : null;
    }
}
