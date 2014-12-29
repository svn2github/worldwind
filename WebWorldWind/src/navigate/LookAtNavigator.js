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
        '../util/Logger',
        '../geom/Matrix',
        '../navigate/Navigator',
        '../geom/Position',
        '../geom/Vec2',
        '../util/WWMath'
    ],
    function (Angle,
              Frustum,
              Logger,
              Matrix,
              Navigator,
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

            // Internal. Intentionally not documented.
            this.mouseButton = -1;

            // Internal. Intentionally not documented.
            this.mousePoint = new Vec2(0, 0);

            // Internal. Intentionally not documented.
            this.mouseDelta = new Vec2(0, 0);

            // Internal. Intentionally not documented.
            this.wheelDelta = 0;

            // Register mouse event listeners on the global window object. Though this navigator ignores mouse gestures
            // initiated outside of the WorldWindow's canvas, listening on the global window enables this navigator to
            // track mouse movement and button releases that occur outside of the canvas.
            var self = this;
            var mouseEventListener = function (event) {
                self.handleMouseEvent(event);
            };
            window.addEventListener("mousedown", mouseEventListener, false);
            window.addEventListener("mouseup", mouseEventListener, false);
            window.addEventListener("mousemove", mouseEventListener, false);

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
         * Recognizes mouse gestures initiated on the WorldWindow's canvas. Upon recognizing a gesture this delegates
         * the task of responding to that gesture to one of this navigator's handleMouse* functions, and cancels the
         * default actions associated with the corresponding events.
         *
         * @param {MouseEvent} event A mouse event associated with the WorldWindow.
         */
        LookAtNavigator.prototype.handleMouseEvent = function (event) {
            if (event.type == "mousedown") {
                if (this.mouseButton < 0 && event.target == this.worldWindow.canvas) { // mouse pressed in WorldWindow canvas
                    this.mouseButton = event.button;
                    this.mousePoint.set(event.screenX, event.screenY);
                    this.mouseDelta.set(0, 0);
                    event.preventDefault();
                }
            } else if (event.type == "mouseup") {
                if (this.mouseButton == event.button) {
                    this.mouseButton = -1;
                    event.preventDefault();
                }
            } else if (event.type == "mousemove") {
                if (this.mouseButton >= 0) {
                    this.mouseDelta.set(event.screenX - this.mousePoint[0], event.screenY - this.mousePoint[1]);
                    this.mousePoint.set(event.screenX, event.screenY);
                    event.preventDefault();

                    if (this.mouseButton == 0) { // primary button is down
                        this.handleMousePan();
                    } else if (this.mouseButton == 1) { // auxiliary button is down
                        this.handleMouseZoom();
                    } else if (this.mouseButton == 2) { // secondary button is down
                        this.handleMouseRotate();
                    }
                }
            } else {
                Logger.logMessage(Logger.LEVEL_WARNING, "LookAtNavigator", "handleMouseEvent",
                    "Unrecognized event type: " + event.type);
            }
        };

        /**
         * Translates mouse pan gestures to changes in this navigator's properties.
         */
        LookAtNavigator.prototype.handleMousePan = function () {
            var viewport,
                distance,
                globe,
                globeRadius,
                metersPerPixel,
                forwardMeters,
                forwardDegrees,
                sideMeters,
                sideDegrees,
                sinHeading,
                cosHeading,
                latDegrees,
                lonDegrees;

            // Convert the translation from screen coordinates to meters. Use this navigator's range as a distance
            // metric for converting to meters. This assumes that the gesture is intended for an object that is 'range'
            // meters away form the eye position.
            viewport = this.worldWindow.viewport;
            distance = WWMath.max(1, this.range);
            metersPerPixel = WWMath.perspectivePixelSize(viewport, distance);
            forwardMeters = this.mouseDelta[1] * metersPerPixel;
            sideMeters = -this.mouseDelta[0] * metersPerPixel;

            // Convert the translation from meters to arc degrees. The globe's radius provides the necessary context to
            // perform this conversion.
            globe = this.worldWindow.globe;
            globeRadius = WWMath.max(globe.equatorialRadius, globe.polarRadius);
            forwardDegrees = (forwardMeters / globeRadius) * Angle.RADIANS_TO_DEGREES;
            sideDegrees = (sideMeters / globeRadius) * Angle.RADIANS_TO_DEGREES;

            // Convert the translation from arc degrees to change in latitude and longitude relative to the current
            // heading. The resultant translation in latitude and longitude is defined in the equirectangular coordinate
            // system.
            sinHeading = Math.sin(this.heading * Angle.DEGREES_TO_RADIANS);
            cosHeading = Math.cos(this.heading * Angle.DEGREES_TO_RADIANS);
            latDegrees = forwardDegrees * cosHeading - sideDegrees * sinHeading;
            lonDegrees = forwardDegrees * sinHeading + sideDegrees * cosHeading;

            // Apply the change in latitude and longitude to this navigator's properties. Limit the new latitude to the
            // range (-90, 90) in order to stop the forward movement at the pole. Panning over the pole requires a
            // corresponding change in heading, which has not been implemented here in favor of simplicity.
            this.lookAtPosition.latitude += latDegrees;
            this.lookAtPosition.longitude += lonDegrees;
            this.lookAtPosition.latitude = WWMath.clamp(this.lookAtPosition.latitude, -90, 90);
            this.lookAtPosition.longitude = Angle.normalizedDegreesLongitude(this.lookAtPosition.longitude);

            // Send an event to request a redraw.
            var e = document.createEvent('Event');
            e.initEvent(WorldWind.REDRAW_EVENT_TYPE, true, true);
            this.worldWindow.canvas.dispatchEvent(e);
        };

        /**
         * Translates mouse rotation gestures to changes in this navigator's properties.
         */
        LookAtNavigator.prototype.handleMouseRotate = function () {
            var viewport,
                headingDegrees,
                tiltDegrees;

            // Convert the translation from screen coordinates to degrees. Use the viewport dimensions as a metric for
            // converting the gesture translation to a fraction of an angle.
            viewport = this.worldWindow.viewport;
            headingDegrees = 180 * this.mouseDelta[0] / viewport.width;
            tiltDegrees = 90 * this.mouseDelta[1] / viewport.height;

            // Apply the change in heading and tilt to this navigator's corresponding properties. Limit the new tilt to
            // the range (0, 90) in order to prevent the navigator from achieving an upside down orientation.
            this.heading += headingDegrees;
            this.tilt += tiltDegrees;
            this.heading = Angle.normalizedDegreesLongitude(this.heading);// TODO: normalizedDegrees
            this.tilt = WWMath.clamp(this.tilt, 0, 90);

            // Send an event to request a redraw.
            this.worldWindow.canvas.dispatchEvent(new CustomEvent(WorldWind.REDRAW_EVENT_TYPE));
        };

        /**
         * Translates mouse zoom gestures to changes in this navigator's properties.
         */
        LookAtNavigator.prototype.handleMouseZoom = function () {
            var viewport,
                distance,
                metersPerPixel,
                meters;

            // Convert the translation from screen coordinates to meters. Use this navigator's range as a distance
            // metric for converting to meters. This assumes that the gesture is intended for an object that is 'range'
            // meters away form the eye position.
            viewport = this.worldWindow.viewport;
            distance = WWMath.max(1, this.range);
            metersPerPixel = WWMath.perspectivePixelSize(viewport, distance);
            meters = 2.0 * this.mouseDelta[1] * metersPerPixel;

            // Apply the change in range to this navigator's properties. Limit the new range to positive values in order
            // to prevent degenerating to a first-person navigator when range is zero.
            this.range += meters;
            this.range = WWMath.clamp(this.range, 1, Number.MAX_VALUE);

            // Send an event to request a redraw.
            this.worldWindow.canvas.dispatchEvent(new CustomEvent(WorldWind.REDRAW_EVENT_TYPE));
        };

        /**
         * Recognizes wheel gestures initiated on the WorldWindow's canvas. Upon recognizing a gesture this delegates
         * the task of responding to that gesture to one of this navigator's handleWheel* functions, and cancels the
         * default actions associated with the corresponding events.
         *
         * @param {WheelEvent} event A wheel event associated with the WorldWindow.
         */
        LookAtNavigator.prototype.handleWheelEvent = function (event) {
            if (event.type == "wheel") {
                // Convert the wheel delta value from its current units to screen coordinates. The default wheel unit
                // is DOM_DELTA_PIXEL.
                this.wheelDelta = event.deltaY;
                if (event.deltaMode == WheelEvent.DOM_DELTA_LINE) {
                    this.wheelDelta *= 10;
                } else if (event.deltaMode == WheelEvent.DOM_DELTA_PAGE) {
                    this.wheelDelta *= 100;
                }

                event.preventDefault();
                this.handleWheelZoom();
            } else {
                Logger.logMessage(Logger.LEVEL_WARNING, "LookAtNavigator", "handleWheelEvent",
                    "Unrecognized event type: " + event.type);
            }
        };

        /**
         * Translates wheel zoom gestures to changes in this navigator's properties.
         */
        LookAtNavigator.prototype.handleWheelZoom = function () {
            var viewport,
                distance,
                metersPerPixel,
                meters;

            // Convert the translation from screen coordinates to meters. Use this navigator's range as a distance
            // metric for converting to meters. This assumes that the gesture is intended for an object that is 'range'
            // meters away form the eye position.
            viewport = this.worldWindow.viewport;
            distance = WWMath.max(1, this.range);
            metersPerPixel = WWMath.perspectivePixelSize(viewport, distance);
            meters = 0.5 * this.wheelDelta * metersPerPixel;

            // Apply the change in range to this navigator's properties. Limit the new range to positive values in order
            // to prevent degenerating to a first-person navigator when range is zero.
            this.range += meters;
            this.range = WWMath.clamp(this.range, 1, Number.MAX_VALUE);

            // Send an event to request a redraw.
            this.worldWindow.canvas.dispatchEvent(new CustomEvent(WorldWind.REDRAW_EVENT_TYPE));
        };

        return LookAtNavigator;
    });