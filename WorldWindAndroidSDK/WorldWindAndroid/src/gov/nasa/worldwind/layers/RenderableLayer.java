/*
 * Copyright (C) 2012 DreamHammer.com
 */

package gov.nasa.worldwind.layers;

import android.graphics.*;
import gov.nasa.worldwind.Disposable;
import gov.nasa.worldwind.avlist.AVList;
import gov.nasa.worldwind.event.*;
import gov.nasa.worldwind.pick.PickSupport;
import gov.nasa.worldwind.render.*;
import gov.nasa.worldwind.util.Logging;

import java.util.Collection;
import java.util.concurrent.ConcurrentLinkedQueue;

/**
 * The <code>RenderableLayer</code> class manages a collection of {@link gov.nasa.worldwind.render.Renderable} objects
 * for rendering, picking, and disposal.
 *
 * @author tag
 * @version $Id$
 * @see gov.nasa.worldwind.render.Renderable
 */
public class RenderableLayer extends AbstractLayer
{
    protected Collection<Renderable> renderables = new ConcurrentLinkedQueue<Renderable>();
    protected PickSupport pickSupport = new PickSupport();

    /** Creates a new <code>RenderableLayer</code> with a null <code>delegateOwner</code> */
    public RenderableLayer()
    {
    }

    /**
     * Adds the specified <code>renderable</code> to this layer's internal collection.
     * <p/>
     * If the <code>renderable</code> implements {@link gov.nasa.worldwind.avlist.AVList}, the layer forwards its
     * property change events to the layer's property change listeners. Any property change listeners the layer attaches
     * to the <code>renderable</code> are removed in {@link #removeRenderable(gov.nasa.worldwind.render.Renderable)},
     * {@link #removeAllRenderables()}, or {@link #dispose()}.
     *
     * @param renderable Renderable to add.
     *
     * @throws IllegalArgumentException If <code>renderable</code> is null.
     */
    public void addRenderable(Renderable renderable)
    {
        if (renderable == null)
        {
            String msg = Logging.getMessage("nullValue.RenderableIsNull");
            Logging.error(msg);
            throw new IllegalArgumentException(msg);
        }

        this.renderables.add(renderable);

        // Attach the layer as a property change listener of the renderable. This forwards property change events from
        // the renderable to the SceneController.
        if (renderable instanceof AVList)
            ((AVList) renderable).addPropertyChangeListener(this);
    }

    /**
     * Adds the contents of the specified <code>renderables</code> to this layer's internal collection.
     * <p/>
     * If any of the <code>renderables</code> implement {@link gov.nasa.worldwind.avlist.AVList}, the layer forwards
     * their property change events to the layer's property change listeners. Any property change listeners the layer
     * attaches to the <code>renderable</code> are removed in {@link #removeRenderable(gov.nasa.worldwind.render.Renderable)},
     * {@link #removeAllRenderables()}, or {@link #dispose()}.
     *
     * @param renderables Renderables to add.
     *
     * @throws IllegalArgumentException If <code>renderables</code> is null.
     */
    public void addRenderables(Iterable<? extends Renderable> renderables)
    {
        if (renderables == null)
        {
            String msg = Logging.getMessage("nullValue.IterableIsNull");
            Logging.error(msg);
            throw new IllegalArgumentException(msg);
        }

        for (Renderable renderable : renderables)
        {
            // Internal list of renderables does not accept null values.
            if (renderable != null)
                this.renderables.add(renderable);

            // Attach the layer as a property change listener of the renderable. This forwards property change events
            // from the renderable to the SceneController.
            if (renderable instanceof AVList)
                ((AVList) renderable).addPropertyChangeListener(this);
        }
    }

    /**
     * Removes the specified <code>renderable</code> from this layer's internal collection, if it exists.
     * <p/>
     * If the <code>renderable</code> implements {@link gov.nasa.worldwind.avlist.AVList}, this stops forwarding the its
     * property change events to the layer's property change listeners. Any property change listeners the layer attached
     * to the <code>renderable</code> in {@link #addRenderable(gov.nasa.worldwind.render.Renderable)} or {@link
     * #addRenderables(Iterable)} are removed.
     *
     * @param renderable Renderable to remove.
     *
     * @throws IllegalArgumentException If <code>renderable</code> is null.
     */
    public void removeRenderable(Renderable renderable)
    {
        if (renderable == null)
        {
            String msg = Logging.getMessage("nullValue.RenderableIsNull");
            Logging.error(msg);
            throw new IllegalArgumentException(msg);
        }

        this.renderables.remove(renderable);

        // Remove the layer as a property change listener of the renderable. This prevents the renderable from keeping a
        // dangling reference to the layer.
        if (renderable instanceof AVList)
            ((AVList) renderable).removePropertyChangeListener(this);
    }

    /**
     * Clears the contents of this layer's internal Renderable collection.
     * <p/>
     * If any of the <code>renderables</code> implement {@link gov.nasa.worldwind.avlist.AVList}, this stops forwarding
     * their property change events to the layer's property change listeners. Any property change listeners the layer
     * attached to the <code>renderables</code> in {@link #addRenderable(gov.nasa.worldwind.render.Renderable)} or
     * {@link #addRenderables(Iterable)} are removed.
     */
    public void removeAllRenderables()
    {
        this.clearRenderables();
    }

    protected void clearRenderables()
    {
        if (this.renderables != null && this.renderables.size() > 0)
        {
            // Remove the layer as property change listener of any renderables. This prevents the renderables from
            // keeping a dangling references to the layer.
            for (Renderable renderable : this.renderables)
            {
                if (renderable instanceof AVList)
                    ((AVList) renderable).removePropertyChangeListener(this);
            }

            this.renderables.clear();
        }
    }

    public int getNumRenderables()
    {
        return this.renderables.size();
    }

    /**
     * Returns the Iterable of Renderables currently in use by this layer.
     *
     * @return Iterable of currently active Renderables.
     */
    public Iterable<Renderable> getRenderables()
    {
        return this.getActiveRenderables();
    }

    /**
     * Returns an Iterable of currently active Renderables.
     *
     * @return Iterable of currently active Renderables.
     */
    protected Iterable<Renderable> getActiveRenderables()
    {
        return this.renderables;
    }

    /**
     * Opacity is not applied to layers of this type because each renderable typically has its own opacity control.
     *
     * @param opacity the current opacity value, which is ignored by this layer.
     */
    @Override
    public void setOpacity(double opacity)
    {
        super.setOpacity(opacity);
    }

    /**
     * Returns the layer's opacity value, which is ignored by this layer because each of its renderables typiically has
     * its own opacity control.
     *
     * @return The layer opacity, a value between 0 and 1.
     */
    @Override
    public double getOpacity()
    {
        return super.getOpacity();
    }

    /**
     * Disposes the contents of this layer's internal Renderable collection, but does not remove any elements from that
     * collection.
     * <p/>
     * If any of layer's internal Renderables implement {@link gov.nasa.worldwind.avlist.AVList}, this stops forwarding
     * their property change events to the layer's property change listeners. Any property change listeners the layer
     * attached to the <code>renderables</code> in {@link #addRenderable(gov.nasa.worldwind.render.Renderable)} or
     * {@link #addRenderables(Iterable)} are removed.
     */
    public void dispose()
    {
        this.disposeRenderables();
    }

    protected void disposeRenderables()
    {
        if (this.renderables != null && this.renderables.size() > 0)
        {
            for (Renderable renderable : this.renderables)
            {
                try
                {
                    // Remove the layer as a property change listener of the renderable. This prevents the renderable
                    // from keeping a dangling reference to the layer.
                    if (renderable instanceof AVList)
                        ((AVList) renderable).removePropertyChangeListener(this);

                    if (renderable instanceof Disposable)
                        ((Disposable) renderable).dispose();
                }
                catch (Exception e)
                {
                    String msg = Logging.getMessage("generic.ExceptionAttemptingToDisposeRenderable");
                    Logging.error(msg);
                    // continue to next renderable
                }
            }
        }

        if (this.renderables != null)
            this.renderables.clear();
    }

    protected void doPick(DrawContext dc, Point pickPoint)
    {
        this.doPick(dc, this.getActiveRenderables(), pickPoint);
    }

    protected void doRender(DrawContext dc)
    {
        this.doRender(dc, this.getActiveRenderables());
    }

    protected void doPick(DrawContext dc, Iterable<? extends Renderable> renderables, Point pickPoint)
    {
//        this.pickSupport.clearPickList();
//        this.pickSupport.beginPicking(dc);
//
//        try
//        {
//            for (Renderable renderable : renderables)
//            {
//                // If the caller has specified their own Iterable,
//                // then we cannot make any guarantees about its contents.
//                if (renderable != null)
//                {
////                    float[] inColor = new float[4];
////                    dc.getGL().glGetFloatv(GL.GL_CURRENT_COLOR, inColor, 0);
//                    Color color = dc.getUniquePickColor();
//                    dc.getGL().glColor3ub((byte) color.getRed(), (byte) color.getGreen(), (byte) color.getBlue());
//
//                    try
//                    {
//                        renderable.render(dc);
//                    }
//                    catch (Exception e)
//                    {
//                        String msg = Logging.getMessage("generic.ExceptionWhilePickingRenderable");
//                        Logging.error(msg);
//                        Logging.warning(msg, e); // show exception for this level
//                        continue; // go on to next renderable
//                    }
////
////                    dc.getGL().glColor4fv(inColor, 0);
//
//                    if (renderable instanceof Locatable)
//                    {
//                        this.pickSupport.addPickableObject(color.getRGB(), renderable,
//                            ((Locatable) renderable).getPosition(), false);
//                    }
//                    else
//                    {
//                        this.pickSupport.addPickableObject(color.getRGB(), renderable);
//                    }
//                }
//            }
//
//            this.pickSupport.resolvePick(dc, pickPoint, this);
//        }
//        finally
//        {
//            this.pickSupport.endPicking(dc);
//        }
    }

    protected void doRender(DrawContext dc, Iterable<? extends Renderable> renderables)
    {
        for (Renderable renderable : renderables)
        {
            try
            {
                // If the caller has specified their own Iterable,
                // then we cannot make any guarantees about its contents.
                if (renderable != null)
                    renderable.render(dc);
            }
            catch (Exception e)
            {
                String msg = Logging.getMessage("generic.ExceptionWhileRenderingRenderable");
                Logging.error(msg, e);
                // continue to next renderable
            }
        }
    }

    @Override
    public String toString()
    {
        return Logging.getMessage("layers.RenderableLayer.Name");
    }

    /**
     * {@inheritDoc}
     * <p/>
     * This implementation forwards the message to each Renderable that implements {@link
     * gov.nasa.worldwind.event.MessageListener}.
     *
     * @param message The message that was received.
     */
    @Override
    public void onMessage(Message message)
    {
        for (Renderable renderable : this.renderables)
        {
            try
            {
                if (renderable instanceof MessageListener)
                    ((MessageListener) renderable).onMessage(message);
            }
            catch (Exception e)
            {
                String msg = Logging.getMessage("generic.ExceptionInvokingMessageListener");
                Logging.error(msg, e);
                // continue to next renderable
            }
        }
    }
}
