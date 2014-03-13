/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwindx.applications;

import gov.nasa.worldwind.BasicFactory;
import gov.nasa.worldwind.avlist.AVKey;
import gov.nasa.worldwind.event.*;
import gov.nasa.worldwind.geom.Sector;
import gov.nasa.worldwind.retrieve.*;
import gov.nasa.worldwind.terrain.CompoundElevationModel;

/**
 * @author tag
 * @version $Id$
 *
 * This class downloads specially configured imagery and elevations for the World Wind iOS TAIGA application.
 */
public class BulkDownloadAlaska
{
    public static void main(String[] args)
    {
        try
        {
            Sector alaskaSector = Sector.fromDegrees(55.7, 71.1, -169.2, -129.5);

            BulkRetrievable layer = (BulkRetrievable) BasicFactory.create(AVKey.LAYER_FACTORY,
                "config/Earth/BMNG256.xml");
            System.out.println(layer.getName());
            BulkRetrievalThread thread = layer.makeLocal(alaskaSector, 0, new BulkRetrievalListener()
            {
                @Override
                public void eventOccurred(BulkRetrievalEvent event)
                {
                    System.out.println(event.getItem());
                }
            });
            thread.join();

            layer = (BulkRetrievable) BasicFactory.create(AVKey.LAYER_FACTORY,
                "config/Earth/Landsat256.xml");
            System.out.println(layer.getName());
            thread = layer.makeLocal(alaskaSector, 0, new BulkRetrievalListener()
            {
                @Override
                public void eventOccurred(BulkRetrievalEvent event)
                {
                    System.out.println(event.getItem());
                }
            });
            thread.join();

            CompoundElevationModel cem = (CompoundElevationModel) BasicFactory.create(AVKey.ELEVATION_MODEL_FACTORY,
                "config/Earth/EarthElevations256.xml");
            layer = (BulkRetrievable) cem.getElevationModels().get(0);
            System.out.println(layer.getName());
            thread = layer.makeLocal(alaskaSector, 0, new BulkRetrievalListener()
            {
                @Override
                public void eventOccurred(BulkRetrievalEvent event)
                {
                    System.out.println(event.getItem());
                }
            });
            thread.join();
        }
        catch (InterruptedException e)
        {
            e.printStackTrace();
        }
    }
}
