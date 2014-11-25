/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports Position
 * @version $Id$
 */
define([
        'src/util/Logger',
        'src/error/ArgumentError',
        'src/geom/Angle',
        'src/util/WWMath'
    ],
    function (Logger,
              ArgumentError,
              Angle,
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
        }

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
                var msg = "Position.fromPosition: Position is null, undefined or not a Position";
                Logger.log(Logger.LEVEL_SEVERE, msg);
                throw new ArgumentError(msg);
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
            return position instanceof Position && position.latitude == this.latitude
                && position.longitude == this.longitude
                && position.altitude == this.altitude;
        };

    });