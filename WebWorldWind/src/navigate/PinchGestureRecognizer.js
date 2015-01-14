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
         * @classdesc A concrete gesture recognizer subclass that looks for two-finger pinch gestures.
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
            this.threshold = 5;

            /**
             *
             * @type {number}
             * @protected
             */
            this.beginDistance = 0;

            /**
             *
             * @type {number}
             * @protected
             */
            this.distance = 0;

            /**
             *
             * @type {Array}
             * @protected
             */
            this.pinchTouches = [];
        };

        PinchGestureRecognizer.prototype = Object.create(GestureRecognizer.prototype);

        /**
         * 
         */
        PinchGestureRecognizer.prototype.reset = function () {
            GestureRecognizer.prototype.reset.call(this);

            this.scale = 1;
            this.scaleOffset = 1;
            this.beginDistance = 0;
            this.distance = 0;
            this.pinchTouches = [];
        };

        /**
         *
         * @param event
         * @returns {boolean}
         */
        PinchGestureRecognizer.prototype.shouldBeginWithTouchEvent = function (event) {
            return Math.abs(this.distance - this.beginDistance) > this.threshold
        };

        /**
         *
         * @returns {number}
         */
        PinchGestureRecognizer.prototype.pinchDistance = function () {
            var touchA, touchB,
                dx, dy;

            if (this.pinchTouches.length < 2) {
                return 0;
            } else {
                touchA = this.touchWithIdentifier(this.pinchTouches[0]);
                touchB = this.touchWithIdentifier(this.pinchTouches[1]);
                dx = touchA.screenX - touchB.screenX;
                dy = touchA.screenY - touchB.screenY;

                return Math.sqrt(dx * dx + dy * dy);
            }
        };

        /**
         *
         * @param event
         */
        PinchGestureRecognizer.prototype.touchStart = function (event) {
            var touchesDown = event.changedTouches;

            if (this.pinchTouches.length < 2) {
                for (var i = 0; i < touchesDown.length && this.pinchTouches.length < 2; i++) {
                    this.pinchTouches.push(touchesDown.item(i).identifier);
                }

                if (this.pinchTouches.length == 2) {
                    this.beginDistance = this.pinchDistance();
                    this.scaleOffset = this.scale;
                }
            }
        };

        /**
         *
         * @param event
         */
        PinchGestureRecognizer.prototype.touchMove = function (event) {
            if (this.pinchTouches.length == 2) {
                this.distance = this.pinchDistance();
                this.scale = this.scaleOffset * (this.distance / this.beginDistance);
            }

            if (this.state == GestureRecognizer.POSSIBLE) {
                if (this.pinchTouches.length == 2) {
                    if (this.shouldBeginWithTouchEvent(event)) {
                        this.transitionToState(GestureRecognizer.BEGAN, event);
                    }
                }
            } else if (this.state == GestureRecognizer.BEGAN || this.state == GestureRecognizer.CHANGED) {
                this.transitionToState(GestureRecognizer.CHANGED, event);
            }
        };

        // TODO: Capture the common pattern in touchEnd and touchCancel

        /**
         *
         * @param event
         */
        PinchGestureRecognizer.prototype.touchEnd = function (event) {
            var touchesUp = event.changedTouches;

            for (var i = 0, count = touchesUp.length; i < count; i++) {
                this.removeTouch(touchesUp.item(i).identifier);
            }

            if (event.targetTouches.length == 0) {
                if (this.state == GestureRecognizer.BEGAN || this.state == GestureRecognizer.CHANGED) {
                    this.transitionToState(GestureRecognizer.ENDED, event);
                    this.reset();
                } else if (this.state == GestureRecognizer.FAILED) {
                    this.reset();
                }
            }
        };

        /**
         *
         * @param event
         */
        PinchGestureRecognizer.prototype.touchCancel = function (event) {
            var touchesUp = event.changedTouches;

            for (var i = 0, count = touchesUp.length; i < count; i++) {
                this.removeTouch(touchesUp.item(i).identifier);
            }

            if (event.targetTouches.length == 0) {
                if (this.state == GestureRecognizer.BEGAN || this.state == GestureRecognizer.CHANGED) {
                    this.transitionToState(GestureRecognizer.CANCELLED, event);
                    this.reset();
                } else if (this.state == GestureRecognizer.FAILED) {
                    this.reset();
                }
            }
        };


        PinchGestureRecognizer.prototype.removeTouch = function (identifier) {
            for (var i = 0, count = this.pinchTouches.length; i < count; i++) {
                if (this.pinchTouches[i] == identifier) {
                    this.pinchTouches.splice(i, 1);
                    break;
                }
            }
        };

        return PinchGestureRecognizer;
    });