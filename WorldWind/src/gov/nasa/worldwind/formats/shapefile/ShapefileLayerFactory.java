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
 * Converts Shapefile geometry into World Wind renderable objects.
 * <p/>
 * <h1>Shapefile Geometry Conversion</h1>
 * <p/>
 * Shapefile geometries are mapped to World Wind objects as follows:
 * <p/>
 * <table> <tr><th>Shapefile Geometry</th><th>World Wind Object</th></tr> <tr><td>Point</td><td>{@link
 * gov.nasa.worldwind.render.PointPlacemark}</td></tr> <tr><td>MultiPoint</td><td>List of {@link
 * gov.nasa.worldwind.render.PointPlacemark}</td></tr> <tr><td>Polyline</td><td>{@link
 * gov.nasa.worldwind.formats.shapefile.ShapefilePolylines}</td></tr> <tr><td>Polygon</td><td>{@link
 * gov.nasa.worldwind.formats.shapefile.ShapefilePolygons}</td></tr> </table>
 * <p/>
 * In addition, if the DBase attributes file associated with the shapefile has an attribute named "height" or "hgt", the
 * shapes in the shapefile are mapped to {@link gov.nasa.worldwind.formats.shapefile.ShapefileExtrudedPolygons}.
 * <p/>
 * <h1>Shapefile Attributes</h1>
 * <p/>
 * Shapefiles may have associated with them a DBase attributes file. This class provides a mechanism for mapping
 * attribute names in the DBase file to keys assigned to the created shapes. The mapping is specified as key/value
 * pairs, the key is the attribute name in the shapefile's DBase attributes file, the value is the key name to attach to
 * the created shape to hold the value of the specified attribute. Thus, for example, the value of per-record "NAME"
 * fields in the DBase attributes may be mapped to a {@link gov.nasa.worldwind.avlist.AVKey#DISPLAY_NAME} key in the
 * av-list of the created shapes corresponding to each record. The mapping's key/value pairs are specified using {@link
 * #setDBaseMappings(gov.nasa.worldwind.avlist.AVList)}.
 * <p/>
 * The rendering attributes applied to the created shapes may be specified to this class, either via the attribute
 * accessors of this class or a configuration file passed to {@link #createLayerFromConfigDocument(org.w3c.dom.Element,
 * gov.nasa.worldwind.avlist.AVList, CompletionCallback)}.
 * <p/>
 * The key-value attributes and the rendering attributes of certain created shapes may be specified programmatically
 * using a ShapefileRenderable.AttributeDelegate. The delegate is called for each shapefile record encountered during
 * parsing, after this factory applies its DBase attribute mapping and its default rendering attributes. Currently,
 * attribute delegates are called when parsing shapefiles containing polylines, polygons or extruded polygons.
 * shapefiles containing points or multi-points ignore the attribute delegate. The delegate is specified using {@link
 * #setAttributeDelegate(gov.nasa.worldwind.formats.shapefile.ShapefileRenderable.AttributeDelegate)}.
 *
 * @author tag
 * @version $Id$
 */
public class ShapefileLayerFactory implements ShapefileRenderable.AttributeDelegate
{
    /**
     * Defines an interface for receiving notifications when shapefile parsing completes or encounters an exception.
     * This interface's methods are typically executed on a separate thread created by the factory. Implementations must
     * synchronize access to objects that are not thread safe.
     */
    public interface CompletionCallback
    {
        /**
         * Called when shapefile parsing and geometry conversion completes. Always called before the factory's thread
         * terminates.
         *
         * @param layer  The layer that renders the shapefile's contents.
         * @param source The shapefile source passed to this factory.
         */
        void completion(Layer layer, Object source);

        /**
         * Called if exception occurs during shapefile parsing or shapefile geometry conversion. May be called multiple
         * times during shapefile parsing.
         *
         * @param e      The exception thrown.
         * @param source The shapefile source passed to this factory.
         */
        void exception(Exception e, Object source);
    }

    protected AVList dBaseMappings;
    protected ShapeAttributes normalShapeAttributes;
    protected ShapeAttributes highlightShapeAttributes;
    protected PointPlacemarkAttributes normalPointAttributes;
    protected PointPlacemarkAttributes highlightPointAttributes;
    protected ShapefileRenderable.AttributeDelegate attributeDelegate;

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
     * Indicates the attribute delegate called for each shapefile record encountered during parsing.
     *
     * @return The attribute delegate called for each shapefile record.
     */
    public ShapefileRenderable.AttributeDelegate getAttributeDelegate()
    {
        return this.attributeDelegate;
    }

    /**
     * Specifies an attribute delegate to call for each shapefile record encountered during parsing. The delegate is
     * called after this factory applies its DBase attribute mapping and its default rendering attributes.
     * <p/>
     * Currently, attribute delegates are called when parsing shapefiles containing polylines, polygons or extruded
     * polygons. shapefiles containing points or multi-points ignore the attribute delegate.
     *
     * @param attributeDelegate The attribute delegate to call for each shapefile record.
     */
    public void setAttributeDelegate(ShapefileRenderable.AttributeDelegate attributeDelegate)
    {
        this.attributeDelegate = attributeDelegate;
    }

    /**
     * Applies this factory's DBase attribute mapping and default rendering attributes to the specified records. If an
     * attribute delegate has been specified using {@link #setAttributeDelegate(gov.nasa.worldwind.formats.shapefile.ShapefileRenderable.AttributeDelegate)},
     * this calls the attribute delegate before exiting.
     *
     * @param shapefileRecord  The shapefile record used to create the ShapefileRenderable.Record.
     * @param renderableRecord The ShapefileRenderable.Record to assign attributes for.
     */
    @Override
    public void assignAttributes(ShapefileRecord shapefileRecord, ShapefileRenderable.Record renderableRecord)
    {
        if (this.dBaseMappings != null)
        {
            AVList mappings = this.applyMappings(shapefileRecord.getAttributes(), this.dBaseMappings);
            if (mappings != null)
                renderableRecord.setValues(mappings);
        }

        if (this.attributeDelegate != null)
        {
            this.attributeDelegate.assignAttributes(shapefileRecord, renderableRecord);
        }
    }

    /**
     * Creates a {@link gov.nasa.worldwind.layers.Layer} from a general shapefile layer configuration element. The
     * element may contain elements specifying shapefile attribute mappings, shape attributes to assign to created
     * shapes, and layer properties.
     * <p/>
     * This returns with the new layer immediately, but executes shapefile parsing and shapefile geometry conversion on
     * a separate thread. Shapefile geometry is added to the returned layer as it becomes available. Once parsing
     * completes, this executes the specified callback's completion method, passing the completed layer and the
     * configuration element.
     * <p/>
     * If an exception occurs during shapefile parsing and geometry conversion, this calls the callback's exception
     * method, passing the exception and the configuration element. When an exception causes layer parsing or geometry
     * conversion to fail, this calls the callback's completion method before the separate thread terminates.
     *
     * @param domElement The configuration element.
     * @param params     Key/value pairs to associate with the created layer. Values specified here override
     *                   corresponding values specified within the configuration element.
     * @param callback   A callback to notify when shapefile parsing completes or encounters an exception. May be null.
     *
     * @return A Layer that renders the shapefile's contents.
     *
     * @throws IllegalArgumentException if the element is null, or the element does not specify the shapefile location.
     */
    public Layer createLayerFromConfigDocument(final Element domElement, AVList params,
        final CompletionCallback callback)
    {
        if (domElement == null)
        {
            String message = Logging.getMessage("nullValue.ElementIsNull");
            Logging.logger().severe(message);
            throw new IllegalArgumentException(message);
        }

        final String shapefileLocation = WWXML.getText(domElement, "ShapefileLocation");
        if (WWUtil.isEmpty(shapefileLocation))
        {
            String message = Logging.getMessage("SHP.ShapefileLocationUnspecified");
            Logging.logger().severe(message);
            return null;
        }

        final RenderableLayer layer = new RenderableLayer();

        if (params == null)
            params = new AVListImpl();

        // Common layer properties.
        AbstractLayer.getLayerConfigParams(domElement, params);
        layer.setValues(params);

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

        WorldWind.getScheduledTaskService().addTask(new Runnable()
        {
            @Override
            public void run()
            {
                Shapefile shp = null;
                try
                {
                    shp = new Shapefile(shapefileLocation);
                    addRenderablesForShapefile(shp, layer);
                }
                catch (Exception e)
                {
                    if (callback != null)
                        callback.exception(e, domElement);
                }
                finally
                {
                    WWIO.closeStream(shp, shapefileLocation);
                    if (callback != null)
                        callback.completion(layer, domElement);
                }
            }
        });

        return layer;
    }

    /**
     * Creates a {@link gov.nasa.worldwind.layers.Layer} from a general shapefile.
     * <p/>
     * This returns with the new layer immediately, but executes shapefile parsing and shapefile geometry conversion on
     * a separate thread. Shapefile geometry is added to the returned layer as it becomes available. Once parsing
     * completes, this executes the specified callback's completion method, passing the completed layer and the
     * shapefile.
     * <p/>
     * If an exception occurs during shapefile parsing and geometry conversion, this calls the callback's exception
     * method, passing the exception and the shapefile. When an exception causes layer parsing or geometry conversion to
     * fail, this calls the callback's completion method before the separate thread terminates.
     *
     * @param shp      the Shapefile to create a layer for.
     * @param callback A callback to notify when shapefile parsing completes or encounters an exception. May be null.
     *
     * @return A Layer that renders the shapefile's contents.
     *
     * @throws IllegalArgumentException if the shapefile is null, or if the shapefile's primitive type is unrecognized.
     */
    public Layer createLayerFromShapefile(final Shapefile shp, final CompletionCallback callback)
    {
        if (shp == null)
        {
            String message = Logging.getMessage("nullValue.ShapefileIsNull");
            Logging.logger().severe(message);
            throw new IllegalArgumentException(message);
        }

        final RenderableLayer layer = new RenderableLayer();

        WorldWind.getScheduledTaskService().addTask(new Runnable()
        {
            @Override
            public void run()
            {
                try
                {
                    addRenderablesForShapefile(shp, layer);
                }
                catch (Exception e)
                {
                    if (callback != null)
                        callback.exception(e, shp);
                }
                finally
                {
                    if (callback != null)
                        callback.completion(layer, shp);
                }
            }
        });

        return layer;
    }

    /**
     * Creates a {@link gov.nasa.worldwind.layers.Layer} from a general shapefile source. The source type may be one of
     * the following: <ul> <li>{@link java.io.InputStream}</li> <li>{@link java.net.URL}</li> <li>{@link
     * java.io.File}</li> <li>{@link String} containing a valid URL description or a file or resource name available on
     * the classpath.</li> </ul>
     * <p/>
     * This returns with the new layer immediately, but executes shapefile parsing and shapefile geometry conversion on
     * a separate thread. Shapefile geometry is added to the returned layer as it becomes available. Once parsing
     * completes, this executes the specified callback's completion method, passing the completed layer and the
     * shapefile source.
     * <p/>
     * If an exception occurs during shapefile parsing and geometry conversion, this calls the callback's exception
     * method, passing the exception and the shapefile source. When an exception causes layer parsing or geometry
     * conversion to fail, this calls the callback's completion method before the separate thread terminates.
     *
     * @param source   the source of the shapefile.
     * @param callback A callback to notify when shapefile parsing completes or encounters an exception. May be null.
     *
     * @return A Layer that renders the shapefile's contents.
     *
     * @throws IllegalArgumentException if the source is null or an empty string, or if the shapefile's primitive type
     *                                  is unrecognized.
     */
    public Layer createLayerFromShapefileSource(final Object source, final CompletionCallback callback)
    {
        if (WWUtil.isEmpty(source))
        {
            String message = Logging.getMessage("nullValue.SourceIsNull");
            Logging.logger().severe(message);
            throw new IllegalArgumentException(message);
        }

        final RenderableLayer layer = new RenderableLayer();

        WorldWind.getScheduledTaskService().addTask(new Runnable()
        {
            @Override
            public void run()
            {
                Shapefile shp = null;
                try
                {
                    shp = new Shapefile(source);
                    addRenderablesForShapefile(shp, layer);
                }
                catch (Exception e)
                {
                    if (callback != null)
                        callback.exception(e, source);
                }
                finally
                {
                    WWIO.closeStream(shp, source.toString());
                    if (callback != null)
                        callback.completion(layer, source);
                }
            }
        });

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

    protected void addRenderablesForShapefile(Shapefile shp, RenderableLayer layer)
    {
        if (Shapefile.isPointType(shp.getShapeType()))
        {
            this.addRenderablesForPoints(shp, layer);
        }
        else if (Shapefile.isMultiPointType(shp.getShapeType()))
        {
            this.addRenderablesForMultiPoints(shp, layer);
        }
        else if (Shapefile.isPolylineType(shp.getShapeType()))
        {
            this.addRenderablesForPolylines(shp, layer);
        }
        else if (Shapefile.isPolygonType(shp.getShapeType()))
        {
            this.addRenderablesForPolygons(shp, layer);
        }
        else
        {
            Logging.logger().warning(Logging.getMessage("generic.UnrecognizedShapeType", shp.getShapeType()));
        }

        if (shp.getBoundingRectangle() != null)
        {
            layer.setValue(AVKey.SECTOR, Sector.fromDegrees(shp.getBoundingRectangle()));
        }

        layer.firePropertyChange(AVKey.LAYER, null, layer);
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
            this.highlightShapeAttributes, this);
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
            this.highlightShapeAttributes, this);
        layer.addRenderable(shape);
    }

    protected void addRenderablesForExtrudedPolygons(Shapefile shp, RenderableLayer layer)
    {
        ShapefileExtrudedPolygons shape = new ShapefileExtrudedPolygons(shp, this.normalShapeAttributes,
            this.highlightShapeAttributes, this);
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
