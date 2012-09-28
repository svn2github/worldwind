/* Copyright (C) 2001, 2012 United States Government as represented by 
the Administrator of the National Aeronautics and Space Administration. 
All Rights Reserved.
*/
package gov.nasa.worldwindx.examples;

import android.os.Bundle;
import gov.nasa.worldwind.BasicView;
import gov.nasa.worldwind.geom.*;
import gov.nasa.worldwind.globes.Globe;
import gov.nasa.worldwind.kml.KMLRoot;
import gov.nasa.worldwind.kml.impl.KMLController;
import gov.nasa.worldwind.layers.*;
import gov.nasa.worldwind.util.*;

import java.io.InputStream;

/**
 * @author dcollins
 * @version $Id$
 */
public class KMLActivity extends BasicWorldWindActivity
{
    protected static final String ALASKA_FLIGHT_PASSAGEWAYS_PATH = "data/AlaskaFlightPassageways.kml";

    @Override
    public void onCreate(Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);

        this.addKMLFile(ALASKA_FLIGHT_PASSAGEWAYS_PATH);
    }

    protected void addKMLFile(final String path)
    {
        Thread t = new Thread(new Runnable()
        {
            public void run()
            {
                try
                {
                    InputStream stream = WWIO.openFileOrResourceStream(path, null);
                    KMLRoot kmlRoot = KMLRoot.createAndParse(stream);
                    KMLController kmlController = new KMLController(kmlRoot);
                    RenderableLayer layer = new RenderableLayer();
                    layer.addRenderable(kmlController);
                    addLayerInRenderingThread(layer);
                }
                catch (Exception e)
                {
                    String msg = Logging.getMessage("generic.ExceptionOpeningPath", path);
                    Logging.error(msg, e);
                }
            }
        });
        t.start();
    }

    protected void addLayerInRenderingThread(final Layer layer)
    {
        this.wwd.invokeInRenderingThread(new Runnable()
        {
            public void run()
            {
                wwd.getModel().getLayers().add(layer);
            }
        });
    }

    @Override
    protected void setupView()
    {
        super.setupView();

        BasicView view = (BasicView) this.wwd.getView();
        Globe globe = this.wwd.getModel().getGlobe();

        // Configure the view to start looking at the Alaska Flight Passageways KML file.
        Position eyePos = Position.fromDegrees(61.7, -148.7, 4700000);
        view.setEyePosition(eyePos, Angle.fromDegrees(0), Angle.fromDegrees(0), globe);
        view.setLookAtTilt(Angle.fromDegrees(30), globe);
    }
}
