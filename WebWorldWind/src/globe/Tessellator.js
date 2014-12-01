/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports Tessellator
 * @version $Id$
 */
define([
        'src/error/ArgumentError',
        'src/globe/Globe',
        'src/util/Logger',
        'src/navigate/NavigatorState',
        'src/globe/Terrain'
    ],
    function (ArgumentError,
              Globe,
              Logger,
              NavigatorState,
              Terrain) {
        "use strict";

        /**
         * Constructs a Tessellator object for a specified globe.
         * @alias Tessellator
         * @constructor
         * @classdesc Represents a tessellator for a specified globe.
         */
        var Tessellator = function () {
        };

        /**
         * Tessellates the geometry of the globe associated with this terrain.
         * @param {Globe} globe The globe on which this tessellator operates.
         * @param {NavigatorState} navigatorState The navigator state to use when computing terrain.
         * @param {Number} verticalExaggeration The vertical exaggeration to apply to the computed terrain.
         * @returns {Terrain} The computed terrain, or null if terrain could not be computed.
         */
        Tessellator.prototype.tessellate = function (globe, navigatorState, verticalExaggeration) {
            if (!globe) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Tessellator", "tessellate", "missingGlobe"));
            }

            if (!navigatorState) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Tessellator", "tessellate", "missingNavigatorState"));
            }

            // TODO

            return null;
        };

        return Tessellator;
    });