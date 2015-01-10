/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports TouchPanGestureRecognizer
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
            GestureRecognizer.registerMouseEventListeners(this, target);
            GestureRecognizer.registerTouchEventListeners(this, target);

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
             * @type {Vec2}
             */
            this.previousTranslation = new Vec2(0, 0);

            /**
             *
             * @type {Vec2}
             */
            this.startPoint = new Vec2(0, 0);
        };

        PanGestureRecognizer.prototype = Object.create(GestureRecognizer.prototype);

        PanGestureRecognizer.prototype.reset = function () {
            GestureRecognizer.prototype.reset.call(this);

            this.translation.set(0, 0);
            this.previousTranslation.set(0, 0);
            this.startPoint.set(0, 0);
        };

        /**
         *
         * @param event
         */
        PanGestureRecognizer.prototype.mouseDown = function (event) {
            var buttonBit = (1 << event.button);

            if (this.mouseButtons == buttonBit) {
                this.startPoint.set(event.screenX, event.screenY);
            }
        };

        /**
         *
         * @param event
         */
        PanGestureRecognizer.prototype.mouseMove = function (event) {
            var threshold = 5;

            this.previousTranslation.copy(this.translation);
            this.translation.set(event.screenX, event.screenY);
            this.translation.subtract(this.startPoint);

            if (this.state == GestureRecognizer.POSSIBLE) {
                if (this.translation.magnitude() > threshold) {
                    if (this.buttons == this.mouseButtons) {
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
            if (this.mouseButtons == 0) {
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
        PanGestureRecognizer.prototype.touchStart = function (event) {
            if (event.targetTouches.length == event.changedTouches.length) {
                this.startPoint.copy(this.touchCentroid);
            }
        };

        /**
         *
         * @param event
         */
        PanGestureRecognizer.prototype.touchMove = function (event) {
            var threshold = 5;

            this.previousTranslation.copy(this.translation);
            this.translation.copy(this.touchCentroid);
            this.translation.add(this.touchCentroidOffset);
            this.translation.subtract(this.startPoint);

            if (this.state == GestureRecognizer.POSSIBLE) {
                if (this.translation.magnitude() > threshold) {
                    if (this.minimumNumberOfTouches <= event.targetTouches.length &&
                        this.maximumNumberOfTouches >= event.targetTouches.length) {
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
