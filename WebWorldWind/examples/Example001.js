/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @version $Id$
 */
//requirejs.config({
//    baseUrl : ".."
//});

requirejs(['../src/WorldWind'], function () {
    "use strict";

    //TestStart.showMessage("Hi There! This is yet another message");
    WorldWind.Logger.setLoggingLevel(WorldWind.Logger.LEVEL_WARNING);

    var wwd = new WorldWind.WorldWindow("canvasOne");
    wwd.render();
});