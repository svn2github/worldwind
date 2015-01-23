/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports LookAtNavigator
 * @version $Id$
 */
define([
        '../geom/Angle',
        '../geom/Frustum',
        '../gesture/GestureRecognizer',
        '../util/Logger',
        '../geom/Matrix',
        '../navigate/Navigator',
        '../gesture/PanGestureRecognizer',
        '../gesture/PinchGestureRecognizer',
        '../geom/Position',
        '../gesture/RotationGestureRecognizer',
        '../geom/Vec2',
        '../util/WWMath'
    ],
    function (Angle,
              Frustum,
              GestureRecognizer,
              Logger,
              Matrix,
              Navigator,
              PanGestureRecognizer,
              PinchGestureRecognizer,
              Position,
              RotationGestureRecognizer,
              Vec2,
              WWMath) {
        "use strict";

        /**
         * Constructs a look-at navigator.
         * @alias LookAtNavigator
         * @constructor
         * @augments Navigator
         * @classdesc Represents a navigator that enables the user to pan, zoom and tilt the globe.
         */
        var LookAtNavigator = function (worldWindow) {
            Navigator.call(this, worldWindow);

            var self = this;

            /**
             * The geographic position this navigator is directed towards.
             * @type {Position}
             */
            this.lookAtPosition = new Position(30, -90, 0);

            /**
             * The distance of the eye from this navigator's look-at position.
             * @type {number}
             */
            this.range = 10e6; // TODO: Compute initial range to fit globe in viewport.

            /**
             * A gesture recognizer configured to look for touch drag gestures with any number of touches or
             * primary-mouse drag gestures, which initiates navigator panning while the gesture is occurring.
             * @type {PanGestureRecognizer}
             * @protected
             */
            this.panRecognizer = new PanGestureRecognizer(worldWindow.canvas);
            this.panRecognizer.addGestureListener(function (gestureRecognizer) {
                self.handlePan(gestureRecognizer);
            });

            /**
             * A gesture recognizer configured to look for secondary-mouse drag gestures, which initiates navigator
             * rotation while the gesture is occurring.
             * @type {PanGestureRecognizer}
             * @protected
             */
            this.secondaryPanRecognizer = new PanGestureRecognizer(worldWindow.canvas);
            this.secondaryPanRecognizer.buttons = 4; // secondary mouse button
            this.secondaryPanRecognizer.minimumNumberOfTouches = Number.MAX_VALUE; // disable touch gestures
            this.secondaryPanRecognizer.addGestureListener(function (gestureRecognizer) {
                self.handleSecondaryPan(gestureRecognizer);
            });

            /**
             * A gesture recognizer configured to look for two finger pinch gestures, which initiates navigator zooming
             * while the gesture is occurring.
             * @type {PinchGestureRecognizer}
             * @protected
             */
            this.pinchRecognizer = new PinchGestureRecognizer(worldWindow.canvas);
            this.pinchRecognizer.addGestureListener(function (gestureRecognizer) {
                self.handlePinch(gestureRecognizer);
            });

            /**
             * A gesture recognizer configured to look for two finger rotation gestures, which initiates navigator
             * rotation while the gesture is occurring.
             * @type {RotationGestureRecognizer}
             * @protected
             */
            this.rotationRecognizer = new RotationGestureRecognizer(worldWindow.canvas);
            this.rotationRecognizer.addGestureListener(function (gestureRecognizer) {
                self.handleRotation(gestureRecognizer);
            });

            // Establish the dependencies between gesture recognizers. The pan, pinch and rotate gesture may recognize
            // simultaneously with each other.
            this.panRecognizer.recognizeWith(this.pinchRecognizer);
            this.panRecognizer.recognizeWith(this.rotationRecognizer);
            this.pinchRecognizer.recognizeWith(this.panRecognizer);
            this.pinchRecognizer.recognizeWith(this.rotationRecognizer);
            this.rotationRecognizer.recognizeWith(this.panRecognizer);
            this.rotationRecognizer.recognizeWith(this.pinchRecognizer);

            // Internal. Intentionally not documented.
            this.lastPanTranslation = new Vec2(0, 0);
            this.beginHeading = 0;
            this.beginTilt = 0;
            this.beginRange = 0;

            // Register wheel event listeners on the WorldWindow's canvas.
            worldWindow.canvas.addEventListener("wheel", function (event) {
                self.handleWheelEvent(event);
            }, false);

            // Prevent the browser's default actions for touches on the WorldWindow's canvas, and prevent the context
            // menu from appearing when the WorldWindow's canvas is right-clicked.
            var preventDefaultListener = function (event) {
                event.preventDefault();
            };
            worldWindow.canvas.addEventListener("touchstart", preventDefaultListener, false);
            worldWindow.canvas.addEventListener("touchmove", preventDefaultListener, false);
            worldWindow.canvas.addEventListener("touchend", preventDefaultListener, false);
            worldWindow.canvas.addEventListener("touchcancel", preventDefaultListener, false);
            worldWindow.canvas.addEventListener("contextmenu", preventDefaultListener, false);
        };

        LookAtNavigator.prototype = Object.create(Navigator.prototype);

        /**
         * Returns the navigator state for this navigator's current settings.
         * @returns {NavigatorState} This navigator's current navigator state.
         */
        LookAtNavigator.prototype.currentState = function () {
            var modelview = Matrix.fromIdentity();

            modelview.multiplyByLookAtModelview(this.lookAtPosition, this.range, this.heading, this.tilt, this.roll,
                this.worldWindow.globe);

            return this.currentStateForModelview(modelview);
        };

        /**
         * Performs navigation changes in response to pan gestures using the primary mouse button or any number of
         * touches.
         *
         * @param gestureRecognizer The gesture recognizer that identified the gesture.
         */
        LookAtNavigator.prototype.handlePan = function (gestureRecognizer) {
            var state = gestureRecognizer.state,
                translation = gestureRecognizer.translationInElement(this.worldWindow.canvas),
                viewport = this.worldWindow.viewport,
                globe = this.worldWindow.globe,
                globeRadius = WWMath.max(globe.equatorialRadius, globe.polarRadius),
                distance,
                metersPerPixel,
                forwardPixels, sidePixels,
                forwardMeters, sideMeters,
                forwardDegrees, sideDegrees,
                sinHeading, cosHeading;

            if (state == GestureRecognizer.BEGAN) {
                this.lastPanTranslation = new Vec2(0, 0);
                this.lastPanTranslation.copy(translation);
            } else if (state == GestureRecognizer.CHANGED) {
                // Compute the current translation in screen coordinates.
                forwardPixels = translation[1] - this.lastPanTranslation[1];
                sidePixels = translation[0] - this.lastPanTranslation[0];
                this.lastPanTranslation.copy(translation);

                // Convert the translation from screen coordinates to meters. Use this navigator's range as a distance
                // metric for converting screen pixels to meters. This assumes that the gesture is intended to translate
                // a surface that is 'range' meters away form the eye point.
                distance = WWMath.max(1, this.range);
                metersPerPixel = WWMath.perspectivePixelSize(viewport, distance);
                forwardMeters = forwardPixels * metersPerPixel;
                sideMeters = -sidePixels * metersPerPixel;

                // Convert the translation from meters to arc degrees. The globe's radius provides the necessary context
                // to perform this conversion.
                forwardDegrees = (forwardMeters / globeRadius) * Angle.RADIANS_TO_DEGREES;
                sideDegrees = (sideMeters / globeRadius) * Angle.RADIANS_TO_DEGREES;

                // Apply the change in latitude and longitude to this navigator, relative to the current heading. Limit
                // the new latitude to the range (-90, 90) in order to stop the forward movement at the pole. Panning
                // over the pole requires a corresponding change in heading, which has not been implemented here in
                // favor of simplicity.
                sinHeading = Math.sin(this.heading * Angle.DEGREES_TO_RADIANS);
                cosHeading = Math.cos(this.heading * Angle.DEGREES_TO_RADIANS);
                this.lookAtPosition.latitude += forwardDegrees * cosHeading - sideDegrees * sinHeading;
                this.lookAtPosition.longitude += forwardDegrees * sinHeading + sideDegrees * cosHeading;
                this.lookAtPosition.latitude = WWMath.clamp(this.lookAtPosition.latitude, -90, 90);
                this.lookAtPosition.longitude = Angle.normalizedDegreesLongitude(this.lookAtPosition.longitude);

                // Send an event to request a redraw.
                this.sendRedrawEvent();
            }
        };

        /**
         * Performs navigation changes in response to pan gestures using the secondary mouse button.
         *
         * @param gestureRecognizer The gesture recognizer that identified the gesture.
         */
        LookAtNavigator.prototype.handleSecondaryPan = function (gestureRecognizer) {
            var state = gestureRecognizer.state,
                translation = gestureRecognizer.translationInElement(this.worldWindow.canvas),
                viewport = this.worldWindow.viewport,
                headingPixels, tiltPixels,
                headingDegrees, tiltDegrees;

            if (state == GestureRecognizer.BEGAN) {
                this.beginHeading = this.heading;
                this.beginTilt = this.tilt;
            } if (state == GestureRecognizer.CHANGED) {
                // Compute the current translation in screen coordinates.
                headingPixels = translation[0];
                tiltPixels = translation[1];

                // Convert the translation from screen coordinates to degrees. Use the viewport dimensions as a metric
                // for converting the gesture translation to a fraction of an angle.
                headingDegrees = 180 * headingPixels / viewport.width;
                tiltDegrees = 90 * tiltPixels / viewport.height;

                // Apply the change in heading and tilt to this navigator's corresponding properties. Limit the new tilt
                // to the range (0, 90) in order to prevent the navigator from achieving an upside down orientation.
                this.heading = this.beginHeading + headingDegrees;
                this.tilt = this.beginTilt + tiltDegrees;
                this.heading = Angle.normalizedDegrees(this.heading);
                this.tilt = WWMath.clamp(this.tilt, 0, 90);

                // Send an event to request a redraw.
                this.sendRedrawEvent();
            }
        };

        /**
         * Performs navigation changes in response to two finger pinch gestures.
         *
         * @param gestureRecognizer The gesture recognizer that identified the gesture.
         */
        LookAtNavigator.prototype.handlePinch = function (gestureRecognizer) {
            var state = gestureRecognizer.state,
                scale = gestureRecognizer.scale;

            if (state == GestureRecognizer.BEGAN) {
                this.beginRange = this.range;
            } else if (state == GestureRecognizer.CHANGED) {
                if (scale != 0) {
                    // Apply the change in pinch scale to this navigator's range, relative to the range when the gesture
                    // began. Limit the new range to positive values in order to prevent degenerating to a first-person
                    // navigator when range is zero.
                    this.range = this.beginRange / scale;
                    this.range = WWMath.clamp(this.range, 1, Number.MAX_VALUE);

                    // Send an event to request a redraw.
                    this.sendRedrawEvent();
                }
            }
        };

        /**
         * Performs navigation changes in response to two finger rotation gestures.
         *
         * @param gestureRecognizer The gesture recognizer that identified the gesture.
         */
        LookAtNavigator.prototype.handleRotation = function (gestureRecognizer) {
            var state = gestureRecognizer.state,
                rotation = gestureRecognizer.rotation;

            if (state == GestureRecognizer.BEGAN) {
                this.beginHeading = this.heading;
            } else if (state == GestureRecognizer.CHANGED) {
                // Apply the change in gesture rotation o this navigator's heading, relative to the heading when the
                // gesture began.
                this.heading = this.beginHeading - rotation;
                this.heading = Angle.normalizedDegrees(this.heading);

                // Send an event to request a redraw.
                this.sendRedrawEvent();
            }
        };

        /**
         * Recognizes wheel gestures indicating navigation. Upon recognizing a gesture this delegates the task of
         * responding to that gesture to one of this navigator's handleWheel* functions, and cancels the default actions
         * associated with the corresponding events.
         *
         * @param {WheelEvent} event A wheel event associated with the WorldWindow.
         */
        LookAtNavigator.prototype.handleWheelEvent = function (event) {
            var wheelDelta;

            if (event.type == "wheel") {
                // Convert the wheel delta value from its current units to screen coordinates. The default wheel unit
                // is DOM_DELTA_PIXEL.
                wheelDelta = event.deltaY;
                if (event.deltaMode == WheelEvent.DOM_DELTA_LINE) {
                    wheelDelta *= 10;
                } else if (event.deltaMode == WheelEvent.DOM_DELTA_PAGE) {
                    wheelDelta *= 100;
                }

                event.preventDefault();
                this.handleWheelZoom(wheelDelta);
            } else {
                Logger.logMessage(Logger.LEVEL_WARNING, "LookAtNavigator", "handleWheelEvent",
                    "Unrecognized event type: " + event.type);
            }
        };

        /**
         * Translates wheel zoom gestures to changes in this navigator's properties.
         */
        LookAtNavigator.prototype.handleWheelZoom = function (wheelDelta) {
            var viewport,
                distance,
                metersPerPixel,
                meters;

            // Convert the translation from screen coordinates to meters. Use this navigator's range as a distance
            // metric for converting screen pixels to meters. This assumes that the gesture is intended to translate
            // a surface that is 'range' meters away form the eye point.
            viewport = this.worldWindow.viewport;
            distance = WWMath.max(1, this.range);
            metersPerPixel = WWMath.perspectivePixelSize(viewport, distance);
            meters = 0.5 * wheelDelta * metersPerPixel;

            // Apply the change in range to this navigator's properties. Limit the new range to positive values in order
            // to prevent degenerating to a first-person navigator when range is zero.
            this.range += meters;
            this.range = WWMath.clamp(this.range, 1, Number.MAX_VALUE);

            // Send an event to request a redraw.
            this.sendRedrawEvent();
        };

        /**
         * Sends a redraw event to this navigator's world window.
         */
        LookAtNavigator.prototype.sendRedrawEvent = function () {
            var e = document.createEvent('Event');
            e.initEvent(WorldWind.REDRAW_EVENT_TYPE, true, true);
            this.worldWindow.canvas.dispatchEvent(e);
        };

        return LookAtNavigator;
    });