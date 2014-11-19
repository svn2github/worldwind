/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @version $Id$
 */
requirejs.config({
    baseUrl : ".."
});

requirejs(['src/WorldWind'], function () {
    "use strict";

    var wwd = new WorldWind.WorldWindow("canvasOne");
    wwd.render();
});