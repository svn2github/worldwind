/*
 * Copyright (C) 2013 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */
package gov.nasa.worldwindx.applications.eurogeoss;

import gov.nasa.worldwind.util.*;

import java.io.*;
import java.net.*;

/**
 * @author dcollins
 * @version $Id$
 */
public class CatalogConnection
{
    protected String serviceUrl;
    protected int connectTimeout = 10000;
    protected int readTimeout = 10000;

    public CatalogConnection(String serviceUrl)
    {
        if (serviceUrl == null)
        {
            String msg = Logging.getMessage("nullValue.ServiceIsNull");
            Logging.logger().severe(msg);
            throw new IllegalArgumentException(msg);
        }

        this.serviceUrl = serviceUrl;
    }

    public String getServiceUrl()
    {
        return this.serviceUrl;
    }

    public int getConnectTimeout()
    {
        return this.connectTimeout;
    }

    public void setConnectTimeout(int timeout)
    {
        this.connectTimeout = timeout;
    }

    public int getReadTimeout()
    {
        return this.readTimeout;
    }

    public void setReadTimeout(int timeout)
    {
        this.readTimeout = timeout;
    }

    public GetRecordsResponse getRecords(GetRecordsRequest request) throws IOException
    {
        if (request == null)
        {
            String msg = Logging.getMessage("nullValue.RequestIsNull");
            Logging.logger().severe(msg);
            throw new IllegalArgumentException(msg);
        }

        URL url = WWIO.makeURL(this.serviceUrl);

        HttpURLConnection conn = (HttpURLConnection) url.openConnection();
        conn.setDoOutput(true);
        conn.setRequestMethod("POST");
        conn.setRequestProperty("Content-Type", "application/xml; charset=utf-8");
        conn.setConnectTimeout(this.getConnectTimeout());
        conn.setReadTimeout(this.getReadTimeout());

        OutputStreamWriter writer = new OutputStreamWriter(conn.getOutputStream(), "UTF-8");
        writer.write(request.toXMLString());
        writer.close();

        if (Thread.interrupted())
            return null;

        if (conn.getResponseCode() == HttpURLConnection.HTTP_OK)
        {
            return new GetRecordsResponse(conn.getInputStream());
        }
        else
        {
            String msg = Logging.getMessage("HTTP.ResponseCode", conn.getResponseCode(), this.serviceUrl);
            throw new IOException(msg);
        }
    }
}
