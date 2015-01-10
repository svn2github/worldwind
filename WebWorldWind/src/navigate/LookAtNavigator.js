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
        '../navigate/GestureRecognizer',
        '../util/Logger',
        '../geom/Matrix',
        '../navigate/Navigator',
        '../navigate/PanGestureRecognizer',
        '../geom/Position',
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
              Position,
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

            var self = this;

            /**
             * A gesture recognizer configured to look for primary-mouse drag gestures or touch drag gestures and
             * initiate navigator panning while the gesture is occurring.
             * @type {PanGestureRecognizer}
             * @protected
             */
            this.panGestureRecognizer = new PanGestureRecognizer(worldWindow.canvas);
            this.panGestureRecognizer.addGestureListener(function (gestureRecognizer) {
                self.handlePan(gestureRecognizer);
            });

            /**
             * A gesture recognizer configured to look for secondary-mouse drag gestures and initiate navigator rotation
             * while the gesture is occurring.
             * @type {PanGestureRecognizer}
             * @protected
             */
            this.mouseRotationGestureRecognizer = new PanGestureRecognizer(worldWindow.canvas);
            this.mouseRotationGestureRecognizer.buttons = 4; // secondary mouse button
            this.mouseRotationGestureRecognizer.minimumNumberOfTouches = Number.MAX_VALUE; // disable touch gestures
            this.mouseRotationGestureRecognizer.addGestureListener(function (gestureRecognizer) {
                self.handleMouseRotation(gestureRecognizer);
            });

            /**
             * A gesture recognizer configured to look for auxiliary-mouse drag gestures and initiate navigator zooming
             * while the gesture is occurring.
             * @type {PanGestureRecognizer}
             */
            this.mouseZoomGestureRecognizer = new PanGestureRecognizer(worldWindow.canvas);
            this.mouseZoomGestureRecognizer.buttons = 2; // auxiliary mouse button
            this.mouseZoomGestureRecognizer.minimumNumberOfTouches = Number.MAX_VALUE; // disable touch gestures
            this.mouseZoomGestureRecognizer.addGestureListener(function (gestureRecognizer) {
                self.handleMouseZoom(gestureRecognizer);
            });

            // Register wheel event listeners on the WorldWindow's canvas.
            worldWindow.canvas.addEventListener("wheel", function (event) {
                self.handleWheelEvent(event);
            }, false);

            // Prevent the browser's default context menu from appearing when the WorldWindow's canvas is right-clicked.
            worldWindow.canvas.addEventListener("contextmenu", function (event) {
                event.preventDefault();
            }, false);
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
         * Performs navigator panning in response to the user input identified by the specified gesture recognizer.
         *
         * @param gestureRecognizer The gesture recognizer that identified the gesture.
         */
        LookAtNavigator.prototype.handlePan = function (gestureRecognizer) {
            var state = gestureRecognizer.state,
                viewport = this.worldWindow.viewport,
                globe = this.worldWindow.globe,
                globeRadius = WWMath.max(globe.equatorialRadius, globe.polarRadius),
                distance,
                metersPerPixel,
                forwardPixels, sidePixels,
                forwardMeters, sideMeters,
                forwardDegrees, sideDegrees,
                sinHeading, cosHeading;

            if (state == GestureRecognizer.CHANGED) {
                // Compute the current translation in screen coordinates.
                forwardPixels = gestureRecognizer.translation[1] - gestureRecognizer.previousTranslation[1];
                sidePixels = gestureRecognizer.translation[0] - gestureRecognizer.previousTranslation[0];

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
         * Performs navigator rotation in response to the user input identified by the specified gesture recognizer.
         *
         * @param gestureRecognizer The gesture recognizer that identified the gesture.
         */
        LookAtNavigator.prototype.handleMouseRotation = function (gestureRecognizer) {
            var state = gestureRecognizer.state,
                viewport = this.worldWindow.viewport,
                headingPixels, tiltPixels,
                headingDegrees, tiltDegrees;

            if (state == GestureRecognizer.CHANGED) {
                // Compute the current translation in screen coordinates.
                headingPixels = gestureRecognizer.translation[0] - gestureRecognizer.previousTranslation[0];
                tiltPixels = gestureRecognizer.translation[1] - gestureRecognizer.previousTranslation[1];

                // Convert the translation from screen coordinates to degrees. Use the viewport dimensions as a metric
                // for converting the gesture translation to a fraction of an angle.
                headingDegrees = 180 * headingPixels / viewport.width;
                tiltDegrees = 90 * tiltPixels / viewport.height;

                // Apply the change in heading and tilt to this navigator's corresponding properties. Limit the new tilt
                // to the range (0, 90) in order to prevent the navigator from achieving an upside down orientation.
                this.heading += headingDegrees;
                this.tilt += tiltDegrees;
                this.heading = Angle.normalizedDegreesLongitude(this.heading);// TODO: normalizedDegrees
                this.tilt = WWMath.clamp(this.tilt, 0, 90);

                // Send an event to request a redraw.
                this.sendRedrawEvent();
            }
        };

        /**
         * Performs navigator zooming in response to the user input identified by the specified gesture recognizer.
         *
         * @param gestureRecognizer The gesture recognizer that identified the gesture.
         */
        LookAtNavigator.prototype.handleMouseZoom = function (gestureRecognizer) {
            var state = gestureRecognizer.state,
                viewport = this.worldWindow.viewport,
                pixels,
                distance,
                metersPerPixel,
                meters;

            if (state == GestureRecognizer.CHANGED) {
                // Compute the current translation in screen coordinates.
                pixels = gestureRecognizer.translation[1] - gestureRecognizer.previousTranslation[1];

                // Convert the translation from screen coordinates to meters. Use this navigator's range as a distance
                // metric for converting screen pixels to meters. This assumes that the gesture is intended to translate
                // a surface that is 'range' meters away form the eye point.
                distance = WWMath.max(1, this.range);
                metersPerPixel = WWMath.perspectivePixelSize(viewport, distance);
                meters = 2.0 * pixels * metersPerPixel;

                // Apply the change in range to this navigator's properties. Limit the new range to positive values in
                // order to prevent degenerating to a first-person navigator when range is zero.
                this.range += meters;
                this.range = WWMath.clamp(this.range, 1, Number.MAX_VALUE);

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