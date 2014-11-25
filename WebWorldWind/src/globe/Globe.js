/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports Globe
 * @version $Id$
 */
define([
        'src/util/Logger',
        'src/error/ArgumentError',
        'src/geom/Location',
        'src/geom/Angle',
        'src/geom/Sector',
        'src/globe/ZeroElevationModel',
        'src/geom/Vec3'],
    function (Logger,
              ArgumentError,
              Location,
              Angle,
              Sector,
              ZeroElevationModel,
              Vec3) {
        "use strict";

        /**
         * Constructs an ellipsoidal Globe with default radii for Earth (WGS84).
         * @alias Globe
         * @constructor
         * @classdesc Represents an ellipsoidal globe.
         * @param {ElevationModel} elevationModel The elevation model to use for the constructed globe. If null,
         * {@link ZeroElevationModel} is used.
         */
        var Globe = function (elevationModel) {
            /**
             * This globe's elevation model.
             * @type {ElevationModel}
             * @default {@link ZeroElevationModel}
             */
            this.elevationModel = elevationModel ? elevationModel : new ZeroElevationModel();

            /**
             * This globe's equatorial radius.
             * @type {number}
             * @default 6378137.0 meters
             */
            this.equatorialRadius = 6378137.0;

            /**
             * This globe's polar radius.
             * @type {number}
             * @default 6356752.3 meters
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
         * @param {Number[]} result A reference to a pre-allocated three-element array to contain, respectively, the X,
         * Y and Z Cartesian coordinates.
         * @returns {Number[]} The result argument if specified, otherwise a newly created array with the results.
         */
        Globe.prototype.computePointFromPosition = function (latitude, longitude, altitude, result) {
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
        Globe.prototype.computePointsFromPositions = function (sector, numLat, numLon, altitudes,
                                                               borderAltitude, offset, resultPoints,
                                                               stride, resultElevations) {
            var msg;

            if (!sector instanceof Sector) {
                msg = "Globe.computePointsFromPositions: Sector is null, undefined or not a Sector";
                Logger.log(Logger.LEVEL_SEVERE, msg);
                throw new ArgumentError(msg);
            }

            if (numLat < 1 || numLon < 1) {
                msg = "Globe.computePointsFromPositions: Number of latitude or longitude points is less than zero";
                Logger.log(Logger.LEVEL_SEVERE, msg);
                throw new ArgumentError(msg);
            }

            if (!altitudes instanceof Array || altitudes.length < numLat * numLon) {
                msg = "Globe.computePointsFromPositions: Altitudes is null, undefined, not an Array or insufficient length";
                Logger.log(Logger.LEVEL_SEVERE, msg);
                throw new ArgumentError(msg);
            }

            if (!resultPoints instanceof Array || resultPoints.length < numLat * numLon) {
                msg = "Globe.computePointsFromPositions: Result points array is null, undefined, not an Array or insufficient length";
                Logger.log(Logger.LEVEL_SEVERE, msg);
                throw new ArgumentError(msg);
            }

            if (resultStride < 3) {
                msg = "Globe.computePointsFromPositions: Stride is less than 3";
                Logger.log(Logger.LEVEL_SEVERE, msg);
                throw new ArgumentError(msg);
            }

            if (!resultElevations instanceof Array || resultElevations.length < numLat * numLon) {
                msg = "Globe.computePointsFromPositions: Result elevations array is null, undefined, not an Array or insufficient length";
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

        Globe.prototype.computePositionFromPoint = function (x, y, z, result) {
            if (!resultPoints instanceof Vec3) {
                var msg = "Globe.computePointsFromPositions: Result points array is null, undefined, not an Array or insufficient length";
                Logger.log(Logger.LEVEL_SEVERE, msg);
                throw new ArgumentError(msg);
            }
            // Contributed by Nathan Kronenfeld. Updated on 1/24/2011. Brings this calculation in line with Vermeille's most
            // recent update.

            // According to H. Vermeille, "An analytical method to transform geocentric into geodetic coordinates"
            // http://www.springerlink.com/content/3t6837t27t351227/fulltext.pdf
            // Journal of Geodesy, accepted 10/2010, not yet published
            var X = z,
                Y = x,
                Z = y,
                XXpYY = X * X + Y * Y,
                sqrtXXpYY = sqrt(XXpYY),
                a = this.equatorialRadius,
                ra2 = 1 / (a * a),
                e2 = this.eccentricitySquared,
                e4 = e2 * e2,
                p = XXpYY * ra2,
                q = Z * Z * (1 - e2) * ra2,
                r = (p + q - e4) / 6,
                h,
                phi,
                u,
                evoluteBorderTest = 8 * r * r * r + e4 * p * q,
                rad1,
                rad2,
                rad3,
                atan,
                v,
                w,
                k,
                D,
                sqrtDDpZZ,
                e,
                lambda,
                s2;

            if (evoluteBorderTest > 0 || q != 0) {
                if (evoluteBorderTest > 0) {
                    // Step 2: general case
                    rad1 = Math.sqrt(evoluteBorderTest);
                    rad2 = Math.sqrt(e4 * p * q);

                    // 10*e2 is my arbitrary decision of what Vermeille means by "near... the cusps of the evolute".
                    if (evoluteBorderTest > 10 * e2) {
                        rad3 = Math.cbrt((rad1 + rad2) * (rad1 + rad2));
                        u = r + 0.5 * rad3 + 2 * r * r / rad3;
                    }
                    else {
                        u = r + 0.5 * Math.cbrt((rad1 + rad2) * (rad1 + rad2))
                        + 0.5 * Math.cbrt((rad1 - rad2) * (rad1 - rad2));
                    }
                }
                else {
                    // Step 3: near evolute
                    rad1 = Math.sqrt(-evoluteBorderTest);
                    rad2 = Math.sqrt(-8 * r * r * r);
                    rad3 = Math.sqrt(e4 * p * q);
                    atan = 2 * Math.atan2(rad3, rad1 + rad2) / 3;

                    u = -4 * r * Math.sin(atan) * Math.cos(Math.PI / 6 + atan);
                }

                v = Math.sqrt(u * u + e4 * q);
                w = e2 * (u + v - q) / (2 * v);
                k = (u + v) / (Math.sqrt(w * w + u + v) + w);
                D = k * sqrtXXpYY / (k + e2);
                sqrtDDpZZ = Math.sqrt(D * D + Z * Z);

                h = (k + e2 - 1) * sqrtDDpZZ / k;
                phi = 2 * Math.atan2(Z, sqrtDDpZZ + D);
            }
            else {
                // Step 4: singular disk
                rad1 = Math.sqrt(1 - e2);
                rad2 = Math.sqrt(e2 - p);
                e = Math.sqrt(e2);

                h = -a * rad1 * rad2 / e;
                phi = rad2 / (e * rad2 + rad1 * Math.sqrt(p));
            }

            // Compute lambda
            s2 = Math.sqrt(2);
            if ((s2 - 1) * Y < sqrtXXpYY + X) {
                // case 1 - -135deg < lambda < 135deg
                lambda = 2 * Math.atan2(Y, sqrtXXpYY + X);
            }
            else if (sqrtXXpYY + Y < (s2 + 1) * X) {
                // case 2 - -225deg < lambda < 45deg
                lambda = -Math.PI * 0.5 + 2 * Math.atan2(X, sqrtXXpYY - Y);
            }
            else {
                // if (sqrtXXpYY-Y<(s2=1)*X) {  // is the test, if needed, but it's not
                // case 3: - -45deg < lambda < 225deg
                lambda = Math.PI * 0.5 - 2 * Math.atan2(X, sqrtXXpYY + Y);
            }

            result.latitude = Angle.RADIANS_TO_DEGREES *  phi;
            result.longitude = Angle.RADIANS_TO_DEGREES * lambda;
            result.altitude = h;
        };

        return Globe;
    });