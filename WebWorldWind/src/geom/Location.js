/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports Location
 * @version $Id$
 */
define([
        '../geom/Angle',
        '../error/ArgumentError',
        '../util/Logger',
        '../util/WWMath'
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
         * @classdesc Represents a latitude, longitude pair in degrees.
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
         * Sets this location to the latitude and longitude of a specified location.
         * @param {Location} location The location to copy.
         * @returns {Location} This location, set to the values of the specified location.
         * @throws {ArgumentError} If the specified location is null or undefined.
         */
        Location.prototype.copy = function (location) {
            if (!location) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Location", "copy", "missingLocation"));
            }

            this.latitude = location.latitude;
            this.longitude = location.longitude;

            return this;
        };

        /**
         * Indicates whether this location is equal to a specified location.
         * @param {Location} location The location to compare this one to.
         * @returns {boolean} <code>true</code> if this location is equal to the specified location, otherwise
         * <code>false</code>.
         */
        Location.prototype.equals = function (location) {
            return location
                && location.latitude === this.latitude && location.longitude === this.longitude;
        };

        /**
         * Compute a location along a path at a specified distance between two specified locations.
         * @param {String} pathType The type of path to assume. Recognized values are
         * [WorldWind.GREAT_CIRCLE]{@link WorldWind#GREAT_CIRCLE},
         * [WorldWind.RHUMB_LINE]{@link WorldWind#RHUMB_LINE} and
         * [WorldWind.LINEAR]{@link WorldWind#INEAR}.
         * If the path type is not recognized then WorldWind.LINEAR is used.
         * @param {Number} amount The fraction of the path between the two locations at which to compute the new
         * location. This number should be between 0 and 1. If not, it is clamped to the nearest of those values.
         * @param {Location} location1 The starting location.
         * @param {Location} location2 The ending location.
         * @param {Location} result A Location in which to return the result.
         * @returns {Location} The specified result location.
         * @throws {ArgumentError} If either specified location or the result argument is null or undefined.
         */
        Location.interpolateAlongPath = function (pathType, amount, location1, location2, result) {
            if (!location1 || !location2) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Location", "interpolateAlongPath", "missingLocation"));
            }

            if (!result) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Location", "interpolateAlongPath", "missingResult"));
            }

            if (pathType === WorldWind.GREAT_CIRCLE) {
                return this.interpolateGreatCircle(amount, location1, location2, result);
            } else if (pathType && pathType === WorldWind.RHUMB_LINE) {
                return this.interpolateRhumb(amount, location1, location2, result);
            } else {
                return this.interpolateLinear(amount, location1, location2, result);
            }
        };

        /**
         * Compute a location along a great circle path at a specified distance between two specified locations.
         * @param {Number} amount The fraction of the path between the two locations at which to compute the new
         * location. This number should be between 0 and 1. If not, it is clamped to the nearest of those values.
         * @param {Location} location1 The starting location.
         * @param {Location} location2 The ending location.
         * @param {Location} result A Location in which to return the result.
         * @returns {Location} The specified result location.
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
                return result;
            }

            var t = WWMath.clamp(amount, 0, 1),
                azimuthDegrees = this.greatCircleAzimuth(location1, location2),
                distanceRadians = this.greatCircleDistance(location1, location2);

            return this.greatCircleLocation(location1, azimuthDegrees, t * distanceRadians, result);
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
         * angle between the two positions. In radians, this angle is the arc length of the segment between the two
         * positions. To compute a distance in meters from this value, multiply the return value by the radius of the
         * globe.
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
            c = a * a + Math.cos(lat1) * Math.cos(lat2) * b * b;
            distanceRadians = 2.0 * Math.asin(Math.sqrt(c));

            return isNaN(distanceRadians) ? 0 : distanceRadians;
        };

        /**
         * Computes the location on a great circle path corresponding to a given starting location, azimuth, and
         * arc distance.
         *
         * @param {Location} location The starting location.
         * @param {Number} greatCircleAzimuthDegrees The azimuth in degrees.
         * @param {Number} pathLengthRadians The radian distance along the path at which to compute the end location.
         * @param {Location} result A Location in which to return the result.
         * @returns {Location} The specified result location.
         * @throws {ArgumentError} If the specified location or the result argument is null or undefined.
         */
        Location.greatCircleLocation = function (location, greatCircleAzimuthDegrees, pathLengthRadians, result) {
            if (!location) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Location", "greatCircleLocation", "missingLocation"));
            }
            if (!result) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Location", "greatCircleLocation", "missingResult"));
            }

            if (pathLengthRadians == 0) {
                result.latitude = location.latitude;
                result.longitude = location.longitude;
                return result;
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

            return result;
        };

        /**
         * Compute a location along a rhumb path at a specified distance between two specified locations.
         * @param {Number} amount The fraction of the path between the two locations at which to compute the new
         * location. This number should be between 0 and 1. If not, it is clamped to the nearest of those values.
         * @param {Location} location1 The starting location.
         * @param {Location} location2 The ending location.
         * @param {Location} result A Location in which to return the result.
         * @returns {Location} The specified result location.
         * @throws {ArgumentError} If either specified location or the result argument is null or undefined.
         */
        Location.interpolateRhumb = function (amount, location1, location2, result) {
            if (!location1 || !location2) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Location", "interpolateRhumb", "missingLocation"));
            }
            if (!result) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Location", "interpolateRhumb", "missingResult"));
            }

            if (location1.equals(location2)) {
                result.latitude = location1.latitude;
                result.longitude = location1.longitude;
                return result;
            }

            var t = WWMath.clamp(amount, 0, 1),
                azimuthDegrees = this.rhumbAzimuth(location1, location2),
                distanceRadians = this.rhumbDistance(location1, location2);

            return this.rhumbLocation(location1, azimuthDegrees, t * distanceRadians, result);
        };

        /**
         * Computes the azimuth angle (clockwise from North) that points from the first location to the second location.
         * This angle can be used as the azimuth for a rhumb arc that begins at the first location, and
         * passes through the second location.
         * @param {Location} location1 The starting location.
         * @param {Location} location2 The ending location.
         * @returns {Number} The computed azimuth, in degrees.
         * @throws {ArgumentError} If either specified location is null or undefined.
         */
        Location.rhumbAzimuth = function (location1, location2) {
            if (!location1 || !location2) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Location", "rhumbAzimuth", "missingLocation"));
            }

            var lat1 = location1.latitude * Angle.DEGREES_TO_RADIANS,
                lat2 = location2.latitude * Angle.DEGREES_TO_RADIANS,
                lon1 = location1.longitude * Angle.DEGREES_TO_RADIANS,
                lon2 = location2.longitude * Angle.DEGREES_TO_RADIANS,
                dLon,
                dPhi,
                azimuthRadians;

            if (lat1 == lat2 && lon1 == lon2) {
                return 0;
            }

            dLon = lon2 - lon1;
            dPhi = Math.log(Math.tan(lat2 / 2.0 + Math.PI / 4) / Math.tan(lat1 / 2.0 + Math.PI / 4));

            // If lonChange over 180 take shorter rhumb across 180 meridian.
            if (WWMath.fabs(dLon) > Math.PI) {
                dLon = dLon > 0 ? -(2 * Math.PI - dLon) : (2 * Math.PI + dLon);
            }

            azimuthRadians = Math.atan2(dLon, dPhi);

            return isNaN(azimuthRadians) ? 0 : azimuthRadians * Angle.RADIANS_TO_DEGREES;
        };

        /**
         * Computes the rhumb angular distance between two locations. The return value gives the distance as the
         * angle between the two positions in radians. This angle is the arc length of the segment between the two
         * positions. To compute a distance in meters from this value, multiply the return value by the radius of the
         * globe.
         *
         * @param {Location} location1 The starting location.
         * @param {Location} location2 The ending location.
         * @returns {Number} The computed distance, in radians.
         * @throws {ArgumentError} If either specified location is null or undefined.
         */
        Location.rhumbDistance = function (location1, location2) {
            if (!location1 || !location2) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Location", "rhumbDistance", "missingLocation"));
            }

            var lat1 = location1.latitude * Angle.DEGREES_TO_RADIANS,
                lat2 = location2.latitude * Angle.DEGREES_TO_RADIANS,
                lon1 = location1.longitude * Angle.DEGREES_TO_RADIANS,
                lon2 = location2.longitude * Angle.DEGREES_TO_RADIANS,
                dLat,
                dLon,
                dPhi,
                q,
                distanceRadians;

            if (lat1 == lat2 && lon1 == lon2) {
                return 0;
            }

            dLat = lat2 - lat1;
            dLon = lon2 - lon1;
            dPhi = Math.log(Math.tan(lat2 / 2.0 + Math.PI / 4) / Math.tan(lat1 / 2.0 + Math.PI / 4));
            q = dLat / dPhi;

            if (isNaN(dPhi) || isNaN(q)) {
                q = Math.cos(lat1);
            }

            // If lonChange over 180 take shorter rhumb across 180 meridian.
            if (WWMath.fabs(dLon) > Math.PI) {
                dLon = dLon > 0 ? -(2 * Math.PI - dLon) : (2 * Math.PI + dLon);
            }

            distanceRadians = Math.sqrt(dLat * dLat + q * q * dLon * dLon);

            return isNaN(distanceRadians) ? 0 : distanceRadians;
        };

        /**
         * Computes the location on a rhumb arc with the given starting location, azimuth, and arc distance.
         *
         * @param {Location} location The starting location.
         * @param {Number} azimuthDegrees The azimuth in degrees.
         * @param {Number} pathLengthRadians The radian distance along the path at which to compute the location.
         * @param {Location} result A Location in which to return the result.
         * @returns {Location} The specified result location.
         * @throws {ArgumentError} If the specified location or the result argument is null or undefined.
         */
        Location.rhumbLocation = function (location, azimuthDegrees, pathLengthRadians, result) {
            if (!location) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Location", "rhumbLocation", "missingLocation"));
            }
            if (!result) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Location", "rhumbLocation", "missingResult"));
            }

            if (pathLengthRadians == 0) {
                result.latitude = location.latitude;
                result.longitude = location.longitude;
                return result;
            }

            var latRadians = location.latitude * Angle.DEGREES_TO_RADIANS,
                lonRadians = location.longitude * Angle.DEGREES_TO_RADIANS,
                azimuthRadians = azimuthDegrees * Angle.DEGREES_TO_RADIANS,
                endLatRadians = latRadians + pathLengthRadians * Math.cos(azimuthRadians),
                dPhi = Math.log(Math.tan(endLatRadians / 2 + Math.PI / 4) / Math.tan(latRadians / 2 + Math.PI / 4)),
                q = (endLatRadians - latRadians) / dPhi,
                dLon,
                endLonRadians;

            if (isNaN(dPhi) || isNaN(q) || !isFinite(q)) {
                q = Math.cos(latRadians);
            }

            dLon = pathLengthRadians * Math.sin(azimuthRadians) / q;

            // Handle latitude passing over either pole.
            if (WWMath.fabs(endLatRadians) > Math.PI / 2)
            {
                endLatRadians = endLatRadians > 0 ? Math.PI - endLatRadians : -Math.PI - endLatRadians;
            }

            endLonRadians = WWMath.fmod(lonRadians + dLon + Math.PI, 2 * Math.PI) - Math.PI;

            if (isNaN(endLatRadians) || isNaN(endLonRadians)) {
                result.latitude = location.latitude;
                result.longitude = location.longitude;
            } else {
                result.latitude = Angle.normalizedRadiansLatitude(endLatRadians);
                result.longitude = Angle.normalizedRadiansLongitude(endLonRadians);
            }

            return result;
        };

        /**
         * Compute a location along a linear path at a specified distance between two specified locations.
         * @param {Number} amount The fraction of the path between the two locations at which to compute the new
         * location. This number should be between 0 and 1. If not, it is clamped to the nearest of those values.
         * @param {Location} location1 The starting location.
         * @param {Location} location2 The ending location.
         * @param {Location} result A Location in which to return the result.
         * @returns {Location} The specified result location.
         * @throws {ArgumentError} If either specified location or the result argument is null or undefined.
         */
        Location.interpolateLinear = function (amount, location1, location2, result) {
            if (!location1 || !location2) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Location", "interpolateLinear", "missingLocation"));
            }
            if (!result) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Location", "interpolateLinear", "missingResult"));
            }

            if (location1.equals(location2)) {
                result.latitude = location1.latitude;
                result.longitude = location1.longitude;
                return result;
            }

            var t = WWMath.clamp(amount, 0, 1),
                azimuthDegrees = this.linearAzimuth(location1, location2),
                distanceRadians = this.linearDistance(location1, location2);

            return this.linearLocation(location1, azimuthDegrees, t * distanceRadians, result);
        };

        /**
         * Computes the azimuth angle (clockwise from North) that points from the first location to the second location.
         * This angle can be used as the azimuth for a linear arc that begins at the first location, and
         * passes through the second location.
         * @param {Location} location1 The starting location.
         * @param {Location} location2 The ending location.
         * @returns {Number} The computed azimuth, in degrees.
         * @throws {ArgumentError} If either specified location is null or undefined.
         */
        Location.linearAzimuth = function (location1, location2) {
            if (!location1 || !location2) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Location", "linearAzimuth", "missingLocation"));
            }

            var lat1 = location1.latitude * Angle.DEGREES_TO_RADIANS,
                lat2 = location2.latitude * Angle.DEGREES_TO_RADIANS,
                lon1 = location1.longitude * Angle.DEGREES_TO_RADIANS,
                lon2 = location2.longitude * Angle.DEGREES_TO_RADIANS,
                dLon,
                dPhi,
                azimuthRadians;

            if (lat1 == lat2 && lon1 == lon2) {
                return 0;
            }

            dLon = lon2 - lon1;
            dPhi = lat2 - lat1;

            // If longitude change is over 180 take shorter path across 180 meridian.
            if (WWMath.fabs(dLon) > Math.PI) {
                dLon = dLon > 0 ? -(2 * Math.PI - dLon) : (2 * Math.PI + dLon);
            }

            azimuthRadians = Math.atan2(dLon, dPhi);

            return isNaN(azimuthRadians) ? 0 : azimuthRadians * Angle.RADIANS_TO_DEGREES;
        };

        /**
         * Computes the linear angular distance between two locations. The return value gives the distance as the
         * angle between the two positions in radians. This angle is the arc length of the segment between the two
         * positions. To compute a distance in meters from this value, multiply the return value by the radius of the
         * globe.
         *
         * @param {Location} location1 The starting location.
         * @param {Location} location2 The ending location.
         * @returns {Number} The computed distance, in radians.
         * @throws {ArgumentError} If either specified location is null or undefined.
         */
        Location.linearDistance = function (location1, location2) {
            if (!location1 || !location2) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Location", "linearDistance", "missingLocation"));
            }

            var lat1 = location1.latitude * Angle.DEGREES_TO_RADIANS,
                lat2 = location2.latitude * Angle.DEGREES_TO_RADIANS,
                lon1 = location1.longitude * Angle.DEGREES_TO_RADIANS,
                lon2 = location2.longitude * Angle.DEGREES_TO_RADIANS,
                dLat,
                dLon,
                distanceRadians;

            if (lat1 == lat2 && lon1 == lon2) {
                return 0;
            }

            dLat = lat2 - lat1;
            dLon = lon2 - lon1;

            // If lonChange over 180 take shorter path across 180 meridian.
            if (WWMath.fabs(dLon) > Math.PI) {
                dLon = dLon > 0 ? -(2 * Math.PI - dLon) : (2 * Math.PI + dLon);
            }

            distanceRadians = Math.sqrt(dLat * dLat + dLon * dLon);

            return isNaN(distanceRadians) ? 0 : distanceRadians;
        };

        /**
         * Computes the location on a linear path with the given starting location, azimuth, and arc distance.
         *
         * @param {Location} location The starting location.
         * @param {Number} azimuthDegrees The azimuth in degrees.
         * @param {Number} pathLengthRadians The radian distance along the path at which to compute the location.
         * @param {Location} result A Location in which to return the result.
         * @returns {Location} The specified result location.
         * @throws {ArgumentError} If the specified location or the result argument is null or undefined.
         */
        Location.linearLocation = function (location, azimuthDegrees, pathLengthRadians, result) {
            if (!location) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Location", "linearLocation", "missingLocation"));
            }
            if (!result) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Location", "linearLocation", "missingResult"));
            }

            if (pathLengthRadians == 0) {
                result.latitude = location.latitude;
                result.longitude = location.longitude;
                return result;
            }

            var latRadians = location.latitude * Angle.DEGREES_TO_RADIANS,
                lonRadians = location.longitude * Angle.DEGREES_TO_RADIANS,
                azimuthRadians = azimuthDegrees * Angle.DEGREES_TO_RADIANS,
                endLatRadians = latRadians + pathLengthRadians * Math.cos(azimuthRadians),
                endLonRadians;

            // Handle latitude passing over either pole.
            if (WWMath.fabs(endLatRadians) > Math.PI / 2)
            {
                endLatRadians = endLatRadians > 0 ? Math.PI - endLatRadians : -Math.PI - endLatRadians;
            }

            endLonRadians =
                WWMath.fmod(lonRadians + pathLengthRadians * Math.sin(azimuthRadians) + Math.PI, 2 * Math.PI) - Math.PI;

            if (isNaN(endLatRadians) || isNaN(endLonRadians)) {
                result.latitude = location.latitude;
                result.longitude = location.longitude;
            } else {
                result.latitude = Angle.normalizedRadiansLatitude(endLatRadians);
                result.longitude = Angle.normalizedRadiansLongitude(endLonRadians);
            }

            return result;
        };

        return Location;
    });