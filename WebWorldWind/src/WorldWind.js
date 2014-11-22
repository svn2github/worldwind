/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @version $Id$
 */
define(['src/WorldWindow', 'src/util/Logger'], function (WorldWindow, Logger) {
    "use strict";
    /**
     * This is the top-level World Wind module. It is global.
     * @exports WorldWind
     * @global
     */
    var WorldWind = {
        /**
         * The World Wind version number.
         * @default "0.0.0"
         * @constant
         */
        VERSION: "0.0.0",

        /**
         * Indicates a great circle path.
         * @constant
         */
        GREAT_CIRCLE: "greatCircle",
        /**
         * Indicates a rhumb path -- a path of constant bearing.
         * @constant
         */
        RHUMB_LINE: "rhumbLine",
        /**
         * Indicates a linear, straight line path.
         * @constant
         */
        LINEAR:"linear"
    };

    WorldWind['WorldWindow'] = WorldWindow;
    WorldWind['Logger'] = Logger;

    window.WorldWind = WorldWind;

    return WorldWind;
});