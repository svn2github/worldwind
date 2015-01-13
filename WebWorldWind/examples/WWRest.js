/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @version $Id$
 */

requirejs(['../src/WorldWind',
        './LayerManager/LayerManager'],
    function (ww,
              LayerManager) {
        "use strict";

        WorldWind.Logger.setLoggingLevel(WorldWind.Logger.LEVEL_WARNING);

        var wwd = new WorldWind.WorldWindow("canvasOne");
        wwd.addLayer(new WorldWind.BMNGRestLayer(null, "../data/Earth/BMNG256-200404", "Blue Marble"));
        wwd.addLayer(new WorldWind.LandsatRestLayer(null, "../data/Earth/LandSat", "LandSat"));
        wwd.addLayer(new WorldWind.BingWMSLayer());

        wwd.globe.elevationModel = new WorldWind.EarthRestElevationModel(null, "../data/Earth/EarthElevations2",
            "Earth Elevations");

        wwd.redraw();

        var layerManger = new LayerManager('divLayerManager', wwd);
    });