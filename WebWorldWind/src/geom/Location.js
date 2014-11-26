/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports Location
 * @version $Id$
 */
define([
        'src/geom/Angle',
        'src/error/ArgumentError',
        'src/util/Logger',
        'src/util/WWMath'
    ],
    function (Angle,
              ArgumentError,
              Logger,
              WWMath) {
        "use strict";

        /**
         * Constructs a location from a specified latitude and longitude in degrees.
         * @alias Location
         * @constructor
         * @classdesc Represents a latitude, longitude pair.
         * @param {Number} latitude The latitude in degrees.
         * @param {Number} longitude The longitude in degrees.
         */
        var Location = function (latitude, longitude) {
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
        };

        /**
         * A Location with latitude and longitude both 0.
         * @constant
         * @type {Location}
         */
        Location.ZERO = new Location(0, 0);

        /**
         * Creates a location from angles specified in radians.
         * @param {Number} latitudeRadians The latitude in radians.
         * @param {Number} longitudeRadians The longitude in radians
         * @returns {Location} The new location with latitude and longitude in degrees.
         */
        Location.fromRadians = function (latitudeRadians, longitudeRadians) {
            return new Location(latitudeRadians * Angle.RADIANS_TO_DEGREES, longitudeRadians * Angle.RADIANS_TO_DEGREES);
        };

        /**
         * Creates a new location from a specified location.
         * @param {Location} location The location to copy.
         * @returns {Location} The new location, initialized to the values of the specified location.
         * @throws {ArgumentError} If the specified location is null or undefined.
         */
        Location.fromLocation = function (location) {
            if (!location) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Location", "fromLocation", "missingLocation"));
            }

            return new Location(location.latitude, location.longitude);
        };

        /**
         * Indicates whether this location is equivalent to a specified location.
         * @param {Location} location The location to compare this one to.
         * @returns {boolean} <code>true</code> if this location is equivalent to the specified one, otherwise
         * <code>false</code>.
         */
        Location.prototype.equals = function (location) {
            return (location instanceof Location)
                && location.latitude == this.latitude && location.longitude == this.longitude;
        };

        /**
         * Compute a location along a path at a specified distance between two specified locations.
         * @param {String} pathType The type of path to assume. Recognized values are WorldWind.GREAT_CIRCLE,
         * WorldWind.RHUMB_LINE and WorldWind.LINEAR. If the path type is not recognized then WorldWind.LINEAR is
         * used.
         * @param {Number} amount The fraction of the path between the two locations at which to compute the new
         * location. This number should be between 0 and 1. If not, it is clamped to the nearest of those values.
         * @param {Location} location1 The starting location.
         * @param {Location} location2 The ending location.
         * @param {Location} result A Location in which to return the result.
         * @throws {ArgumentError} If either specified location is null or undefined.
         */
        Location.interpolateAlongPath = function (pathType, amount, location1, location2, result) {
            if (!location1 || !location2) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Location", "interpolateAlongPath", "missingLocation"));
            }

            if (pathType && pathType === WorldWind.GREAT_CIRCLE) {
                this.interpolateGreatCircle(amount, location1, location2, result);
            } else if (pathType && pathType === WorldWind.RHUMB_LINE) {
                // TODO
            } else {
                // TODO
            }
        };

        /**
         * Compute a location along a great circle path at a specified distance between two specified locations.
         * @param {Number} amount The fraction of the path between the two locations at which to compute the new
         * location. This number should be between 0 and 1. If not, it is clamped to the nearest of those values.
         * @param {Location} location1 The starting location.
         * @param {Location} location2 The ending location.
         * @param {Location} result A Location in which to return the result.
         * @throws {ArgumentError} If either specified location or the result argument is null or undefined.
         */
        Location.interpolateGreatCircle = function (amount, location1, location2, result) {
            if (!location1 || !location2) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Location", "interpolateGreatCircle", "missingLocation"));
            }
            if (!result) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Location", "interpolateGreatCircle", "missingResult"));
            }

            if (location1.equals(location2)) {
                result.latitude = location1.latitude;
                result.longitude = location1.longitude;
                return;
            }

            var t = WWMath.clamp(amount, 0, 1),
                azimuthDegrees = this.greatCircleAzimuth(location1, location2),
                distanceRadians = this.greatCircleDistance(location1, location2);

            this.greatCircleEndPosition(location1, azimuthDegrees, t * distanceRadians, result);
        };

        /**
         * Computes the azimuth angle (clockwise from North) that points from the first location to the second location.
         * This angle can be used as the starting azimuth for a great circle arc that begins at the first location, and
         * passes through the second location.
         * @param {Location} location1 The starting location.
         * @param {Location} location2 The ending location.
         * @returns {Number} The computed azimuth, in degrees.
         * @throws {ArgumentError} If either specified location is null or undefined.
         */
        Location.greatCircleAzimuth = function (location1, location2) {
            if (!location1 || !location2) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Location", "greatCircleAzimuth", "missingLocation"));
            }

            var lat1 = location1.latitude * Angle.DEGREES_TO_RADIANS,
                lat2 = location2.latitude * Angle.DEGREES_TO_RADIANS,
                lon1 = location1.longitude * Angle.DEGREES_TO_RADIANS,
                lon2 = location2.longitude * Angle.DEGREES_TO_RADIANS,
                x,
                y,
                azimuthRadians;

            if (lat1 == lat2 && lon1 == lon2) {
                return 0;
            }

            if (lon1 == lon2) {
                return lat1 > lat2 ? 180 : 0;
            }

            // Taken from "Map Projections - A Working Manual", page 30, equation 5-4b.
            // The atan2() function is used in place of the traditional atan(y/x) to simplify the case when x == 0.
            y = Math.cos(lat2) * Math.sin(lon2 - lon1);
            x = Math.cos(lat1) * Math.sin(lat2) - Math.sin(lat1) * Math.cos(lat2) * Math.cos(lon2 - lon1);
            azimuthRadians = Math.atan2(y, x);

            return isNaN(azimuthRadians) ? 0 : azimuthRadians * Angle.RADIANS_TO_DEGREES;
        };

        /**
         * Computes the great circle angular distance between two locations. The return value gives the distance as the
         * angle between the two positions on the pi radius circle. In radians, this angle is also the arc length of the
         * segment between the two positions on that circle. To compute a distance in meters from this value, multiply
         * the return value by the radius of the globe.
         *
         * @param {Location} location1 The starting location.
         * @param {Location} location2 The ending location.
         * @returns {Number} The computed distance, in radians.
         * @throws {ArgumentError} If either specified location is null or undefined.
         */
        Location.greatCircleDistance = function (location1, location2) {
            if (!location1 || !location2) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Location", "greatCircleDistance", "missingLocation"));
            }

            var lat1 = location1.latitude * Angle.DEGREES_TO_RADIANS,
                lat2 = location2.latitude * Angle.DEGREES_TO_RADIANS,
                lon1 = location1.longitude * Angle.DEGREES_TO_RADIANS,
                lon2 = location2.longitude * Angle.DEGREES_TO_RADIANS,
                a,
                b,
                c,
                distanceRadians;

            if (lat1 == lat2 && lon1 == lon2) {
                return 0;
            }

            // "Haversine formula," taken from http://en.wikipedia.org/wiki/Great-circle_distance#Formul.C3.A6
            a = Math.sin((lat2 - lat1) / 2.0);
            b = Math.sin((lon2 - lon1) / 2.0);
            c = a * a + +Math.cos(lat1) * Math.cos(lat2) * b * b;
            distanceRadians = 2.0 * Math.asin(Math.sqrt(c));

            return isNaN(distanceRadians) ? 0 : distanceRadians;
        };

        /**
         * Computes the location on a great circle arc with the given starting location, azimuth, and arc distance.
         *
         * @param {Location} location The starting location.
         * @param {Number} greatCircleAzimuthDegrees The azimuth in degrees.
         * @param {Number} pathLengthRadians The radian distance along the path at which to compute the end location.
         * @param {Location} result A Location in which to return the result.
         * @throws {ArgumentError} If the specified location or the result argument is null or undefined.
         */
        Location.greatCircleEndPosition = function (location, greatCircleAzimuthDegrees, pathLengthRadians, result) {
            if (!location) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Location", "greatCircleEndPosition", "missingLocation"));
            }

            if (pathLengthRadians == 0) {
                result.latitude = location.latitude;
                result.longitude = location.longitude;
                return;
            }

            var latRadians = location.latitude * Angle.DEGREES_TO_RADIANS,
                lonRadians = location.longitude * Angle.DEGREES_TO_RADIANS,
                azimuthRadians = greatCircleAzimuthDegrees * Angle.DEGREES_TO_RADIANS,
                endLatRadians,
                endLonRadians;

            // Taken from "Map Projections - A Working Manual", page 31, equation 5-5 and 5-6.
            endLatRadians = Math.asin(Math.sin(latRadians) * Math.cos(pathLengthRadians)
            + Math.cos(latRadians) * Math.sin(pathLengthRadians) * Math.cos(azimuthRadians));
            endLonRadians = lonRadians + Math.atan2(
                Math.sin(pathLengthRadians) * Math.sin(azimuthRadians),
                Math.cos(latRadians) * Math.cos(pathLengthRadians) - Math.sin(latRadians) * Math.sin(pathLengthRadians)
                * Math.cos(azimuthRadians));

            if (isNaN(endLatRadians) || isNaN(endLonRadians)) {
                result.latitude = location.latitude;
                result.longitude = location.longitude;
            } else {
                result.latitude = Angle.normalizedRadiansLatitude(endLatRadians);
                result.longitude = Angle.normalizedRadiansLongitude(endLonRadians);
            }

        };

        return Location;
    });