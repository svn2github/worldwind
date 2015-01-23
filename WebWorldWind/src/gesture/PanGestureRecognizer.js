/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports PanGestureRecognizer
 * @version $Id$
 */
define([
        '../gesture/GestureRecognizer',
        '../geom/Vec2'
    ],
    function (GestureRecognizer,
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
             * The gesture's translation relative to the window's viewport. For mouse gestures this indicates the cursor
             * translation since the first button press. For touch gestures this indicates the translation of the touch
             * centroid since the first touch, adjusted to remove changes in the centroid due to touches starting or
             * ending. Applications must not modify this object.
             * @type {Vec2}
             * @protected
             */
            this.clientTranslation = new Vec2(0, 0);

            /**
             *
             * @type {number}
             * @protected
             */
            this.threshold = 10;
        };

        PanGestureRecognizer.prototype = Object.create(GestureRecognizer.prototype);

        //noinspection JSUnusedLocalSymbols
        /**
         * Returns gesture's translation relative to the coordinate system of the specified element.
         * @param element
         * @returns {Vec2}
         */
        PanGestureRecognizer.prototype.translationInElement = function (element) {
            // Currently, the element argument is intentionally unused. This argument is intended to provide a flexible
            // interface that enables this implementation to adjust the translation for a scaled or rotated coordinate
            // system.
            return this.clientTranslation;
        };

        PanGestureRecognizer.prototype.reset = function () {
            GestureRecognizer.prototype.reset.call(this);

            this.clientTranslation.set(0, 0);
        };

        /**
         *
         * @param event
         * @protected
         */
        PanGestureRecognizer.prototype.mouseDown = function (event) {
            GestureRecognizer.prototype.mouseDown.call(this, event);

            var buttonBit = (1 << event.button);
            if (buttonBit == this.buttonMask) { // first button down
                this.clientTranslation.set(0, 0);
            }
        };

        /**
         *
         * @param event
         * @protected
         */
        PanGestureRecognizer.prototype.mouseMove = function (event) {
            GestureRecognizer.prototype.mouseMove.call(this, event);

            this.clientTranslation.copy(this.clientLocation);
            this.clientTranslation.subtract(this.clientStartLocation);

            if (this.state == GestureRecognizer.POSSIBLE) {
                if (this.shouldInterpretMouse()) {
                    if (this.shouldRecognizeMouse()) {
                        this.transitionToState(GestureRecognizer.BEGAN);
                    } else {
                        this.transitionToState(GestureRecognizer.FAILED);
                    }
                }
            } else if (this.state == GestureRecognizer.BEGAN || this.state == GestureRecognizer.CHANGED) {
                this.transitionToState(GestureRecognizer.CHANGED);
            }
        };

        /**
         *
         * @param event
         * @protected
         */
        PanGestureRecognizer.prototype.mouseUp = function (event) {
            GestureRecognizer.prototype.mouseUp.call(this, event);

            if (this.buttonMask == 0) { // last button up
                if (this.state == GestureRecognizer.BEGAN || this.state == GestureRecognizer.CHANGED) {
                    this.transitionToState(GestureRecognizer.ENDED);
                }
            }
        };

        /**
         *
         * @returns {boolean}
         * @protected
         */
        PanGestureRecognizer.prototype.shouldInterpretMouse = function () {
            var distance = this.clientTranslation.magnitude();
            return distance > this.threshold;
        };

        /**
         *
         * @returns {boolean}
         * @protected
         */
        PanGestureRecognizer.prototype.shouldRecognizeMouse = function () {
            var buttonMask = this.buttonMask;
            return buttonMask != 0 && buttonMask == this.buttons;
        };

        /**
         *
         * @param event
         */
        PanGestureRecognizer.prototype.touchStart = function (event) {
            GestureRecognizer.prototype.touchStart.call(this, event);

            if (event.touches.length == event.changedTouches.length) { // first touches started
                this.clientTranslation.set(0, 0);
            }
        };

        /**
         *
         * @param event
         * @protected
         */
        PanGestureRecognizer.prototype.touchMove = function (event) {
            GestureRecognizer.prototype.touchMove.call(this, event);

            this.clientTranslation.copy(this.clientLocation);
            this.clientTranslation.subtract(this.clientStartLocation);
            this.clientTranslation.add(this.touchCentroidShift);

            if (this.state == GestureRecognizer.POSSIBLE) {
                if (this.shouldInterpretTouches()) {
                    if (this.shouldRecognizeTouches()) {
                        this.transitionToState(GestureRecognizer.BEGAN);
                    } else {
                        this.transitionToState(GestureRecognizer.FAILED);
                    }
                }
            } else if (this.state == GestureRecognizer.BEGAN || this.state == GestureRecognizer.CHANGED) {
                this.transitionToState(GestureRecognizer.CHANGED);
            }
        };

        /**
         *
         * @param event
         * @protected
         */
        PanGestureRecognizer.prototype.touchEnd = function (event) {
            GestureRecognizer.prototype.touchEnd.call(this, event);

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
        PanGestureRecognizer.prototype.touchCancel = function (event) {
            GestureRecognizer.prototype.touchCancel.call(this, event);

            if (event.targetTouches.length == 0) { // last touches cancelled
                if (this.state == GestureRecognizer.BEGAN || this.state == GestureRecognizer.CHANGED) {
                    this.transitionToState(GestureRecognizer.CANCELLED);
                }
            }
        };

        /**
         *
         * @returns {boolean}
         * @protected
         */
        PanGestureRecognizer.prototype.shouldInterpretTouches = function () {
            var distance = this.clientTranslation.magnitude();
            return distance > this.threshold;
        };

        /**
         *
         * @returns {boolean}
         * @protected
         */
        PanGestureRecognizer.prototype.shouldRecognizeTouches = function () {
            var touchCount = this.touchCount();
            return touchCount != 0
                && touchCount >= this.minimumNumberOfTouches
                && touchCount <= this.maximumNumberOfTouches
        };

        return PanGestureRecognizer;
    });
