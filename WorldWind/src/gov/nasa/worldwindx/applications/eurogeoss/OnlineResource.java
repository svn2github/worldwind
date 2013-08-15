/*
 * Copyright (C) 2013 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */
package gov.nasa.worldwindx.applications.eurogeoss;

/**
 * @author dcollins
 * @version $Id$
 */
public class OnlineResource
{
    protected String linkage;
    protected String name;
    protected String protocol;

    public OnlineResource()
    {
    }

    public String getLinkage()
    {
        return this.linkage;
    }

    public void setLinkage(String linkage)
    {
        this.linkage = linkage;
    }

    public String getName()
    {
        return this.name;
    }

    public void setName(String name)
    {
        this.name = name;
    }

    public String getProtocol()
    {
        return this.protocol;
    }

    public void setProtocol(String protocol)
    {
        this.protocol = protocol;
    }

    @Override
    public boolean equals(Object o)
    {
        if (this == o)
            return true;
        if (o == null || this.getClass() != o.getClass())
            return false;

        OnlineResource that = (OnlineResource) o;

        if (this.linkage != null ? !this.linkage.equals(that.linkage) : that.linkage != null)
            return false;
        if (this.name != null ? !this.name.equals(that.name) : that.name != null)
            return false;
        if (this.protocol != null ? !this.protocol.equals(that.protocol) : that.protocol != null)
            return false;

        return true;
    }

    @Override
    public int hashCode()
    {
        int result = this.linkage != null ? this.linkage.hashCode() : 0;
        result = 31 * result + (this.name != null ? this.name.hashCode() : 0);
        result = 31 * result + (this.protocol != null ? this.protocol.hashCode() : 0);
        return result;
    }

    @Override
    public String toString()
    {
        StringBuilder sb = new StringBuilder();
        sb.append("linkage=").append(this.linkage);
        sb.append(",name=").append(this.name);
        sb.append(",protocol=").append(this.protocol);

        return sb.toString();
    }
}
