/*
 * Copyright (C) 2011 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.ogc.kml.impl;

import gov.nasa.worldwind.*;
import gov.nasa.worldwind.geom.Position;
import gov.nasa.worldwind.ogc.collada.*;
import gov.nasa.worldwind.ogc.kml.*;
import gov.nasa.worldwind.render.DrawContext;
import gov.nasa.worldwind.util.*;

import javax.xml.stream.XMLStreamException;
import java.io.IOException;
import java.util.*;
import java.util.concurrent.atomic.*;

public class KMLModelPlacemarkImpl extends WWObjectImpl implements KMLRenderable
{
    protected KMLModel model;
    protected KMLPlacemark parent;
    protected AtomicReference<ColladaRoot> colladaRoot = new AtomicReference<ColladaRoot>();
    /**
     * Time, in milliseconds since the Epoch, at which this placemark's model resource was last retrieved. Initially
     * <code>-1</code>, indicating that the resource has not been retrieved.
     */
    protected AtomicLong resourceRetrievalTime = new AtomicLong(-1);

    /**
     * Create an instance.
     *
     * @param tc        the current {@link KMLTraversalContext}.
     * @param placemark the <i>Placemark</i> element containing the <i>Point</i>.
     * @param geom      the {@link gov.nasa.worldwind.ogc.kml.KMLPoint} geometry.
     *
     * @throws NullPointerException     if the geometry is null.
     * @throws IllegalArgumentException if the parent placemark or the traversal context is null.
     */
    public KMLModelPlacemarkImpl(KMLTraversalContext tc, KMLPlacemark placemark, KMLAbstractGeometry geom)
    {
        if (tc == null)
        {
            String msg = Logging.getMessage("nullValue.TraversalContextIsNull");
            Logging.logger().severe(msg);
            throw new IllegalArgumentException(msg);
        }

        if (placemark == null)
        {
            String msg = Logging.getMessage("nullValue.ParentIsNull");
            Logging.logger().severe(msg);
            throw new IllegalArgumentException(msg);
        }

        if (geom == null)
        {
            String msg = Logging.getMessage("nullValue.GeometryIsNull");
            Logging.logger().severe(msg);
            throw new IllegalArgumentException(msg);
        }

        this.model = (KMLModel) geom;
        this.parent = placemark;
    }

    protected Map<String, Object> createResourceMap(KMLModel model)
    {
        Map<String, Object> map = new HashMap<String, Object>();

        for (KMLAlias alias : model.getResourceMap().getAliases())
        {
            if (alias != null && !WWUtil.isEmpty(alias.getSourceRef()))
            {
                String targetHref = this.formAliasTarget(model, alias);
                if (!WWUtil.isEmpty(targetHref))
                    map.put(alias.getSourceRef(), targetHref);
            }
        }

        return map.size() > 0 ? map : null;
    }

    protected String formAliasTarget(KMLModel model, KMLAlias alias)
    {
        try
        {
            String targetHref = model.getRoot().getSupportFilePath(alias.getTargetHref());
            return !WWUtil.isEmpty(targetHref) ? targetHref : alias.getTargetHref();
        }
        catch (IOException e)
        {
            return alias.getTargetHref();
        }
    }

    /**
     * Specifies the Collada resource referenced by this placemark, or <code>null</code> if this placemark has no
     * resource.
     *
     * @param root the Collada resource referenced by this placemark. May be <code>null</code>.
     */
    protected void setColladaRoot(ColladaRoot root)
    {
        this.colladaRoot.set(root);
    }

    /**
     * Indicates the Collada resource referenced by this placemark. This returns <code>null</code> if this placemark has
     * no resource.
     *
     * @return this placemark's Collada resource, or <code>null</code> to indicate that this placemark has no resource.
     *
     * @see #setColladaRoot(gov.nasa.worldwind.ogc.collada.ColladaRoot)
     */
    protected ColladaRoot getColladaRoot()
    {
        return this.colladaRoot.get();
    }

    public void preRender(KMLTraversalContext tc, DrawContext dc)
    {
        if (this.mustRetrieveResource())
            this.requestResource(dc);
    }

    public void render(KMLTraversalContext tc, DrawContext dc)
    {
        if (this.model.getLink() == null)
            return;

        String address = this.model.getLink().getAddress(dc);
        if (WWUtil.isEmpty(address))
            return;

        ColladaRoot root = this.getColladaRoot();
        if (root != null)
        {
            root.render(new ColladaTraversalContext(), dc);
        }
    }

    /**
     * Returns whether this placemark must retrieve its model resource. This always returns <code>false</code> if this
     * placemark has no <code>KMLLink</code>.
     *
     * @return <code>true</code> if this placemark must retrieve its model resource, otherwise <code>false</code>.
     */
    protected boolean mustRetrieveResource()
    {
        KMLLink link = this.model.getLink();
        if (link == null)
            return false;

        // The resource must be retrieved if the link has been updated since the resource was
        // last retrieved, or if the resource has never been retrieved.
        return this.getColladaRoot() == null || link.getUpdateTime() > this.resourceRetrievalTime.get();
    }

    /**
     * Thread's off a task to determine whether the resource is local or remote and then retrieves it either from disk
     * cache or a remote server.
     *
     * @param dc the current draw context.
     */
    protected void requestResource(DrawContext dc)
    {
        if (WorldWind.getTaskService().isFull())
            return;

        KMLLink link = this.model.getLink();
        if (link == null)
            return;

        String address = link.getAddress(dc);
        if (address != null)
            address = address.trim();

        if (WWUtil.isEmpty(address))
            return;

        WorldWind.getTaskService().addTask(new RequestTask(this, address));
    }

    /**
     * Initiates a retrieval of the model referenced by this placemark. Once the resource is retrieved and loaded, this
     * calls <code>{@link #setColladaRoot(ColladaRoot)}</code> to specify this link's new network resource, and sends an
     * <code>{@link gov.nasa.worldwind.avlist.AVKey#RETRIEVAL_STATE_SUCCESSFUL}</code> property change event to this
     * link's property change listeners.
     * <p/>
     * This does nothing if this <code>KMLNetworkLink</code> has no <code>KMLLink</code>.
     *
     * @param address the address of the resource to retrieve
     */
    protected void retrieveModel(String address) throws IOException, XMLStreamException
    {
        Object o = this.parent.getRoot().resolveReference(address);
        ColladaRoot root = ColladaRoot.create(o);
        if (root != null)
        {
            root.parse();

            Position refPosition = this.model.getLocation().getPosition();
            root.setPosition(refPosition);
            root.setAltitudeMode(KMLUtil.convertAltitudeMode(this.model.getAltitudeMode()));

            this.setColladaRoot(root);
            this.parent.getRoot().requestRedraw();
        }
    }

    /** Attempts to find this model link resource file locally, and if that fails attempts to find it remotely. */
    protected static class RequestTask implements Runnable
    {
        /** The link associated with this request. */
        protected final KMLModelPlacemarkImpl placemark;
        /** The resource's address. */
        protected final String address;

        /**
         * Construct a request task for a specified network link resource.
         *
         * @param placemark the placemark for which to construct the request task.
         * @param address   the address of the resource to request.
         */
        protected RequestTask(KMLModelPlacemarkImpl placemark, String address)
        {
            if (placemark == null)
            {
                String message = Logging.getMessage("nullValue.ObjectIsNull");
                Logging.logger().severe(message);
                throw new IllegalArgumentException(message);
            }

            if (address == null)
            {
                String message = Logging.getMessage("nullValue.PathIsNull");
                Logging.logger().severe(message);
                throw new IllegalArgumentException(message);
            }

            this.placemark = placemark;
            this.address = address;
        }

        public void run()
        {
            if (Thread.currentThread().isInterrupted())
                return; // the task was cancelled because it's a duplicate or for some other reason

            try
            {
                this.placemark.retrieveModel(this.address);
            }
            catch (IOException e)
            {
                String message = Logging.getMessage("generic.ExceptionWhileReading", e.getMessage());
                Logging.logger().warning(message);
            }
            catch (XMLStreamException e)
            {
                String message = Logging.getMessage("generic.ExceptionAttemptingToParseXml", e.getMessage());
                Logging.logger().warning(message);
            }
        }

        @Override
        public boolean equals(Object o)
        {
            if (this == o)
                return true;
            if (o == null || getClass() != o.getClass())
                return false;

            RequestTask that = (RequestTask) o;

            if (!this.address.equals(that.address))
                return false;
            //noinspection RedundantIfStatement
            if (!this.placemark.equals(that.placemark))
                return false;

            return true;
        }

        @Override
        public int hashCode()
        {
            int result = placemark.hashCode();
            result = 31 * result + address.hashCode();
            return result;
        }

        @Override
        public String toString()
        {
            return this.address;
        }
    }
}