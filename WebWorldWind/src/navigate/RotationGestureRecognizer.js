/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports RotationGestureRecognizer
 * @version $Id$
 */
define([
        '../geom/Angle',
        '../navigate/GestureRecognizer',
        '../geom/Vec2'
    ],
    function (Angle,
              GestureRecognizer,
              Vec2) {
        "use strict";

        /**
         * Constructs a rotation gesture recognizer.
         * @alias RotationGestureRecognizer
         * @constructor
         * @classdesc A concrete gesture recognizer subclass that looks for two finger rotation gestures.
         */
        var RotationGestureRecognizer = function (target) {
            GestureRecognizer.call(this, target);

            /**
             *
             * @type {number}
             */
            this.rotation = 0;

            /**
             *
             * @type {number}
             * @protected
             */
            this.rotationOffset = 0;

            /**
             *
             * @type {number}
             * @protected
             */
            this.threshold = 10;

            /**
             *
             * @type {Vec2}
             * @protected
             */
            this.slope = new Vec2(0, 0);

            /**
             *
             * @type {Vec2}
             * @protected
             */
            this.beginSlope = new Vec2(0, 0);

            /**
             *
             * @type {Array}
             * @protected
             */
            this.touchIds = [];
        };

        RotationGestureRecognizer.prototype = Object.create(GestureRecognizer.prototype);

        /**
         * @protected
         */
        RotationGestureRecognizer.prototype.reset = function () {
            GestureRecognizer.prototype.reset.call(this);

            this.rotation = 0;
            this.rotationOffset = 0;
            this.slope.set(0, 0);
            this.beginSlope.set(0, 0);
            this.touchIds = [];
        };

        /**
         *
         * @param event
         * @protected
         */
        RotationGestureRecognizer.prototype.touchStart = function (event) {
            GestureRecognizer.prototype.touchStart.call(this, event);

            if (this.touchIds.length < 2) {
                var touchesDown = event.changedTouches;
                for (var i = 0; i < touchesDown.length && this.touchIds.length < 2; i++) {
                    this.touchIds.push(touchesDown.item(i).identifier);
                }

                if (this.touchIds.length == 2) {
                    var index0 = this.indexOfTouch(this.touchIds[0]),
                        index1 = this.indexOfTouch(this.touchIds[1]);
                    this.slope = this.touchSlope(index0, index1);
                    this.beginSlope = this.slope;
                    this.rotationOffset = this.rotation;
                }
            }
        };

        /**
         *
         * @param event
         * @protected
         */
        RotationGestureRecognizer.prototype.touchMove = function (event) {
            GestureRecognizer.prototype.touchMove.call(this, event);

            if (this.touchIds.length == 2) {
                var index0 = this.indexOfTouch(this.touchIds[0]),
                    index1 = this.indexOfTouch(this.touchIds[1]);
                this.slope = this.touchSlope(index0, index1);
                this.rotation = this.computeRotation();

                if (this.state == GestureRecognizer.POSSIBLE) {
                    if (this.shouldRecognizeTouches()) {
                        this.transitionToState(GestureRecognizer.BEGAN);
                    }
                } else if (this.state == GestureRecognizer.BEGAN || this.state == GestureRecognizer.CHANGED) {
                    this.transitionToState(GestureRecognizer.CHANGED);
                }
            }
        };

        /**
         *
         * @param event
         * @protected
         */
        RotationGestureRecognizer.prototype.touchEnd = function (event) {
            GestureRecognizer.prototype.touchEnd.call(this, event);

            // Remove touch identifier entries for the touches that ended or cancelled.
            this.removeTouchIds(event.changedTouches);

            if (event.targetTouches.length == 0) { // last touches ended
                if (this.state == GestureRecognizer.BEGAN || this.state == GestureRecognizer.CHANGED) {
                    this.transitionToState(GestureRecognizer.ENDED);
                }
            }
        };

        /**
         *
         * @param event
         * @protected
         */
        RotationGestureRecognizer.prototype.touchCancel = function (event) {
            GestureRecognizer.prototype.touchCancel.call(this, event);

            // Remove touch identifier entries for the touches that ended or cancelled.
            this.removeTouchIds(event.changedTouches);

            if (event.targetTouches.length == 0) { // last touches cancelled
                if (this.state == GestureRecognizer.BEGAN || this.state == GestureRecognizer.CHANGED) {
                    this.transitionToState(GestureRecognizer.CANCELLED);
                }
            }
        };

        /**
         *
         * @param touchList
         * @protected
         */
        RotationGestureRecognizer.prototype.removeTouchIds = function (touchList) {
            for (var i = 0, count = touchList.length; i < count; i++) {
                var index = this.touchIds.indexOf(touchList.item(i).identifier);
                if (index != -1) {
                    this.touchIds.splice(index, 1);
                }
            }
        };

        /**
         *
         * @returns {boolean}
         * @protected
         */
        RotationGestureRecognizer.prototype.shouldRecognizeTouches = function () {
            return Math.abs(this.slope[0] - this.beginSlope[0]) > this.threshold
                || Math.abs(this.slope[1] - this.beginSlope[1]) > this.threshold;
        };

        /**
         *
         * @param indexA
         * @param indexB
         * @returns {number}
         * @protected
         */
        RotationGestureRecognizer.prototype.touchSlope = function (indexA, indexB) {
            var pointA = this.touches[indexA].clientLocation,
                pointB = this.touches[indexB].clientLocation;
            return new Vec2(pointA[0] - pointB[0], pointA[1] - pointB[1]);
        };

        /**
         *
         * @param slope
         * @returns {number}
         * @protected
         */
        RotationGestureRecognizer.prototype.angleForSlope = function (slope) {
            var radians = Math.atan2(slope[1], slope[0]);
            return radians * Angle.RADIANS_TO_DEGREES;
        };

        /**
         *
         * @returns {number}
         * @protected
         */
        RotationGestureRecognizer.prototype.computeRotation = function () {
            var angle = this.angleForSlope(this.slope),
                beginAngle = this.angleForSlope(this.beginSlope),
                rotation = angle - beginAngle + this.rotationOffset;
            return Angle.normalizedDegrees(rotation);
        };

        return RotationGestureRecognizer;
    });
