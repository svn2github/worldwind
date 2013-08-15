/*
 * Copyright (C) 2013 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */
package gov.nasa.worldwindx.applications.eurogeoss;

import java.util.*;

/**
 * @author dcollins
 * @version $Id$
 */
public class Record
{
    protected String title;
    protected Collection<OnlineResource> wmsOnlineResources = new ArrayList<OnlineResource>();

    public Record()
    {
    }

    public String getTitle()
    {
        return this.title;
    }

    public void setTitle(String title)
    {
        this.title = title;
    }

    public Collection<OnlineResource> getWmsOnlineResources()
    {
        return this.wmsOnlineResources;
    }

    public void setWmsOnlineResources(Collection<OnlineResource> wmsOnlineResources)
    {
        this.wmsOnlineResources = wmsOnlineResources;
    }
}
