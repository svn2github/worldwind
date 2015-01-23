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
             * The listeners associated with this gesture recognizer. Applications must not modify this object.
             * @type {Array}
             * @protected
             */
            this.listeners = [];

            /**
             * The gesture recognizers that can recognize simultaneously with this gesture. Applications must not modify
             * this object.
             * @type {Array}
             * @protected
             */
            this.recognizeWithList = [];

            /**
             * The gesture recognizers this gesture depends on either recognizing or failing in order to interpret
             * gesture events. Applications must not modify this object.
             * @type {Array}
             * @protected
             */
            this.dependancies = [];

            /**
             * The gesture recognizers that are dependent on this gesture either recognizing or failing in order to
             * interpret gesture events. Applications must not modify this object.
             * @type {Array}
             * @protected
             */
            this.dependants = [];

            /**
             *
             * @type {boolean}
             */
            this.pendingState = -1;

            /**
             * Applications must not modify this object.
             * @type {number}
             * @protected
             */
            this.buttonMask = 0;

            /**
             * Applications must not modify this object.
             * @type {Array}
             * @protected
             */
            this.touches = [];

            /**
             * The gesture's location relative to the window's viewport. For mouse gestures this indicates the cursor's
             * location. For touch gestures this indicates the touch centroid's location. Applications must not modify
             * this object.
             * @type {number}
             * @protected
             */
            this.clientLocation = new Vec2(0, 0);

            /**
             * The gesture's starting location relative to the window's viewport. For mouse gestures this indicates the
             * location of the first button press. For touch gestures this indicates the location of the first touch.
             * Applications must not modify this object.
             * @type {Vec2}
             * @protected
             */
            this.clientStartLocation = new Vec2(0, 0);

            /**
             * Applications must not modify this object.
             * @type {Vec2}
             * @protected
             */
            this.touchCentroidShift = new Vec2(0, 0);

            GestureRecognizer.registerMouseEventListeners(this, target);
            GestureRecognizer.registerTouchEventListeners(this, target);
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
        GestureRecognizer.RECOGNIZED = "recognized";

        /**
         * Applications must not modify this object.
         * @type {Array}
         * @protected
         */
        GestureRecognizer.recognizedGestures = [];

        /**
         * Applications must not modify this object.
         * @type {Array}
         * @protected
         */
        GestureRecognizer.listenerStates = [GestureRecognizer.BEGAN, GestureRecognizer.CHANGED,
            GestureRecognizer.ENDED, GestureRecognizer.RECOGNIZED];

        /**
         * Applications must not modify this object.
         * @type {Array}
         * @protected
         */
        GestureRecognizer.dependantStates = [GestureRecognizer.BEGAN, GestureRecognizer.FAILED,
            GestureRecognizer.RECOGNIZED];

        /**
         * Applications must not modify this object.
         * @type {Array}
         * @protected
         */
        GestureRecognizer.terminalStates = [GestureRecognizer.ENDED, GestureRecognizer.CANCELLED,
            GestureRecognizer.FAILED, GestureRecognizer.RECOGNIZED];

        //noinspection JSUnusedGlobalSymbols
        /**
         * @param element
         * @returns {Vec2}
         */
        GestureRecognizer.prototype.locationInElement = function (element) {
            var x = this.clientLocation[0],
                y = this.clientLocation[1],
                clientRect;

            if (element) {
                clientRect = element.getBoundingClientRect();
                return new Vec2(x - clientRect.left, y - clientRect.top);
            } else {
                return new Vec2(x, y);
            }
        };

        /**
         *
         * @returns {Number}
         */
        GestureRecognizer.prototype.touchCount = function () {
            return this.touches.length;
        };

        /**
         *
         * @param index
         * @param element
         * @returns {Vec2}
         */
        GestureRecognizer.prototype.touchLocationInElement = function (index, element) {
            if (index < 0 || index >= this.touches.length) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "GestureRecognizer", "touchLocationInElement",
                        "indexOutOfRange"));
            }

            var entry = this.touches[index],
                x = entry.clientLocation[0],
                y = entry.clientLocation[1],
                clientRect;

            if (element) {
                clientRect = element.getBoundingClientRect();
                return new Vec2(x - clientRect.left, y - clientRect.top);
            } else {
                return new Vec2(x, y);
            }
        };

        /**
         *
         * @param listener
         */
        GestureRecognizer.prototype.addGestureListener = function (listener) {
            if (!listener) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "GestureRecognizer", "addGestureListener",
                        "The specified listener is null or undefined."));
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
                    Logger.logMessage(Logger.LEVEL_SEVERE, "GestureRecognizer", "removeGestureListener",
                        "The specified listener is null or undefined."));
            }

            var index = this.listeners.indexOf(listener);
            if (index != -1) {
                this.listeners.splice(index, 1);
            }
        };

        //noinspection JSUnusedLocalSymbols
        /**
         * @param newState
         * @protected
         */
        GestureRecognizer.prototype.notifyGestureListeners = function (newState) {
            for (var i = 0, count = this.listeners.length; i < count; i++) {
                var entry = this.listeners[i];
                entry.call(entry, this);
            }
        };

        /**
         *
         * @param gestureRecognizer
         */
        GestureRecognizer.prototype.recognizeWith = function (gestureRecognizer) {
            if (!gestureRecognizer) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "GestureRecognizer", "recognizeWith",
                        "The specified gesture recognizer is null or undefined"));
            }

            this.recognizeWithList.push(gestureRecognizer);
        };

        /**
         *
         * @param gestureRecognizer
         * @returns {boolean}
         */
        GestureRecognizer.prototype.canRecognizeWith = function (gestureRecognizer) {
            var index = this.recognizeWithList.indexOf(gestureRecognizer);
            return index != -1;
        };

        /**
         *
         * @param gestureRecognizer
         */
        GestureRecognizer.prototype.requireFailure = function (gestureRecognizer) {
            if (!gestureRecognizer) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "GestureRecognizer", "requireFailure",
                        "The specified gesture recognizer is null or undefined"));
            }

            // Keep track of the dependancy relationships between gesture recognizers.
            this.dependancies.push(gestureRecognizer);
            gestureRecognizer.dependants.push(this);
        };

        /**
         * @param newState
         * @protected
         */
        GestureRecognizer.prototype.notifyDependants = function (newState) {
            for (var i = 0, count = this.dependants.length; i < count; i++) {
                var entry = this.dependants[i];

                if (newState == GestureRecognizer.RECOGNIZED || newState == GestureRecognizer.BEGAN) {
                    entry.transitionToState(GestureRecognizer.FAILED);
                } else if (newState == GestureRecognizer.FAILED) {
                    if (entry.pendingState != -1) {
                        entry.transitionToState(entry.pendingState);
                        entry.pendingState = -1;
                    }
                }
            }
        };

        /**
         *
         * @param newState
         * @protected
         */
        GestureRecognizer.prototype.transitionToState = function (newState) {
            if (!this.willTransitionToState(newState)) {
                return; // gestures may be prevented from transitioning to the began state
            }

            this.state = newState;

            this.didTransitionToState(newState);
        };

        /**
         *
         * @param newState
         * @returns {boolean}
         * @protected
         */
        GestureRecognizer.prototype.willTransitionToState = function (newState) {
            var recognized = GestureRecognizer.recognizedGestures,
                i, count;

            if (newState == GestureRecognizer.RECOGNIZED || newState == GestureRecognizer.BEGAN) {
                for (i = 0, count = recognized.length; i < count; i++) {
                    if (!recognized[i].canRecognizeWith(this)) {
                        return false; // unable to recognize simultaneously with currently recognized gesture
                    }
                }

                for (i = 0, count = this.dependancies.length; i < count; i++) {
                    if (this.dependancies[i].state != GestureRecognizer.FAILED) {
                        this.pendingState = newState;
                        return false; // waiting for other gesture to fail
                    }
                }
            }

            return true;
        };

        /**
         *
         * @param newState
         * @protected
         */
        GestureRecognizer.prototype.didTransitionToState = function (newState) {
            // Keep track of the continuous gestures that are currently in a recognized state.
            var recognized = GestureRecognizer.recognizedGestures,
                index = recognized.indexOf(this);
            if (newState == GestureRecognizer.BEGAN) {
                if (index == -1) {
                    recognized.push(this);
                }
            } else if (newState == GestureRecognizer.ENDED || newState == GestureRecognizer.CANCELLED) {
                if (index != -1) {
                    recognized.splice(index, 1);
                }
            }

            // Notify listeners of the state transition when the new state is began, changed, ended or recognized.
            var notifyListeners = GestureRecognizer.listenerStates.indexOf(newState) != -1;
            if (notifyListeners) {
                this.notifyGestureListeners(newState);
            }

            // Notify dependants of the state transition when the new state is began or recognized.
            var notifyDependants = GestureRecognizer.dependantStates.indexOf(newState) != -1;
            if (notifyDependants) {
                this.notifyDependants(newState);
            }
        };

        /**
         * @protected
         */
        GestureRecognizer.prototype.reset = function () {
            this.pendingState = -1;
            this.buttonMask = 0;
            this.touches = [];
            this.clientLocation.set(0, 0);
            this.clientStartLocation.set(0, 0);
            this.touchCentroidShift.set(0, 0);
        };

        /**
         *
         * @param recognizer
         * @protected
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
                recognizer.didHandleMouseEvent(event);
            };
            window.addEventListener("mousedown", eventListener, false);
            window.addEventListener("mousemove", eventListener, false);
            window.addEventListener("mouseup", eventListener, false);
        };

        /**
         *
         * @param event
         * @protected
         */
        GestureRecognizer.prototype.handleMouseEvent = function (event) {
            var buttonBit = (1 << event.button);

            if (!this.enabled) {
                return;
            }

            if (this.touches.length > 0) {
                return; // ignore mouse events when touches are active
            }

            if (event.type == "mousedown") {
                if ((this.buttonMask & buttonBit) == 0 && this.target == event.target) {
                    this.buttonMask |= buttonBit;
                    this.mouseDown(event);
                }
            } else if (event.type == "mousemove") {
                if (this.buttonMask != 0) {
                    this.mouseMove(event);
                }
            } else if (event.type == "mouseup") {
                if ((this.buttonMask & buttonBit) != 0) {
                    this.buttonMask &= ~buttonBit;
                    this.mouseUp(event);
                }
            } else {
                Logger.logMessage(Logger.LEVEL_WARNING, "GestureRecognizer", "handleMouseEvent",
                    "Unrecognized event type: " + event.type);
            }
        };

        //noinspection JSUnusedLocalSymbols
        /**
         *
         * @param event
         * @protected
         */
        GestureRecognizer.prototype.didHandleMouseEvent = function (event) {
            if (!this.enabled) {
                return;
            }

            if (this.touches.length > 0) {
                return; // ignore mouse events when touches are active
            }

            // Reset the gesture and transition to the possible state when the all mouse buttons are up and the
            // gesture is in a terminal state: recognized/ended, cancelled, or failed.
            var inTerminalState = GestureRecognizer.terminalStates.indexOf(this.state) != -1;
            if (inTerminalState && this.buttonMask == 0) {
                this.reset();
                this.transitionToState(GestureRecognizer.POSSIBLE);
            }
        };

        /**
         *
         * @param event
         * @protected
         */
        GestureRecognizer.prototype.mouseDown = function (event) {
            var buttonBit = (1 << event.button);
            if (buttonBit == this.buttonMask) { // first button down
                this.clientLocation.set(event.clientX, event.clientY);
                this.clientStartLocation.set(event.clientX, event.clientY);
            }
        };

        /**
         *
         * @param event
         * @protected
         */
        GestureRecognizer.prototype.mouseMove = function (event) {
            this.clientLocation.set(event.clientX, event.clientY);
        };

        /**
         *
         * @param event
         * @protected
         */
        GestureRecognizer.prototype.mouseUp = function (event) {
        };

        /**
         *
         * @param recognizer
         * @protected
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
                recognizer.didHandleTouchEvent(event);
            };
            recognizer.target.addEventListener("touchstart", eventListener, false);
            recognizer.target.addEventListener("touchmove", eventListener, false);
            recognizer.target.addEventListener("touchend", eventListener, false);
            recognizer.target.addEventListener("touchcancel", eventListener, false);
        };

        /**
         *
         * @param event
         * @protected
         */
        GestureRecognizer.prototype.handleTouchEvent = function (event) {
            if (!this.enabled) {
                return;
            }

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

        //noinspection JSUnusedLocalSymbols
        /**
         *
         * @param event
         * @protected
         */
        GestureRecognizer.prototype.didHandleTouchEvent = function (event) {
            if (!this.enabled) {
                return;
            }

            // Reset the gesture and transition to the possible state when the touches have ended/cancelled and the
            // gesture is in a terminal state: recognized/ended, cancelled, or failed.
            var inTerminalState = GestureRecognizer.terminalStates.indexOf(this.state) != -1;
            if (inTerminalState && this.touchCount() == 0) {
                this.reset();
                this.transitionToState(GestureRecognizer.POSSIBLE);
            }
        };

        /**
         *
         * @param event
         * @protected
         */
        GestureRecognizer.prototype.touchStart = function (event) {
            // Append touch list entries for touches that started.
            for (var i = 0, count = event.changedTouches.length; i < count; i++) {
                var touch = event.changedTouches.item(i),
                    entry = {
                        identifier: touch.identifier,
                        clientLocation: new Vec2(touch.clientX, touch.clientY),
                        clientStartLocation: new Vec2(touch.clientX, touch.clientY)
                    };
                this.touches.push(entry);
            }

            // Update the location and centroid shift to account for touches that started. When the first touch starts
            // the centroid shift is zero. When subsequent touches start the centroid shift is incremented by the
            // difference between the previous centroid and the current centroid.
            if (event.targetTouches.length == event.changedTouches.length) {
                this.touchCentroid(this.clientLocation);
                this.touchCentroidShift.set(0, 0);
                this.clientStartLocation.copy(this.clientLocation);
            } else {
                this.touchCentroidShift.add(this.clientLocation);
                this.touchCentroid(this.clientLocation);
                this.touchCentroidShift.subtract(this.clientLocation);
            }
        };

        /**
         *
         * @param event
         * @protected
         */
        GestureRecognizer.prototype.touchMove = function (event) {
            // Update the touch list entries for touches that moved.
            for (var i = 0, count = event.changedTouches.length; i < count; i++) {
                var touch = event.changedTouches.item(i),
                    index = this.indexOfTouch(touch.identifier),
                    entry;
                if (index != -1) {
                    entry = this.touches[index];
                    entry.clientLocation.set(touch.clientX, touch.clientY);
                }
            }

            // Update the touch centroid to account for touches that moved.
            this.touchCentroid(this.clientLocation);
        };

        /**
         *
         * @param event
         * @protected
         */
        GestureRecognizer.prototype.touchEnd = function (event) {
            // Remove touch list entries for touches that ended.
            this.touchesEndOrCancel(event);
        };

        /**
         *
         * @param event
         * @protected
         */
        GestureRecognizer.prototype.touchCancel = function (event) {
            // Remove touch list entries for cancelled touches.
            this.touchesEndOrCancel(event);
        };

        /**
         *
         * @param event
         * @protected
         */
        GestureRecognizer.prototype.touchesEndOrCancel = function (event) {
            // Remove touch list entries for ended or cancelled touches.
            for (var i = 0, count = event.changedTouches.length; i < count; i++) {
                var touch = event.changedTouches.item(i).identifier,
                    index = this.indexOfTouch(touch);
                if (index != -1) {
                    this.touches.splice(index, 1);
                }
            }

            // Update the touch centroid to account for ended or cancelled touches. When the last touch ends the
            // centroid shift is zero. When subsequent touches end the centroid shift is incremented by the difference
            // between the previous centroid and the current centroid.
            if (event.targetTouches.length == 0) {
                this.touchCentroid(this.clientLocation);
                this.touchCentroidShift.set(0, 0);
            } else {
                this.touchCentroidShift.add(this.clientLocation);
                this.touchCentroid(this.clientLocation);
                this.touchCentroidShift.subtract(this.clientLocation);
            }
        };

        /**
         *
         * @param identifier
         * @returns {number}
         * @protected
         */
        GestureRecognizer.prototype.indexOfTouch = function (identifier) {
            for (var i = 0, count = this.touches.length; i < count; i++) {
                if (this.touches[i].identifier == identifier) {
                    return i;
                }
            }

            return -1;
        };

        /**
         *
         * @protected
         */
        GestureRecognizer.prototype.touchCentroid = function (result) {
            result[0] = 0;
            result[1] = 0;

            for (var i = 0, count = this.touches.length; i < count; i++) {
                var entry = this.touches[i];
                result[0] += entry.clientLocation[0] / count;
                result[1] += entry.clientLocation[1] / count;
            }
        };

        return GestureRecognizer;
    });
