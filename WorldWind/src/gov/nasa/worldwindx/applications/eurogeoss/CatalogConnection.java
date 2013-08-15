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

        OutputStreamWriter writer = new OutputStreamWriter(conn.getOutputStream(), "UTF-8");
        writer.write(request.toXMLString());
        writer.close();

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
