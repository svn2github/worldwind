/*
 * Copyright (C) 2012 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.ogc.collada;

import gov.nasa.worldwind.WorldWind;
import gov.nasa.worldwind.exception.WWRuntimeException;
import gov.nasa.worldwind.geom.*;
import gov.nasa.worldwind.ogc.collada.impl.*;
import gov.nasa.worldwind.ogc.collada.io.*;
import gov.nasa.worldwind.render.DrawContext;
import gov.nasa.worldwind.util.*;
import gov.nasa.worldwind.util.xml.*;

import javax.xml.stream.*;
import javax.xml.stream.events.XMLEvent;
import java.io.*;
import java.net.*;

/**
 * @author pabercrombie
 * @version $Id$
 */
public class ColladaRoot extends ColladaAbstractObject implements ColladaRenderable
{
    /** Reference to the ColladaDoc representing the COLLADA file. */
    protected ColladaDoc colladaDoc;
    /** The event reader used to parse the document's XML. */
    protected XMLEventReader eventReader;
    /** The input stream underlying the event reader. */
    protected InputStream eventStream;
    /** The parser context for the document. */
    protected ColladaParserContext parserContext;

    protected Position position;
    protected int altitudeMode;

    protected ColladaResourceResolver resourceResolver;

    /**
     * Create a new <code>ColladaRoot</code> for a {@link ColladaDoc} instance. A ColladaDoc represents COLLADA files
     * from either files or input streams.
     *
     * @param docSource the ColladaDoc instance representing the COLLADA document.
     *
     * @throws IllegalArgumentException if the document source is null.
     * @throws IOException              if an error occurs while reading the COLLADA document.
     */
    public ColladaRoot(ColladaDoc docSource) throws IOException
    {
        super(ColladaConstants.COLLADA_NAMESPACE);

        if (docSource == null)
        {
            String message = Logging.getMessage("nullValue.DocumentSourceIsNull");
            Logging.logger().severe(message);
            throw new IllegalArgumentException(message);
        }

        this.colladaDoc = docSource;
        this.initialize();
    }

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

    public ColladaRoot(URL docSource) throws IOException
    {
        super(ColladaConstants.COLLADA_NAMESPACE);

        if (docSource == null)
        {
            String message = Logging.getMessage("nullValue.DocumentSourceIsNull");
            Logging.logger().severe(message);
            throw new IllegalArgumentException(message);
        }

        URLConnection conn = docSource.openConnection();
        this.colladaDoc = new ColladaInputStream(conn.getInputStream(), WWIO.makeURI(docSource));

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

        this.colladaDoc = new ColladaInputStream(docSource, null);

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
        else if (docSource instanceof URL)
        {
            return new ColladaRoot((URL) docSource);
        }
        else if (docSource instanceof String)
        {
            File file = new File((String) docSource);
            if (file.exists())
                return new ColladaRoot(file);

            URL url = WWIO.makeURL(docSource);
            if (url != null)
                return new ColladaRoot(url);
        }
        else if (docSource instanceof InputStream)
        {
            return new ColladaRoot((InputStream) docSource);
        }

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

    public ColladaResourceResolver getResourceResolver()
    {
        return this.resourceResolver;
    }

    public void setResourceResolver(ColladaResourceResolver resourceResolver)
    {
        this.resourceResolver = resourceResolver;
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

            // Interpret the path relative to the current document.
            String path = this.getSupportFilePath(linkBase);
            if (path == null)
                path = linkBase;

            // See if it's an already found and parsed COLLADA file.
            Object o = WorldWind.getSessionCache().get(path);
            if (o != null && o instanceof ColladaRoot)
                return linkRef != null ? ((ColladaRoot) o).getItemByID(linkRef) : o;

            URL url = WWIO.makeURL(path);
            if (url == null)
            {
                // See if the reference can be resolved to a local file.
                o = this.resolveLocalReference(path, linkRef);
            }

            // If we didn't find a local file, treat it as a remote reference.
            if (o == null)
                o = this.resolveRemoteReference(path, linkRef);

            if (o != null)
                return o;

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
     * Resolves a reference to a local element identified by address and identifier, where {@code linkBase} identifies a
     * document, including the current document, and {@code linkRef} is the id of the desired element.
     * <p/>
     * If {@code linkBase} refers to a local COLLADA file and {@code linkRef} is non-null, the return value is the
     * element identified by {@code linkRef}. If {@code linkRef} is null, the return value is a parsed {@link
     * ColladaRoot} for the COLLADA file identified by {@code linkBase}. Otherwise, {@code linkBase} is returned.
     *
     * @param linkBase the address of the document containing the requested element.
     * @param linkRef  the element's identifier.
     *
     * @return the requested element, or null if the element is not found.
     *
     * @throws IllegalArgumentException if the address is null.
     */
    protected Object resolveLocalReference(String linkBase, String linkRef)
    {
        if (linkBase == null)
        {
            String message = Logging.getMessage("nullValue.DocumentSourceIsNull");
            Logging.logger().severe(message);
            throw new IllegalArgumentException(message);
        }

        try
        {
            File file = new File(linkBase);

            if (!file.exists())
                return null;

            // Determine whether the file is a COLLADA document. If not, just return the file path.
            if (!WWIO.isContentType(file, ColladaConstants.COLLADA_MIME_TYPE))
                return file.toURI().toString();

            // Attempt to open and parse the COLLADA file.
            ColladaRoot refRoot = ColladaRoot.createAndParse(file);
            // An exception is thrown if parsing fails, so no need to check for null.

            // Add the parsed file to the session cache so it doesn't have to be parsed again.
            WorldWind.getSessionCache().put(linkBase, refRoot);

            // Now check the newly opened COLLADA file for the referenced item, if a reference was specified.
            if (linkRef != null)
                return refRoot.getItemByID(linkRef);
            else
                return refRoot;
        }
        catch (Exception e)
        {
            String message = Logging.getMessage("generic.UnableToResolveReference", linkBase + "/" + linkRef);
            Logging.logger().warning(message);
            return null;
        }
    }

    /**
     * Resolves a reference to a remote element identified by address and identifier, where {@code linkBase} identifies
     * a remote document, and {@code linkRef} is the id of the desired element. This method retrieves resources
     * asynchronously using the {@link gov.nasa.worldwind.cache.FileStore}.
     * <p/>
     * The return value is null if the file is not yet available in the FileStore. If {@code linkBase} refers to a
     * COLLADA file and {@code linkRef} is non-null, the return value is the element identified by {@code linkRef}. If
     * {@code linkBase} refers to a COLLADA file and {@code linkRef} is null, the return value is a parsed {@link
     * ColladaRoot} for the COLLADA file identified by {@code linkBase}. Otherwise the return value is a {@link URL} to
     * the file in the file cache.
     *
     * @param linkBase the address of the document containing the requested element.
     * @param linkRef  the element's identifier.
     *
     * @return URL to the requested file, parsed ColladaRoot, or COLLADA element. Returns null if the document is not
     *         yet available in the FileStore.
     *
     * @throws IllegalArgumentException if the {@code linkBase} is null.
     */
    public Object resolveRemoteReference(String linkBase, String linkRef)
    {
        if (linkBase == null)
        {
            String message = Logging.getMessage("nullValue.DocumentSourceIsNull");
            Logging.logger().severe(message);
            throw new IllegalArgumentException(message);
        }

        try
        {
            // See if it's in the cache. If not, requestFile will start another thread to retrieve it and return null.
            URL url = WorldWind.getDataFileStore().requestFile(linkBase);
            if (url == null)
                return null;

            // It's in the cache. If it's a COLLADA file try to parse it so we can search for the specified reference.
            // If it's not COLLADA, just return the url for the cached file.
            String contentType = WorldWind.getDataFileStore().getContentType(linkBase);
            if (contentType == null)
            {
                String suffix = WWIO.getSuffix(linkBase.split(";")[0]); // strip of trailing garbage
                if (!WWUtil.isEmpty(suffix))
                    contentType = WWIO.makeMimeTypeForSuffix(suffix);
            }

            if (!this.canParseContentType(contentType))
                return url;

            // If the file is a COLLADA document, attempt to open it. We can't open it as a File with createAndParse
            // because the ColladaRoot that will be created needs to have the remote address in order to resolve any
            // relative references within it.
            ColladaRoot refRoot = this.parseCachedColladaFile(url, linkBase);

            // Add the parsed file to the session cache so it doesn't have to be parsed again.
            WorldWind.getSessionCache().put(linkBase, refRoot);

            // Now check the newly opened COLLADA file for the referenced item, if a reference was specified.
            if (linkRef != null)
                return refRoot.getItemByID(linkRef);
            else
                return refRoot;
        }
        catch (Exception e)
        {
            String message = Logging.getMessage("generic.UnableToResolveReference", linkBase + "/" + linkRef);
            Logging.logger().warning(message);
            return null;
        }
    }

    /**
     * Determines if a MIME type can be parsed as COLLADA. Parsable types are the COLLADA MIME type, as well as
     * "text/plain" and "text/xml".
     *
     * @param mimeType Type to test. May be null.
     *
     * @return {@code true} if {@code mimeType} can be parsed as COLLADA.
     */
    protected boolean canParseContentType(String mimeType)
    {
        return ColladaConstants.COLLADA_MIME_TYPE.equals(mimeType)
            || "text/plain".equals(mimeType) || "text/xml".equals(mimeType);
    }

    /**
     * Open and parse the specified file expressed as a file: URL..
     *
     * @param url      the URL of the file to open, expressed as a URL with a scheme of "file".
     * @param linkBase the original address of the document if the file is a retrieved and cached file.
     *
     * @return A {@code ColladaRoot} representing the file's COLLADA contents.
     *
     * @throws IOException        if an I/O error occurs during opening and parsing.
     * @throws XMLStreamException if a server parsing error is encountered.
     */
    protected ColladaRoot parseCachedColladaFile(URL url, String linkBase)
        throws IOException, XMLStreamException
    {
        ColladaDoc colladaDoc;

        InputStream refStream = url.openStream();

        colladaDoc = new ColladaInputStream(refStream, WWIO.makeURI(linkBase));

        try
        {
            ColladaRoot refRoot = new ColladaRoot(colladaDoc);
            refRoot.parse(); // also closes the URL's stream
            return refRoot;
        }
        catch (XMLStreamException e)
        {
            refStream.close(); // parsing failed, so explicitly close the stream
            throw e;
        }
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
     * Starts document parsing. This method initiates parsing of the COLLADA document and returns when the full document
     * has been parsed.
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

    public ColladaScene getScene()
    {
        return (ColladaScene) this.getField("scene");
    }

    public ColladaAsset getAsset()
    {
        return (ColladaAsset) this.getField("asset");
    }

    public void preRender(ColladaTraversalContext tc, DrawContext dc)
    {
        // Apply scaling factor to convert file units to meters.
        double scale = this.getScale();
        tc.multiplyMatrix(Matrix.fromScale(scale));

        // COLLADA doc contains at most one scene. See COLLADA spec pg 5-67.
        ColladaScene scene = this.getScene();
        if (scene != null)
            scene.preRender(tc, dc);
    }

    public void render(ColladaTraversalContext tc, DrawContext dc)
    {
        // Apply scaling factor to convert file units to meters.
        double scale = this.getScale();
        tc.multiplyMatrix(Matrix.fromScale(scale));

        ColladaScene scene = this.getScene();
        if (scene != null)
            scene.render(tc, dc);
    }

    /**
     * Indicates the scale defined by the asset/unit element. This scale converts the document's units to meters.
     *
     * @return Scale for this document, or 1.0 if no scale is defined.
     */
    protected double getScale()
    {
        Double scale = null;

        ColladaAsset asset = this.getAsset();
        if (asset != null)
        {
            ColladaUnit unit = asset.getUnit();
            if (unit != null)
                scale = unit.getMeter();
        }
        return (scale != null) ? scale : 1.0;
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

    public String getSupportFilePath(String link) throws IOException
    {
        String filePath = null;

        // Use the resource resolver to find the file.
        ColladaResourceResolver resolver = this.getResourceResolver();
        if (resolver != null)
            filePath = resolver.resolveFilePath(link);

        // If the resolver failed to find the file then attempt to resolve the reference relative to the document.
        if (filePath == null)
            filePath = this.getColladaDoc().getSupportFilePath(link);

        return filePath;
    }
}
