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
        '../navigate/Navigator',
        '../geom/Position'
    ],
    function (Frustum,
              Logger,
              Matrix,
              Navigator,
              Position) {
        "use strict";

        /**
         * Constructs a look-at navigator.
         * @alias LookAtNavigator
         * @constructor
         * @augments Navigator
         * @classdesc Represents a navigator that enables the user to pan, zoom and tilt the globe.
         */
        var LookAtNavigator = function (worldWindow) {
            Navigator.call(this, worldWindow);
            /**
             * The geographic position this navigator is directed towards.
             * @type {Position}
             */
            this.lookAtPosition = new Position(30, -90, 0);

            /**
             * The distance of the eye from this navigator's look-at position.
             * @type {number}
             */
            this.range = 10e6; // TODO: Compute initial range to fit globe in viewport.
        };

        LookAtNavigator.prototype = Object.create(Navigator.prototype);

        /**
         * Returns the navigator state for this navigator's current settings.
         * @returns {NavigatorState} This navigator's current navigator state.
         */
        LookAtNavigator.prototype.currentState = function () {
            var modelview = Matrix.fromIdentity();

            modelview.multiplyByLookAtModelview(this.lookAtPosition, this.range, this.heading, this.tilt, this.roll,
                this.worldWindow.globe);

            return this.currentStateForModelview(modelview);
        };

        return LookAtNavigator;
    });