/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports NavigatorState
 * @version $Id$
 */
define([
        'src/geom/Frustum',
        'src/util/Logger',
        'src/geom/Matrix',
        'src/geom/Rectangle',
        'src/geom/Vec3'
    ],
    function (Frustum,
              Logger,
              Matrix,
              Rectangle,
              Vec3) {
        "use strict";

        /**
         * Constructs navigator state. This constructor is meant to be called by navigators when their current state
         * is requested.
         * @alias NavigatorState
         * @constructor
         * @classdesc Represents the state of a navigator.
         */
        var NavigatorState = function () {

            /**
             * The navigator's Cartesian eye point relative to the globe's center. This value is meant to be read-only
             * once it is set by the associated navigator.
             * @type {Vec3}
             */
            this.eyePoint = new Vec3(0, 0, 0);

            /**
             * The navigator's viewport, in screen coordinates. This value is meant to be read-only
             * once it is set by the associated navigator.
             * @type {Rectangle}
             */
            this.viewport = new Rectangle(0, 0, 0, 0);

            /**
             * The navigator's model-view matrix. This value is meant to be read-only
             * once it is set by the associated navigator.
             * @type {Matrix}
             */
            this.modelview = Matrix.fromIdentity();

            /**
             * The navigator's projection matrix. This value is meant to be read-only
             * once it is set by the associated navigator.
             * @type {Matrix}
             */
            this.projection = Matrix.fromIdentity();

            /**
             * The concatenation of the navigator's model-view and projection matrices. This value is meant to be
             * read-only once it is set by the associated navigator.
             * @type {Matrix}
             */
            this.modelviewProjection = Matrix.fromIdentity();

            this.forwardRay = new Vec3(0, 0, 0);

            this.frustumInModelCoordinates = null;

            this.heading = 0;

            this.tilt = 0;
        };

        NavigatorState.prototype.project = function(modelPoint, result) {
            // TODO
        };

        NavigatorState.prototype.projectWithDepth = function(modelPoint, depthOffset, result) {
            // TODO
        };

        NavigatorState.prototype.unProject = function(screenPoint, result) {
            // TODO
        };

        NavigatorState.prototype.convertPointToView = function(screenPoint) {
            // TODO
        };

        NavigatorState.prototype.convertPointToViewport = function(point) {
            // TODO
        };

        NavigatorState.prototype.rayFromScreenPoint = function(screenPoint) {
            // TODO
        };

        NavigatorState.prototype.pixelSizeAtDistance = function(distance) {
            // TODO
        };

        return NavigatorState;
    });