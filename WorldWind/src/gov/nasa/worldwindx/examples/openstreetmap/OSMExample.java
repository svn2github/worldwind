/*
 * Copyright (C) 2012 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwindx.examples.openstreetmap;

import gov.nasa.worldwind.util.WWIO;
import gov.nasa.worldwindx.examples.ApplicationTemplate;

import javax.xml.stream.XMLStreamException;
import java.io.*;

/**
 * Shows how to display Open Street Map data that has been installed into the local cache. All that's necessary is to
 * create a layer for OSM nodes and a layer for OSM ways and add them to the World Window's layer list, passing those
 * layers an OSM shape factory.
 * <p/>
 * See {@link OSMDataInstaller for an example of installing Open Street Map data.}
 *
 * @author tag
 * @version $Id$
 */
public class OSMExample extends ApplicationTemplate
{
    public static class AppFrame extends ApplicationTemplate.AppFrame
    {
        public AppFrame()
        {
            try
            {
                // Create an OSM shape factory, which the layers use to create OSM shapes as necessary.
                OSMShapeFactory shapeFactory = new OSMShapeFactory(this.getOSMConfigurationStream());

                // Create one layer for OSM ways and another for OSM nodes. Add the to the World Window.
                insertBeforeCompass(getWwd(), new OSMWayLayer(shapeFactory));
                insertBeforeCompass(getWwd(), new OSMNodeLayer(shapeFactory));
            }
            catch (XMLStreamException e)
            {
                e.printStackTrace();
            }

            getLayerPanel().update(getWwd());
        }

        protected InputStream getOSMConfigurationStream()
        {
            // The OSM shape factory consults an OSM attributes configuration file to determine the size, colors and
            // other attributes to use when displaying OSM nodes and ways. The attribute file can also contain
            // exclusion instructions to prevent display of OSM nodes or ways based on their declared features. The
            // default configuration file is used below.
            Object o = WWIO.getFileOrResourceAsStream("config/Earth/OSMAttributes.xml", OSMCacheBuilder.class);
            if (o instanceof Exception)
            {
                ((Exception) o).printStackTrace();
                return null;
            }

            return (InputStream) o;
        }
    }

    public static void main(String[] args)
    {
        ApplicationTemplate.start("World Wind Open Street Map Example", AppFrame.class);
    }
}
