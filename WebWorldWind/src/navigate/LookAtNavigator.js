/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports LookAtNavigator
 * @version $Id$
 */
define([
        '../geom/Frustum',
        '../util/Logger',
        '../geom/Matrix',
        '../navigate/NavigatorState'
    ],
    function (Frustum,
              Logger,
              Matrix,
              NavigatorState) {
        "use strict";

        /**
         * Constructs a look-at navigator.
         * @alias LookAtNavigator
         * @constructor
         * @classdesc Represents a navigator that enables the user to pan, zoom and tilt the globe.
         */
        var LookAtNavigator = function () {
            this.modelview = Matrix.fromIdentity();
            this.projection = Matrix.fromIdentity();
            this.heading = 0;
            this.tilt = 0;
        };

        /**
         * Returns the navigator state for this navigator's current settings.
         * @returns {NavigatorState} This navigator's current navigator state.
         */
        LookAtNavigator.prototype.currentState = function () {
            return new NavigatorState(this.modelview, this.projection, this.viewport, this.heading, this.tilt);
        };

        return LookAtNavigator;
    });