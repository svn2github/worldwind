/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @version $Id$
 */
/**
 * Provides functions to operate on arrays of latitude and longitude pairs. The arrays are in the order of latitude
 * followed by longitude and unless otherwise specified are in degrees.
 * @module Location
 */
define(['src/util/Logger', 'src/error/ArgumentError', 'src/geom/Angle', 'src/util/WWMath'], function (Logger, ArgumentError, Angle, WWMath) {
    "use strict";

    return {
        /**
         * A two-element array with latitude and longitude both 0.
         * @constant
         */
        ZERO: [0, 0],

        /**
         * Indicates whether two locations are equal.
         * @param {Array} location1 The first location.
         * @param {Array} location2 The second location.
         * @returns {boolean} <code>true</code> if the locations are non-null and identical, otherwise <code>false</code>.
         */
        equals: function (location1, location2) {
            if (location1 && location2) {
                return location1[0] == location2[0] && location1[1] == location2[1];
            } else {
                return false;
            }
        },

        /**
         * Returns a two-element array of doubles containing the specified latitude and longitude.
         * @param {Number} latitudeDegrees The latitude to return.
         * @param {Number} longitudeDegrees The longitude to return;
         * @returns {Array} A two-element array of doubles containing the specified latitude and longitude.
         */
        fromDegrees: function (latitudeDegrees, longitudeDegrees) {
            return [latitudeDegrees, longitudeDegrees];
        },

        /**
         * Returns a two-element array of doubles containing the specified radians of latitude and longitude in degrees.
         * @param {Number} latitudeRadians The radians of latitude to return.
         * @param {Number} longitudeRadians The radians of longitude to return;
         * @returns {Array} A two-element array of doubles containing the specified latitude and longitude in degrees.
         */
        fromRadians: function (latitudeRadians, longitudeRadians) {
            return [latitudeRadians * Angle.RADIANS_TO_DEGREES, longitudeRadians * Angle.RADIANS_TO_DEGREES];
        },

        /**
         * Returns the latitude component of a two-element Location array.
         * @param {Array} location The location whose latitude to return.
         * @returns {Number} The location's latitude, or <code>undefined</code> if the specified location is null or
         * undefined.
         */
        getLatitude: function (location) {
            return location ? location[0] : undefined;
        },

        /**
         * Returns the longitude component of a two-element Location array.
         * @param {Array} location The location whose longitude to return.
         * @returns {Number} The location's longitude, or <code>undefined</code> if the specified location is null or
         * undefined.
         */
        getLongitude: function (location) {
            return location ? location[1] : undefined;
        },

        /**
         * Returns in radians a two-element array containing the latitude and longitude of a specified location
         * expressed in degrees.
         * @param {Array} location The location to convert, in degrees.
         * @returns {Array} A new location expressed in radians, or <code>null</code> if the specified location is
         * null or undefined or its length is less than 2.
         */
        asRadians: function (location) {
            return location && location.length >= 2 ?
                [location[0] * Angle.DEGREES_TO_RADIANS, location[1] * Angle.DEGREES_TO_RADIANS] : null;
        },

        /**
         * Compute a location a specified amount between two specified locations.
         * @param {String} pathType The type of path to assume. Recognized values are WorldWind.GREAT_CIRCLE,
         * WorldWind.RHUMB_LINE and WorldWind.LINEAR. If the path type is not recognized then WorldWind.LINEAR is
         * used.
         * @param {Number} amount The fraction of the path between the two locations at which to compute the new
         * location. This number should be between 0 and 1. If not, it is clamped to the nearest of those values.
         * @param {Array} location1 The starting location.
         * @param {Array} location2 The ending location.
         * @returns {Array} The computed location as a two-element array of latitude and longitude expressed in degrees.
         * @throws {ArgumentError} If either specified location is null or undefined.
         */
        interpolateAlongPath: function (pathType, amount, location1, location2) {
            if (!location1 || !location2) {
                var msg = "Location.InterpolateAlongPath: Location is null or undefined";
                Logger.log(Logger.LEVEL_SEVERE, msg);
                throw new ArgumentError(msg);
            }

            if (pathType && pathType === WorldWind.GREAT_CIRCLE) {
                return this.interpolateGreatCircle(amount, location1, location2);
            } else if (pathType && pathType === WorldWind.RHUMB_LINE) {
                // TODO
            } else {
                // TODO
            }
        },

        interpolateGreatCircle: function (amount, location1, location2) {
            if (!location1 || !location2) {
                var msg = "Location.interpolateGreatCircle: Location is null or undefined";
                Logger.log(Logger.LEVEL_SEVERE, msg);
                throw new ArgumentError(msg);
            }

            if (this.equals(location1, location2))
                return location1;

            var t = WWMath.clamp(amount, 0, 1),
                azimuthDegrees = this.greatCircleAzimuth(location1, location2),
                distanceRadians = this.greatCircleDistance(location1, location2);

            return this.greatCircleEndPosition(location1, azimuthDegrees, t * distanceRadians);
        },

        greatCircleAzimuth: function (location1, location2) {
            if (!location1 || !location2) {
                var msg = "Location.greatCircleAzimuth: Location is null or undefined";
                Logger.log(Logger.LEVEL_SEVERE, msg);
                throw new ArgumentError(msg);
            }

            var lat1 = location1[0] * Angle.DEGREES_TO_RADIANS,
                lat2 = location2[2] * Angle.DEGREES_TO_RADIANS,
                lon1 = location1[1] * Angle.DEGREES_TO_RADIANS,
                lon2 = location2[1] * Angle.DEGREES_TO_RADIANS,
                x,
                y,
                azimuthRadians;

            if (lat1 == lat && lon1 == lon2) {
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
        },

        greatCircleDistance: function (location1, location2) {
            if (!location1 || !location2) {
                var msg = "Location.greatCircleAzimuth: Location is null or undefined";
                Logger.log(Logger.LEVEL_SEVERE, msg);
                throw new ArgumentError(msg);
            }

            var lat1 = location1[0] * Angle.DEGREES_TO_RADIANS,
                lat2 = location2[2] * Angle.DEGREES_TO_RADIANS,
                lon1 = location1[1] * Angle.DEGREES_TO_RADIANS,
                lon2 = location2[1] * Angle.DEGREES_TO_RADIANS,
                a,
                b,
                c,
                distanceRadians;

            if (lat1 == lat && lon1 == lon2) {
                return 0;
            }

            // "Haversine formula," taken from http://en.wikipedia.org/wiki/Great-circle_distance#Formul.C3.A6
            a = Math.sin((lat2 - lat1) / 2.0);
            b = Math.sin((lon2 - lon1) / 2.0);
            c = a * a + +Math.cos(lat1) * Math.cos(lat2) * b * b;
            distanceRadians = 2.0 * Math.asin(Math.sqrt(c));

            return isNaN(distanceRadians) ? 0 : distanceRadians;
        },

        greatCircleEndPosition: function (location, greatCircleAzimuthDegrees, pathLengthRadians) {
            if (!location) {
                var msg = "Location.greatCircleEndPosition: Location is null or undefined";
                Logger.log(Logger.LEVEL_SEVERE, msg);
                throw new ArgumentError(msg);
            }

            if (pathLengthRadians == 0)
                return location;

            var latRadians = location[0] * Angle.DEGREES_TO_RADIANS,
                lonRadians = location[1] * Angle.DEGREES_TO_RADIANS,
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

            if (isNaN(endLatRadians) || isNaN(endLonRadians))
                return location;

            return Angle.fromRadians(Angle.normalizedRadiansLatitude(endLatRadians),
                Angle.normalizedRadiansLongitude(endLonRadians));
        }

    }
});