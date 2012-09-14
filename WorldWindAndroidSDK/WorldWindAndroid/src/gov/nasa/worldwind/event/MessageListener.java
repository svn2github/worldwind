/*
 * Copyright (C) 2012 DreamHammer.com
 */

package gov.nasa.worldwind.event;


/**
 * Listener for general purpose message events.
 *
 * @author pabercrombie
 * @version $Id$
 */
public interface MessageListener
{
    /**
     * Invoked when a message is received.
     *
     * @param msg The message that was received.
     */
    void onMessage(Message msg);
}
