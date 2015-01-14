/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports PanGestureRecognizer
 * @version $Id$
 */
define([
        '../navigate/GestureRecognizer',
        '../util/Logger',
        '../geom/Vec2'
    ],
    function (GestureRecognizer,
              Logger,
              Vec2) {
        "use strict";

        /**
         * Constructs a pan gesture recognizer.
         * @alias PanGestureRecognizer
         * @constructor
         * @classdesc A concrete gesture recognizer subclass that looks for mouse panning or touch panning gestures.
         */
        var PanGestureRecognizer = function (target) {
            GestureRecognizer.call(this, target);

            /**
             *
             * @type {number}
             */
            this.buttons = 1;

            /**
             *
             * @type {number}
             */
            this.minimumNumberOfTouches = 1;

            /**
             *
             * @type {Number}
             */
            this.maximumNumberOfTouches = Number.MAX_VALUE;

            /**
             *
             * @type {Vec2}
             */
            this.translation = new Vec2(0, 0);

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
            this.beginPoint = new Vec2(0, 0);
        };

        PanGestureRecognizer.prototype = Object.create(GestureRecognizer.prototype);

        PanGestureRecognizer.prototype.reset = function () {
            GestureRecognizer.prototype.reset.call(this);

            this.translation.set(0, 0);
            this.beginPoint.set(0, 0);
        };

        /**
         *
         * @param event
         * @returns {boolean}
         */
        PanGestureRecognizer.prototype.shouldBeginWithMouseEvent = function (event) {
            return this.buttons == this.activeButtons;
        };

        /**
         *
         * @param event
         */
        PanGestureRecognizer.prototype.mouseDown = function (event) {
            var buttonBit = (1 << event.button);

            if (this.activeButtons == buttonBit) {
                this.beginPoint.set(event.screenX, event.screenY);
            }
        };

        /**
         *
         * @param event
         */
        PanGestureRecognizer.prototype.mouseMove = function (event) {
            this.translation.set(event.screenX, event.screenY);
            this.translation.subtract(this.beginPoint);

            if (this.state == GestureRecognizer.POSSIBLE) {
                if (this.translation.magnitude() > this.threshold) {
                    if (this.shouldBeginWithMouseEvent(event)) {
                        this.transitionToState(GestureRecognizer.BEGAN, event);
                    } else {
                        this.transitionToState(GestureRecognizer.FAILED, event);
                    }
                }
            } else if (this.state == GestureRecognizer.BEGAN || this.state == GestureRecognizer.CHANGED) {
                this.transitionToState(GestureRecognizer.CHANGED, event);
            }
        };

        /**
         *
         * @param event
         */
        PanGestureRecognizer.prototype.mouseUp = function (event) {
            if (this.activeButtons == 0) {
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
         * @returns {boolean}
         */
        PanGestureRecognizer.prototype.shouldBeginWithTouchEvent = function (event) {
            return this.activeTouches.length >= this.minimumNumberOfTouches
                && this.activeTouches.length <= this.maximumNumberOfTouches;
        };

        /**
         *
         * @param event
         */
        PanGestureRecognizer.prototype.touchStart = function (event) {
            if (event.targetTouches.length == event.changedTouches.length) {
                this.beginPoint.copy(this.touchCentroid);
            }
        };

        /**
         *
         * @param event
         */
        PanGestureRecognizer.prototype.touchMove = function (event) {
            this.translation.copy(this.touchCentroid);
            this.translation.add(this.touchCentroidOffset);
            this.translation.subtract(this.beginPoint);

            if (this.state == GestureRecognizer.POSSIBLE) {
                if (this.translation.magnitude() > this.threshold) {
                    if (this.shouldBeginWithTouchEvent(event)) {
                        this.transitionToState(GestureRecognizer.BEGAN, event);
                    } else {
                        this.transitionToState(GestureRecognizer.FAILED, event);
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
        PanGestureRecognizer.prototype.touchEnd = function (event) {
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
        PanGestureRecognizer.prototype.touchCancel = function (event) {
            if (event.targetTouches.length == 0) {
                if (this.state == GestureRecognizer.BEGAN || this.state == GestureRecognizer.CHANGED) {
                    this.transitionToState(GestureRecognizer.CANCELLED, event);
                    this.reset();
                } else if (this.state == GestureRecognizer.FAILED) {
                    this.reset();
                }
            }
        };

        return PanGestureRecognizer;
    });
