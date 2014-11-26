/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports Position
 * @version $Id$
 */
define([
        'src/geom/Angle',
        'src/error/ArgumentError',
        'src/geom/Location',
        'src/util/Logger',
        'src/util/WWMath'
    ],
    function (Angle,
              ArgumentError,
              Location,
              Logger,
              WWMath) {
        "use strict";

        /**
         * Constructs a position from a specified latitude and longitude in degrees and altitude in meters.
         * @alias Position
         * @constructor
         * @classdesc Represents a latitude, longitude pair.
         * @param {Number} latitude The latitude in degrees.
         * @param {Number} longitude The longitude in degrees.
         * @param {Number} altitude The altitude in meters.
         */
        var Position = function (latitude, longitude, altitude) {
            /**
             * The latitude in degrees.
             * @type {Number}
             */
            this.latitude = latitude;
            /**
             * The longitude in degrees.
             * @type {Number}
             */
            this.longitude = longitude;
            /**
             * The altitude in meters.
             * @type {Number}
             */
            this.altitude = altitude;
        };

        /**
         * A Position with latitude, longitude and altitude all 0.
         * @constant
         * @type {Location}
         */
        Position.ZERO = new Position(0, 0, 0);

        /**
         * Creates a position from angles specified in radians.
         * @param {Number} latitudeRadians The latitude in radians.
         * @param {Number} longitudeRadians The longitude in radians.
         * @param {Number} altitude The altitude in meters.
         * @returns {Position} The new position with latitude and longitude in degrees.
         */
        Position.fromRadians = function (latitudeRadians, longitudeRadians, altitude) {
            return new Position(
                latitudeRadians * Angle.RADIANS_TO_DEGREES,
                longitudeRadians * Angle.RADIANS_TO_DEGREES,
                altitude);
        };

        /**
         * Creates a new position from a specified position.
         * @param {Position} position The position to copy.
         * @returns {Position} The new position, initialized to the values of the specified position.
         * @throws {ArgumentError} If the specified position is null or undefined.
         */
        Position.fromPosition = function (position) {
            if (!position instanceof Position) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Position", "fromPosition", "missingPosition"));
            }

            return new Position(position.latitude, position.longitude, position.altitude);
        };

        /**
         * Indicates whether this position is equivalent to a specified position.
         * @param {Position} position The position to compare with this one.
         * @returns {boolean} <code>true</code> if this position is equivalent to the specified one.
         * <code>false</code> if the specified position is not equivalent, null, undefined or not a Position.
         */
        Position.prototype.equals = function (position) {
            return position instanceof Position
                && position.latitude == this.latitude
                && position.longitude == this.longitude
                && position.altitude == this.altitude;
        };

        /**
         * Compute a position along a great circle path at a specified distance between two specified positions.
         * @param {Number} amount The fraction of the path between the two positions at which to compute the new
         * position. This number should be between 0 and 1. If not, it is clamped to the nearest of those values.
         * @param {Position} position1 The starting location.
         * @param {Position} position2 The ending location.
         * @param {Position} result A Location in which to return the result.
         * @throws {ArgumentError} If either specified position or the result argument is null or undefined.
         */
        Position.interpolateGreatCircle = function (amount, position1, position2, result) {
            if (!position1 || !position2) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Position", "interpolateGreatCircle", "missingPosition"));
            }

            var t = WWMath.clamp(amount, 0, 1);
            Location.interpolateGreatCircle(t, position1, position2, result);
            result.altitude = WWMath.interpolate(t, position1.altitude, position2.altitude);
        };

        return Position;
    });