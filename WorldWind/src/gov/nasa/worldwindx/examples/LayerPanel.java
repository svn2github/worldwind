/*
 * Copyright (C) 2012 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */
package gov.nasa.worldwindx.examples;

import gov.nasa.worldwind.WorldWindow;
import gov.nasa.worldwindx.examples.layermanager.*;

import javax.swing.*;
import java.awt.*;

/**
 * Panel to display a list of layers. A layer can be turned on or off by clicking a check box next to the layer name.
 *
 * @version $Id$
 *
 * @see LayerTreeUsage
 * @see OnScreenLayerManager
 */
public class LayerPanel extends JPanel
{
    protected LayerManagerPanel layerManagerPanel;
    protected ElevationModelManagerPanel elevationModelManagerPanel;

    public LayerPanel(WorldWindow wwd)
    {
        super(new BorderLayout(10, 10));

        this.add(this.layerManagerPanel = new LayerManagerPanel(wwd), BorderLayout.CENTER);

        this.add(this.elevationModelManagerPanel = new ElevationModelManagerPanel(wwd), BorderLayout.SOUTH);
    }

    public void updateLayers(WorldWindow wwd)
    {
        this.layerManagerPanel.update(wwd);
    }

    public void updateElevations(WorldWindow wwd)
    {
        this.elevationModelManagerPanel.update(wwd);
    }
}
