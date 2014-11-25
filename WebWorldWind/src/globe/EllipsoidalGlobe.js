/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports EllipsoidalGlobe
 * @version $Id$
 */
define([
        'src/util/Logger',
        'src/error/ArgumentError',
        'src/geom/Location',
        'src/geom/Angle',
        'src/geom/Sector',
        'src/globe/ZeroElevationModel'],
    function (Logger,
              ArgumentError,
              Location,
              Angle,
              Sector,
              ZeroElevationModel) {
        "use strict";

        /**
         * Constructs an EllipsoidalGlobe with default radii for Earth.
         * @alias EllipsoidalGlobe
         * @constructor
         * @classdesc Represents an ellipsoidal globe.
         * @param {ElevationModel} elevationModel The elevation model to use for the constructed globe. If null,
         * {@link ZeroElevationModel} is used.
         */
        var EllipsoidalGlobe = function (elevationModel) {
            /**
             * This globe's elevation model.
             * @type {ElevationModel}
             * @default {@link ZeroElevationModel}
             */
            this.elevationModel = elevationModel ? elevationModel : new ZeroElevationModel();

            /**
             * This globe's equatorial radius.
             * @type {number}
             * @default 6378137.0
             */
            this.equatorialRadius = 6378137.0;

            /**
             * This globe's polar radius.
             * @type {number}
             * @default 6356752.3
             */
            this.polarRadius = 6356752.3;

            /**
             * This globe's eccentricity squared.
             * @type {number}
             * @default 0.00669437999013
             */
            this.eccentricitySquared = 0.00669437999013;
        }

        /**
         * Computes a Cartesian point from a specified position.
         * @param {Number} latitude The position's latitude.
         * @param {Number} longitude The position's longitude.
         * @param {Number} altitude The position's altitude.
         * @param {Number[]} result A reference to a preallocated three-element array to contain, respectively, the X,
         * Y and Z Cartesian coordinates.
         * @returns {Number[]} The result argument if specified, otherwise a newly created array with the results.
         */
        EllipsoidalGlobe.prototype.computePointFromPosition = function (latitude, longitude, altitude, result) {
            var cosLat = Math.cos(latitude * Angle.DEGREES_TO_RADIANS),
                sinLat = Math.sin(latitude * Angle.DEGREES_TO_RADIANS),
                cosLon = Math.cos(longitude * Angle.DEGREES_TO_RADIANS),
                sinLon = Math.sin(longitude * Angle.DEGREES_TO_RADIANS),
                rpm = this.equatorialRadius / Math.sqrt(1.0 - this.eccentricitySquared * sinLat * sinLat),
                x = (rpm + altitude) * cosLat * sinLon,
                y = (rpm * (1.0 - this.eccentricitySquared) + altitude) * sinLat,
                z = (rpm + altitude) * cosLat * cosLon;

            if (!result)
                result = new Array(3); // TODO: Use a Vec3

            result[0] = x;
            result[1] = y;
            result[2] = z;

            return result;
        };

        /**
         * Computes the Cartesian coordinates of a specified number of positions within a specified sector.
         * @param {Sector} sector The sector in which to compute the points.
         * @param {Number} numLat The number of latitudinal locations at which to compute the points.
         * @param {Number} numLon The number of longitudinal locations at which to compute the points.
         * @param {Number[]} altitudes The altitudes at each of the points implied by the specified number of
         * latitudinal and longitudinal points.
         * @param {Number} borderAltitude The altitude at the border of the sector. // TODO: Verify this
         * @param {Number[]} offset Cartesian X, Y and Z values to offset the computed points. These offsets are
         * subtracted from the computed points.
         * @param {Number[]} resultPoints An array in which to return the computed points. It's length must be at least
         * numLat x numLon * stride.
         * @param {Number} stride The number of array elements between the X coordinates in the result array and the
         * X coordinate of the subsequent point in the result array. A tightly packed array has a stride of 3.
         * @param {Number[]} resultElevations An array to hold the elevations computed for each of the returned points.
         * The array must have a length of at least numLat * numLon.
         * @throws {ArgumentError} if the specified sector, altitudes array and results arrays or null or undefined, if
         * the lengths of any of the results arrays are insufficient, or if the specified stride is less than 3.
         */
        EllipsoidalGlobe.prototype.computePointsFromPositions = function (sector, numLat, numLon, altitudes,
                                                                          borderAltitude, offset, resultPoints,
                                                                          stride, resultElevations) {
            var msg;

            if (!sector) {
                msg = "EllipsoidalGlobe.computePointsFromPositions: Sector is null or undefined";
                Logger.log(Logger.LEVEL_SEVERE, msg);
                throw new ArgumentError(msg);
            }

            if (numLat < 1 || numLon < 1) {
                msg = "EllipsoidalGlobe.computePointsFromPositions: Number of latitude or longitude points is less than zero";
                Logger.log(Logger.LEVEL_SEVERE, msg);
                throw new ArgumentError(msg);
            }

            if (!altitudes) {
                msg = "EllipsoidalGlobe.computePointsFromPositions: Altitudes is null or undefined";
                Logger.log(Logger.LEVEL_SEVERE, msg);
                throw new ArgumentError(msg);
            }

            if (!resultPoints || resultPoints.length < numLat * numLon) {
                msg = "EllipsoidalGlobe.computePointsFromPositions: Result points array is null, undefined or insufficient length";
                Logger.log(Logger.LEVEL_SEVERE, msg);
                throw new ArgumentError(msg);
            }

            if (resultStride < 3) {
                msg = "EllipsoidalGlobe.computePointsFromPositions: Stride is less than 3";
                Logger.log(Logger.LEVEL_SEVERE, msg);
                throw new ArgumentError(msg);
            }

            if (!resultElevations || resultElevations.length < numLat * numLon) {
                msg = "EllipsoidalGlobe.computePointsFromPositions: Result elevations array is null, undefined or insufficient length";
                Logger.log(Logger.LEVEL_SEVERE, msg);
                throw new ArgumentError(msg);
            }

            var minLat = sector.minLatitude * Angle.DEGREES_TO_RADIANS,
                maxLat = sector.maxlatitude * Angle.DEGREES_TO_RADIANS,
                minLon = sector.minLongitude * Angle.DEGREES_TO_RADIANS,
                maxLon = sector.maxLongitude * Angle.DEGREES_TO_RADIANS,
                deltaLat = (maxLat - minLat) / (numLat > 1 ? numLat - 1 : 1),
                deltaLon = (maxLon - minLon) / (numLon > 1 ? numLon - 1 : 1),
                offsetX = offset[0],
                offsetY = offset[1],
                offsetZ = offset[2],
                numLatPoints = numLat + 2,
                numLonPoints = numLon + 2,
                vertexOffset = 0,
                elevOffset = 0,
                lat,
                lon = minLon,
                cosLat,
                sinLat,
                rpm,
                elev,
                cosLon = new Array(numLonPoints),
                sinLon = new Array(numLonPoints),
                i, j;

            // Iterate over the latitude coordinates in the specified sector and compute the cosine and sine of each longitude
            // value required to compute Cartesian points for the specified sector. This eliminates the need to re-compute the
            // same cosine and sine results for each row of latitude.
            for (i = 0; i < numLonPoints; i++) {
                // Explicitly set the first and last row to minLon and maxLon, respectively, rather than using the
                // accumulated lon value, in order to ensure that the Cartesian points of adjacent sectors match perfectly.
                if (i <= 1) // Border and first longitude.
                    lon = minLon;
                else if (i >= numLon) // Border and last longitude.
                    lon = maxLon;
                else
                    lon += deltaLon;

                cosLon[i] = Math.cos(lon);
                sinLon[i] = Math.sin(lon);
            }

            // Iterate over the latitude and longitude coordinates in the specified sector, computing the Cartesian point
            // corresponding to each latitude and longitude.
            lat = minLat;
            for (j = 0; j < numLatPoints; j++) {
                // Explicitly set the first and last row to minLat and maxLat, respectively, rather than using the
                // accumulated lat value, in order to ensure that the Cartesian points of adjacent sectors match perfectly.
                if (j <= 1) // Border and first latitude.
                    lat = minLat;
                else if (j >= numLat) // Border and last latitude.
                    lat = maxLat;
                else
                    lat += deltaLat;

                // Latitude is constant for each row, therefore values depending on only latitude can be computed once per row.
                cosLat = Math.cos(lat);
                sinLat = Math.sin(lat);
                rpm = this.equatorialRadius / sqrt(1.0 - this.eccentricitySquared * sinLat * sinLat);

                for (i = 0; i < numLon + 2; i++) {
                    elev = (j == 0 || j == numLat + 1 || i == 0 || i == numLon + 1)
                        ? borderAltitude : altitudes[elevOffset++];
                    resultElevations[vertexOffset / stride] = elev;

                    resultPoints[vertexOffset] = (rpm + elev) * cosLat * sinLon[i] - offsetX;
                    resultPoints[vertexOffset + 1] = (rpm * (1.0 - this.eccentricitySquared) + elev) * sinLat - offsetY;
                    resultPoints[vertexOffset + 2] = (rpm + elev) * cosLat * cosLon[i] - offsetZ;
                    vertexOffset += stride;
                }
            }
        };

        return EllipsoidalGlobe;
    });