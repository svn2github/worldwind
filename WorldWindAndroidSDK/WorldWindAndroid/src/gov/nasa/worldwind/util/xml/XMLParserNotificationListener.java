/*
 * Copyright (C) 2012 DreamHammer.com
 */

package gov.nasa.worldwind.util.xml;

/**
 * @author tag
 * @version $Id$
 */
public interface XMLParserNotificationListener
{
    /**
     * Receives notification events from the parser context.
     *
     * @param notification the notification object containing the notificaton type and data.
     */
    public void notify(XMLParserNotification notification);
}
