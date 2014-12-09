/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @version $Id$
 */

requirejs(['../src/WorldWind'], function () {
    "use strict";

    WorldWind.Logger.setLoggingLevel(WorldWind.Logger.LEVEL_WARNING);

    var wwd = new WorldWind.WorldWindow("canvasOne");
    wwd.globe.equatorialRadius = 1;
    wwd.globe.polarRadius = 1;
    wwd.layers.addLayer(new WorldWind.BMNGOneImageLayer);
    wwd.layers.addLayer(new WorldWind.ShowTessellationLayer());
    wwd.redraw();
});