/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports GestureRecognizer
 * @version $Id$
 */
define([
        '../error/ArgumentError',
        '../util/Logger',
        '../geom/Vec2'
    ],
    function (ArgumentError,
              Logger,
              Vec2) {
        "use strict";

        /**
         * Constructs a base gesture recognizer. This is an abstract base class and not intended to be instantiated
         * directly.
         * @alias GestureRecognizer
         * @constructor
         * @classdesc Provides an abstract base class for gesture recognizers.
         */
        var GestureRecognizer = function (target) {
            if (!target) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "GestureRecognizer", "constructor", "missingTarget"));
            }

            /**
             * @readonly
             */
            this.target = target;

            /**
             * @readonly
             */
            this.state = GestureRecognizer.POSSIBLE;

            /**
             *
             * @type {boolean}
             */
            this.enabled = true;

            /**
             *
             * @type {boolean}
             */
            this.cancelsEvents = true;

            /**
             * The listeners associated with this gesture recognizer. Applications must not modify this object.
             * @type {Array}
             * @protected
             */
            this.listeners = [];

            /**
             *
             * @type {Array}
             * @protected
             */
            this.cancelStates = [GestureRecognizer.BEGAN, GestureRecognizer.CHANGED, GestureRecognizer.ENDED,
                GestureRecognizer.RECOGNIZED];

            /**
             *
             * @type {Array}
             * @protected
             */
            this.notifyStates = [GestureRecognizer.BEGAN, GestureRecognizer.CHANGED, GestureRecognizer.ENDED,
                GestureRecognizer.CANCELLED, GestureRecognizer.RECOGNIZED];

            /**
             *
             * @type {number}
             * @protected
             */
            this.mouseButtons = 0;

            /**
             *
             * @type {Array}
             * @protected
             */
            this.touches = [];

            /**
             *
             * @type {Vec2}
             * @protected
             */
            this.touchCentroid = new Vec2(0, 0);

            /**
             *
             * @type {Vec2}
             */
            this.touchCentroidOffset = new Vec2(0, 0);
        };

        /**
         *
         * @type {string}
         */
        GestureRecognizer.POSSIBLE = "possible";

        /**
         *
         * @type {string}
         */
        GestureRecognizer.BEGAN = "began";

        /**
         *
         * @type {string}
         */
        GestureRecognizer.CHANGED = "changed";

        /**
         *
         * @type {string}
         */
        GestureRecognizer.ENDED = "ended";

        /**
         *
         * @type {string}
         */
        GestureRecognizer.CANCELLED = "cancelled";

        /**
         *
         * @type {string}
         */
        GestureRecognizer.FAILED = "failed";

        /**
         *
         * @type {string}
         */
        GestureRecognizer.RECOGNIZED = GestureRecognizer.ENDED;

        /**
         *
         * @param listener
         */
        GestureRecognizer.prototype.addGestureListener = function (listener) {
           if (!listener) {
               throw new ArgumentError(
                   Logger.logMessage(Logger.LEVEL_SEVERE, "GestureRecognizer", "addGestureListener", "missingListener"));
           }

            if (typeof listener != "function") {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "GestureRecognizer", "addGestureListener",
                        "The specified listener is not a function."));
            }

            this.listeners.push(listener);
        };

        /**
         *
         * @param listener
         */
        GestureRecognizer.prototype.removeGestureListener = function (listener) {
            if (!listener) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "GestureRecognizer", "removeGestureListener", "missingListener"));
            }

            if (typeof listener != "function") {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "GestureRecognizer", "addGestureListener",
                        "The specified listener is not a function."));
            }

            var index = this.listeners.indexOf(listener);
            if (index > -1) {
                this.listeners.splice(index, 1);
            }
        };

        /**
         *
         */
        GestureRecognizer.prototype.reset = function () {
            this.transitionToState(GestureRecognizer.POSSIBLE, null);
        };

        /**
         *
         * @param state
         * @param event
         */
        GestureRecognizer.prototype.transitionToState = function (state, event) {
            var cancel = this.cancelStates.indexOf(state) != -1,
                notify = this.notifyStates.indexOf(state) != -1;

            // Set this gesture recognizer's state property to the new state.
            this.state = state;

            // When the new state cancels its associated events and this gesture recognizer is configured to cancel
            // events, prevent the associated event's default action.
            if (cancel && this.cancelsEvents && event) {
                event.preventDefault();
            }

            // When the new state generates notifications, call the gesture listeners associated with this recognizer.
            if (notify) {
                for (var i = 0, len = this.listeners.length; i < len; i++) {
                    this.listeners[i].call(this.listeners[i], this);
                }
            }
        };

        /**
         *
         * @param recognizer
         */
        GestureRecognizer.registerMouseEventListeners = function (recognizer) {
            if (!recognizer) {
                throw new ArgumentError(
                    Logger.getMessage(Logger.LEVEL_SEVERE, "GestureRecognizer", "registerMouseEventListeners",
                        "The specified recognizer is null or undefined"));
            }

            // Register mouse event listeners on the global window object. Mouse drags started on the target do not
            // generate mouse move and mouse up events outside of the target's bounds. We listen on the window to
            // handle mouse gestures that start on the target but travel outside the target or end outside the target.
            var eventListener = function (event) {
                recognizer.handleMouseEvent(event);
            };
            window.addEventListener("mousedown", eventListener, false);
            window.addEventListener("mousemove", eventListener, false);
            window.addEventListener("mouseup", eventListener, false);
        };

        /**
         *
         * @param event
         */
        GestureRecognizer.prototype.handleMouseEvent = function (event) {
            var buttonBit = (1 << event.button);

            if (!this.enabled) {
                return;
            }

            // Ignore mouse events when one or more touches are active.
            if (this.touches.length > 0) {
                return;
            }

            if (event.type == "mousedown") {
                if ((this.mouseButtons & buttonBit) == 0 && this.target == event.target) {
                    this.mouseButtons |= buttonBit;
                    this.mouseDown(event);
                }
            } else if (event.type == "mousemove") {
                if (this.mouseButtons != 0) {
                    this.mouseMove(event);
                }
            } else if (event.type == "mouseup") {
                if ((this.mouseButtons & buttonBit) != 0) {
                    this.mouseButtons &= ~buttonBit;
                    this.mouseUp(event);
                }
            } else {
                Logger.logMessage(Logger.LEVEL_WARNING, "GestureRecognizer", "handleMouseEvent",
                    "Unrecognized event type: " + event.type);
            }
        };

        /**
         *
         * @param event
         */
        GestureRecognizer.prototype.mouseDown = function (event) {
            // Default implementation does nothing.
        };

        /**
         *
         * @param event
         */
        GestureRecognizer.prototype.mouseMove = function (event) {
            // Default implementation does nothing.
        };

        /**
         *
         * @param event
         */
        GestureRecognizer.prototype.mouseUp = function (event) {
            // Default implementation does nothing.
        };

        /**
         *
         * @param recognizer
         */
        GestureRecognizer.registerTouchEventListeners = function (recognizer) {
            if (!recognizer) {
                throw new ArgumentError(
                    Logger.getMessage(Logger.LEVEL_SEVERE, "GestureRecognizer", "registerTouchEventListeners",
                        "The specified recognizer is null or undefined"));
            }

            // Register touch event listeners on the specified target. Touches started on the target generate touch move
            // and touch end events outside of the target's bounds.
            var eventListener = function (event) {
                recognizer.handleTouchEvent(event);
            };
            recognizer.target.addEventListener("touchstart", eventListener, false);
            recognizer.target.addEventListener("touchmove", eventListener, false);
            recognizer.target.addEventListener("touchend", eventListener, false);
            recognizer.target.addEventListener("touchcancel", eventListener, false);
        };

        /**
         *
         * @param event
         */
        GestureRecognizer.prototype.handleTouchEvent = function (event) {
            if (!this.enabled) {
                return;
            }

            this.updateTouches(event);

            if (event.type == "touchstart") {
                this.touchStart(event);
            } else if (event.type == "touchmove") {
                this.touchMove(event);
            } else if (event.type == "touchend") {
                this.touchEnd(event);
            } else if (event.type == "touchcancel") {
                this.touchCancel(event);
            } else {
                Logger.logMessage(Logger.LEVEL_WARNING, "GestureRecognizer", "handleTouchEvent",
                    "Unrecognized event type: " + event.type);
            }
        };

        GestureRecognizer.prototype.updateTouches = function (event) {
            var previousCentroid = new Vec2(this.touchCentroid[0], this.touchCentroid[1]),
                targetTouches = event.targetTouches,
                numTouches = targetTouches.length,
                touch;

            this.touches = [];
            this.touchCentroid.set(0, 0);

            if (numTouches > 0) {
                for (var i = 0; i < numTouches; i++) {
                    touch = targetTouches.item(i);
                    this.touches.push(touch);
                    this.touchCentroid[0] += touch.screenX;
                    this.touchCentroid[1] += touch.screenY;
                }

                this.touchCentroid[0] /= numTouches;
                this.touchCentroid[1] /= numTouches;
            }

            // TODO: Capture the common pattern in tuochstart and touchend/touchcancel

            if (event.type == "touchstart") {
                if (event.targetTouches.length == event.changedTouches.length) { // first touch down
                    this.touchCentroidOffset.set(0, 0);
                } else { // added touches
                    this.touchCentroidOffset.add(previousCentroid);
                    this.touchCentroidOffset.subtract(this.touchCentroid);
                }
            } else if (event.type == "touchend" || event.type == "touchcancel") {
                if (event.targetTouches.length == 0) { // last touch up
                    this.touchCentroidOffset.set(0, 0);
                } else { // removed touches
                    this.touchCentroidOffset.add(previousCentroid);
                    this.touchCentroidOffset.subtract(this.touchCentroid);
                }
            }
        };

        /**
         *
         * @param event
         */
        GestureRecognizer.prototype.touchStart = function (event) {
            // Default implementation does nothing.
        };

        /**
         *
         * @param event
         */
        GestureRecognizer.prototype.touchMove = function (event) {
            // Default implementation does nothing.
        };

        /**
         *
         * @param event
         */
        GestureRecognizer.prototype.touchEnd = function (event) {
            // Default implementation does nothing.
        };

        /**
         *
         * @param event
         */
        GestureRecognizer.prototype.touchCancel = function (event) {
            // Default implementation does nothing.
        };

        return GestureRecognizer;
    });
