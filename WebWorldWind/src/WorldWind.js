/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @version $Id$
 */
define(['src/WorldWindow'], function (WorldWindow) {
    "use strict";

    var WorldWind = {
        VERSION: 0.0
    };

    WorldWind['WorldWindow'] = WorldWindow;

    window.WorldWind = WorldWind;

    return WorldWind;
});