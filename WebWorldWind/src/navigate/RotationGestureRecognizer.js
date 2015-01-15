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
            this.threshold = 5;

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
            this.touchIdentifiers = [];

        };

        RotationGestureRecognizer.prototype = Object.create(GestureRecognizer.prototype);

        /**
         *
         */
        RotationGestureRecognizer.prototype.reset = function () {
            GestureRecognizer.prototype.reset.call(this);

            this.rotation = 0;
            this.rotationOffset = 0;
            this.slope.set(0, 0);
            this.beginSlope.set(0, 0);
            this.touchIdentifiers = [];
        };

        /**
         *
         * @param event
         * @returns {boolean}
         */
        RotationGestureRecognizer.prototype.shouldBeginWithTouchEvent = function (event) {
            return Math.abs(this.slope[0] - this.beginSlope[0]) > this.threshold
                || Math.abs(this.slope[1] - this.beginSlope[1]) > this.threshold;
        };

        /**
         *
         * @param result
         */
        RotationGestureRecognizer.prototype.touchSlope = function (result) {
            var touchA, touchB,
                dx, dy;

            if (this.touchIdentifiers.length < 2) {
                result.set(0, 0);
            } else {
                touchA = this.touchWithIdentifier(this.touchIdentifiers[0]);
                touchB = this.touchWithIdentifier(this.touchIdentifiers[1]);
                dx = touchA.screenX - touchB.screenX;
                dy = touchA.screenY - touchB.screenY;
                result.set(dx, dy);
            }
        };

        RotationGestureRecognizer.prototype.angleForSlope = function (slope) {
            var radians = Math.atan2(slope[1], slope[0]);

            return radians * Angle.RADIANS_TO_DEGREES;
        };

        /**
         *
         * @param event
         */
        RotationGestureRecognizer.prototype.touchStart = function (event) {
            var touchesDown = event.changedTouches;

            if (this.touchIdentifiers.length < 2) {
                for (var i = 0; i < touchesDown.length && this.touchIdentifiers.length < 2; i++) {
                    this.touchIdentifiers.push(touchesDown.item(i).identifier);
                }

                if (this.touchIdentifiers.length == 2) {
                    this.touchSlope(this.beginSlope);
                    this.rotationOffset = this.rotation;
                }
            }
        };

        /**
         *
         * @param event
         */
        RotationGestureRecognizer.prototype.touchMove = function (event) {
            var angle, beginAngle;

            if (this.touchIdentifiers.length == 2) {
                this.touchSlope(this.slope);
                angle = this.angleForSlope(this.slope);
                beginAngle = this.angleForSlope(this.beginSlope);
                this.rotation = this.rotationOffset + (angle - beginAngle);
                this.rotation = Angle.normalizedDegrees(this.rotation);
            }

            if (this.state == GestureRecognizer.POSSIBLE) {
                if (this.touchIdentifiers.length == 2) {
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
        RotationGestureRecognizer.prototype.touchEnd = function (event) {
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
        RotationGestureRecognizer.prototype.touchCancel = function (event) {
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

        RotationGestureRecognizer.prototype.removeTouch = function (identifier) {
            for (var i = 0, count = this.touchIdentifiers.length; i < count; i++) {
                if (this.touchIdentifiers[i] == identifier) {
                    this.touchIdentifiers.splice(i, 1);
                    break;
                }
            }
        };

        return RotationGestureRecognizer;
    });
