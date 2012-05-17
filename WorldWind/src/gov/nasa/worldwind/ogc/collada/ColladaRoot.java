/*
 * Copyright (C) 2012 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.ogc.collada;

import gov.nasa.worldwind.exception.WWRuntimeException;
import gov.nasa.worldwind.geom.Position;
import gov.nasa.worldwind.ogc.collada.io.*;
import gov.nasa.worldwind.render.*;
import gov.nasa.worldwind.util.*;
import gov.nasa.worldwind.util.xml.*;

import javax.xml.stream.*;
import javax.xml.stream.events.XMLEvent;
import java.io.*;

/**
 * @author pabercrombie
 * @version $Id$
 */
// TODO handle URL document source
public class ColladaRoot extends ColladaAbstractObject implements Renderable
{
    /** Reference to the KMLDoc representing the KML or KMZ file. */
    protected ColladaDoc colladaDoc;
    /** The event reader used to parse the document's XML. */
    protected XMLEventReader eventReader;
    /** The input stream underlying the event reader. */
    protected InputStream eventStream;
    /** The parser context for the document. */
    protected ColladaParserContext parserContext;

    protected Position position;
    protected int altitudeMode;

    /**
     * Create a new <code>ColladaRoot</code> for a {@link File}.
     *
     * @param docSource the File containing the document.
     *
     * @throws IllegalArgumentException if the document source is null.
     * @throws IOException              if an error occurs while reading the Collada document.
     */
    public ColladaRoot(File docSource) throws IOException
    {
        super(ColladaConstants.COLLADA_NAMESPACE);

        if (docSource == null)
        {
            String message = Logging.getMessage("nullValue.DocumentSourceIsNull");
            Logging.logger().severe(message);
            throw new IllegalArgumentException(message);
        }

        this.colladaDoc = new ColladaFile(docSource);

        this.initialize();
    }

    public ColladaRoot(InputStream docSource) throws IOException
    {
        super(ColladaConstants.COLLADA_NAMESPACE);

        if (docSource == null)
        {
            String message = Logging.getMessage("nullValue.DocumentSourceIsNull");
            Logging.logger().severe(message);
            throw new IllegalArgumentException(message);
        }

        this.colladaDoc = new ColladaInputStream(docSource);

        this.initialize();
    }

    /**
     * Creates a Collada root for an untyped source. The source must be either a {@link File} or a {@link String}
     * identifying either a file path or a URL. Null is returned if the source type is not recognized.
     *
     * @param docSource either a {@link File} or a {@link String} identifying a file path or URL.
     *
     * @return a new {@link ColladaRoot} for the specified source, or null if the source type is not supported.
     *
     * @throws IllegalArgumentException if the source is null.
     * @throws IOException              if an error occurs while reading the source.
     */
    public static ColladaRoot create(Object docSource) throws IOException
    {
        if (docSource == null)
        {
            String message = Logging.getMessage("nullValue.DocumentSourceIsNull");
            Logging.logger().severe(message);
            throw new IllegalArgumentException(message);
        }

        if (docSource instanceof File)
        {
            return new ColladaRoot((File) docSource);
        }
        else if (docSource instanceof String)
        {
            File file = new File((String) docSource);
            if (file.exists())
                return new ColladaRoot(file);
        }
        else if (docSource instanceof InputStream)
            return new ColladaRoot((InputStream) docSource);

        return null;
    }

    public static ColladaRoot createAndParse(Object docSource) throws IOException, XMLStreamException
    {
        ColladaRoot colladaRoot = ColladaRoot.create(docSource);

        if (colladaRoot == null)
        {
            String message = Logging.getMessage("generic.UnrecognizedSourceTypeOrUnavailableSource",
                docSource.toString());
            throw new IllegalArgumentException(message);
        }

        // Try with a namespace aware parser.
        colladaRoot.parse();

        return colladaRoot;
    }

    /**
     * Called just before the constructor returns. If overriding this method be sure to invoke
     * <code>super.initialize()</code>.
     *
     * @throws java.io.IOException if an I/O error occurs attempting to open the document source.
     */
    protected void initialize() throws IOException
    {
        this.eventStream = this.getColladaDoc().getInputStream(); // TODO maybe wrap in buffered input stream
        this.eventReader = this.createReader(this.eventStream);
        if (this.eventReader == null)
            throw new WWRuntimeException(Logging.getMessage("XML.UnableToOpenDocument", this.getColladaDoc()));

        this.parserContext = this.createParserContext(this.eventReader);
    }

    protected ColladaDoc getColladaDoc()
    {
        return this.colladaDoc;
    }

    public Position getPosition()
    {
        return this.position;
    }

    public void setPosition(Position position)
    {
        if (position == null)
        {
            String message = Logging.getMessage("nullValue.PositionIsNull");
            Logging.logger().severe(message);
            throw new IllegalArgumentException(message);
        }

        this.position = position;
    }

    public int getAltitudeMode()
    {
        return this.altitudeMode;
    }

    public void setAltitudeMode(int altitudeMode)
    {
        this.altitudeMode = altitudeMode;
    }

    public Object resolveReference(String link)
    {
        if (link == null)
        {
            String message = Logging.getMessage("nullValue.DocumentSourceIsNull");
            Logging.logger().severe(message);
            throw new IllegalArgumentException(message);
        }

        try
        {
            String[] linkParts = link.split("#");
            String linkBase = linkParts[0];
            String linkRef = linkParts.length > 1 ? linkParts[1] : null;

            // See if it's a reference to an internal element.
            if (WWUtil.isEmpty(linkBase) && !WWUtil.isEmpty(linkRef))
                return this.getItemByID(linkRef);

            // TODO handle external references

            // If the reference was not resolved as a remote reference, look for a local element identified by the
            // reference string. This handles the case of malformed internal references that omit the # sign at the
            // beginning of the reference.
            return this.getItemByID(link);
        }
        catch (Exception e)
        {
            String message = Logging.getMessage("generic.UnableToResolveReference", link);
            Logging.logger().warning(message);
        }

        return null;
    }

    /**
     * Creates the event reader. Called from the constructor.
     *
     * @param docSource the document source to create a reader for. The type can be any of those supported by {@link
     *                  gov.nasa.worldwind.util.WWXML#openEventReader(Object)}.
     *
     * @return a new event reader, or null if the source type cannot be determined.
     */
    protected XMLEventReader createReader(Object docSource)
    {
        return WWXML.openEventReader(docSource, false);
    }

    /**
     * Invoked during {@link #initialize()} to create the parser context. The parser context is created by the global
     * {@link gov.nasa.worldwind.util.xml.XMLEventParserContextFactory}.
     *
     * @param reader the reader to associate with the parser context.
     *
     * @return a new parser context.
     */
    protected ColladaParserContext createParserContext(XMLEventReader reader)
    {
        ColladaParserContext ctx = (ColladaParserContext)
            XMLEventParserContextFactory.createParserContext(ColladaConstants.COLLADA_MIME_TYPE,
                this.getNamespaceURI());

        if (ctx == null)
        {
            // Register a parser context for this root's default namespace
            String[] mimeTypes = new String[] {ColladaConstants.COLLADA_MIME_TYPE};
            XMLEventParserContextFactory.addParserContext(mimeTypes, new ColladaParserContext(this.getNamespaceURI()));
            ctx = (ColladaParserContext)
                XMLEventParserContextFactory.createParserContext(ColladaConstants.COLLADA_MIME_TYPE,
                    this.getNamespaceURI());
        }

        ctx.setEventReader(reader);

        return ctx;
    }

    /**
     * Starts document parsing. This method initiates parsing of the KML document and returns when the full document has
     * been parsed.
     *
     * @param args optional arguments to pass to parsers of sub-elements.
     *
     * @return <code>this</code> if parsing is successful, otherwise  null.
     *
     * @throws XMLStreamException if an exception occurs while attempting to read the event stream.
     */
    public ColladaRoot parse(Object... args) throws XMLStreamException
    {
        ColladaParserContext ctx = this.parserContext;

        try
        {
            for (XMLEvent event = ctx.nextEvent(); ctx.hasNext(); event = ctx.nextEvent())
            {
                if (event == null)
                    continue;

                // Allow a <COLLADA> element in any namespace
                if (event.isStartElement() && event.asStartElement().getName().getLocalPart().equals("COLLADA"))
                {
                    super.parse(ctx, event, args);
                    return this;
                }
            }
        }
        finally
        {
            ctx.getEventReader().close();
            this.closeEventStream();
        }
        return null;
    }

    /** Closes the event stream associated with this context's XML event reader. */
    protected void closeEventStream()
    {
        try
        {
            this.eventStream.close();
            this.eventStream = null;
        }
        catch (IOException e)
        {
            String message = Logging.getMessage("generic.ExceptionClosingXmlEventReader");
            Logging.logger().warning(message);
        }
    }

    public ColladaLibraryGeometries getGeometryLibrary()
    {
        return (ColladaLibraryGeometries) this.getField("library_geometries");
    }

    public ColladaLibraryMaterials getMaterialLibrary()
    {
        return (ColladaLibraryMaterials) this.getField("library_materials");
    }

    public ColladaLibraryEffects getEffectLibrary()
    {
        return (ColladaLibraryEffects) this.getField("library_effects");
    }

    public ColladaLibraryImages getImageLibrary()
    {
        return (ColladaLibraryImages) this.getField("library_images");
    }

    public ColladaLibraryVisualScenes getSceneLibrary()
    {
        return (ColladaLibraryVisualScenes) this.getField("library_visual_scenes");
    }

    public ColladaScene getScene()
    {
        return (ColladaScene) this.getField("scene");
    }

    public void render(DrawContext dc)
    {
        // COLLADA doc contains at most one scene. See COLLADA spec pg 5-67.
        ColladaScene scene = this.getScene();
        if (scene != null)
            scene.render(dc);
    }

    protected XMLEventParserContext getParserContext()
    {
        return this.parserContext;
    }

    /**
     * Finds a named element in the document.
     *
     * @param id the element's identifier. If null, null is returned.
     *
     * @return the element requested, or null if there is no corresponding element in the document.
     */
    public Object getItemByID(String id)
    {
        return id != null ? this.getParserContext().getIdTable().get(id) : null;
    }
}
