/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports PinchGestureRecognizer
 * @version $Id$
 */
define([
        '../navigate/GestureRecognizer'
    ],
    function (GestureRecognizer) {
        "use strict";

        /**
         * Constructs a pinch gesture recognizer.
         * @alias PinchGestureRecognizer
         * @constructor
         * @classdesc A concrete gesture recognizer subclass that looks for two finger pinch gestures.
         */
        var PinchGestureRecognizer = function (target) {
            GestureRecognizer.call(this, target);

            /**
             *
             * @type {number}
             */
            this.scale = 1;

            /**
             *
             * @type {number}
             * @protected
             */
            this.scaleOffset = 1;

            /**
             *
             * @type {number}
             * @protected
             */
            this.threshold = 10;

            /**
             *
             * @type {number}
             * @protected
             */
            this.distance = 0;

            /**
             *
             * @type {number}
             * @protected
             */
            this.startDistance = 0;

            /**
             *
             * @type {Array}
             * @protected
             */
            this.touchIds = [];
        };

        PinchGestureRecognizer.prototype = Object.create(GestureRecognizer.prototype);

        /**
         * @protected
         */
        PinchGestureRecognizer.prototype.reset = function () {
            GestureRecognizer.prototype.reset.call(this);

            this.scale = 1;
            this.scaleOffset = 1;
            this.distance = 0;
            this.startDistance = 0;
            this.touchIds = [];
        };

        /**
         *
         * @param event
         * @protected
         */
        PinchGestureRecognizer.prototype.touchStart = function (event) {
            GestureRecognizer.prototype.touchStart.call(this, event);

            if (this.touchIds.length < 2) {
                var touchesDown = event.changedTouches;
                for (var i = 0; i < touchesDown.length && this.touchIds.length < 2; i++) {
                    this.touchIds.push(touchesDown.item(i).identifier);
                }

                if (this.touchIds.length == 2) {
                    var index0 = this.indexOfTouch(this.touchIds[0]),
                        index1 = this.indexOfTouch(this.touchIds[1]);
                    this.distance = this.touchDistance(index0, index1);
                    this.startDistance = this.distance;
                    this.scaleOffset = this.scale;
                }
            }
        };

        /**
         *
         * @param event
         * @protected
         */
        PinchGestureRecognizer.prototype.touchMove = function (event) {
            GestureRecognizer.prototype.touchMove.call(this, event);

            if (this.touchIds.length == 2) {
                var index0 = this.indexOfTouch(this.touchIds[0]),
                    index1 = this.indexOfTouch(this.touchIds[1]);
                this.distance = this.touchDistance(index0, index1);
                this.scale = this.computeScale();

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
        PinchGestureRecognizer.prototype.touchEnd = function (event) {
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
        PinchGestureRecognizer.prototype.touchCancel = function (event) {
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
        PinchGestureRecognizer.prototype.removeTouchIds = function (touchList) {
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
        PinchGestureRecognizer.prototype.shouldRecognizeTouches = function () {
            return Math.abs(this.distance - this.startDistance) > this.threshold
        };

        /**
         *
         * @param indexA
         * @param indexB
         * @returns {number}
         * @protected
         */
        PinchGestureRecognizer.prototype.touchDistance = function (indexA, indexB) {
            var pointA = this.touches[indexA].clientLocation,
                pointB = this.touches[indexB].clientLocation;
            return pointA.distanceTo(pointB);
        };

        /**
         *
         * @returns {number}
         * @protected
         */
        PinchGestureRecognizer.prototype.computeScale = function() {
            return (this.distance / this.startDistance) * this.scaleOffset;
        };

        return PinchGestureRecognizer;
    });