/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports Globe
 * @version $Id$
 */
define([
        '../geom/Angle',
        '../error/ArgumentError',
        '../globe/ElevationModel',
        '../geom/Line',
        '../geom/Location',
        '../util/Logger',
        '../geom/Position',
        '../geom/Sector',
        '../geom/Vec3',
        '../util/WWMath'],
    function (Angle,
              ArgumentError,
              ElevationModel,
              Line,
              Location,
              Logger,
              Position,
              Sector,
              Vec3,
              WWMath) {
        "use strict";

        /**
         * Constructs an ellipsoidal Globe with default radii for Earth (WGS84).
         * @alias Globe
         * @constructor
         * @classdesc Represents an ellipsoidal globe. The default values represent Earth.
         *
         * A globe is used to generate terrain.
         *
         * The globe uses a Cartesian coordinate system in which the Y axis points to the north pole,
         * the Z axis points to the intersection of the prime meridian and the equator,
         * and the X axis completes a right-handed coordinate system, is in the equatorial plane and 90 degree east of the Z
         * axis. The origin of the coordinate system lies at the center of the globe.

         * @param {ElevationModel} elevationModel The elevation model to use for the constructed globe.
         * @throws {ArgumentError} If the specified elevation model is null or undefined.
         */
        var Globe = function (elevationModel) {
            if (!elevationModel) {
                throw new ArgumentError(Logger.logMessage(Logger.LEVEL_SEVERE, "Globe",
                    "constructor", "Elevation model is null or undefined."));
            }
            /**
             * This globe's elevation model.
             * @type {ElevationModel}
             * @default {@link ZeroElevationModel}
             */
            this.elevationModel = elevationModel;

            /**
             * This globe's equatorial radius.
             * @type {Number}
             * @default 6378137.0 meters
             */
            this.equatorialRadius = 6378137.0;

            /**
             * This globe's polar radius.
             * @type {Number}
             * @default 6356752.3 meters
             */
            this.polarRadius = 6356752.3;

            /**
             * This globe's eccentricity squared.
             * @type {Number}
             * @default 0.00669437999013
             */
            this.eccentricitySquared = 0.00669437999013;

            // Used internally to eliminate the need to create new positions for certain calculations.
            this.scratchPosition = new Position(0, 0, 0);
        };

        /**
         * Computes a Cartesian point from a specified position.
         * See this class' Overview section for a description of the Cartesian coordinate system used.
         * @param {Number} latitude The position's latitude.
         * @param {Number} longitude The position's longitude.
         * @param {Number} altitude The position's altitude.
         * @param {Vec3} result A reference to a pre-allocated {@link Vec3} instance to contain the computed X,
         * Y and Z Cartesian coordinates.
         * @returns {Vec3} The result argument.
         * @throws {ArgumentError} If the specified result is null or undefined.
         */
        Globe.prototype.computePointFromPosition = function (latitude, longitude, altitude, result) {
            if (!result) {
                throw new ArgumentError(Logger.logMessage(Logger.LEVEL_SEVERE, "Globe", "computePointFromPosition",
                    "missingResult"));
            }

            var cosLat = Math.cos(latitude * Angle.DEGREES_TO_RADIANS),
                sinLat = Math.sin(latitude * Angle.DEGREES_TO_RADIANS),
                cosLon = Math.cos(longitude * Angle.DEGREES_TO_RADIANS),
                sinLon = Math.sin(longitude * Angle.DEGREES_TO_RADIANS),
                rpm = this.equatorialRadius / Math.sqrt(1.0 - this.eccentricitySquared * sinLat * sinLat);

            result[0] = (rpm + altitude) * cosLat * sinLon;
            result[1] = (rpm * (1.0 - this.eccentricitySquared) + altitude) * sinLat;
            result[2] = (rpm + altitude) * cosLat * cosLon;

            return result;
        };

        /**
         * Computes a grid of Cartesian points within a specified sector and relative to a specified Cartesian offset.
         *
         * This method is used to compute a collection of points within a sector. It is used by tessellators to
         * efficiently generate a tile's interior points. The number of points to generate is indicated by the numLat
         * and numLon parameters, which specify respectively the number of points to generate in the latitudinal and
         * longitudinal directions. In addition to the specified numLat and numLon points, this method generates an
         * additional row and column of points along the sector's outer edges. These border points have the same
         * latitude and longitude as the points on the sector's outer edges, but use the constant borderElevation
         * instead of values from the array of elevations.
         *
         * For each implied position within the sector, an elevation value is specified via an array of elevations. The
         * calculation at each position incorporates the associated elevation. The array of elevations need not supply
         * elevations for the border points, which use the constant borderElevation.
         *
         * @param {Sector} sector The sector in which to compute the points.
         * @param {Number} numLat The number of latitudinal locations at which to compute the points.
         * @param {Number} numLon The number of longitudinal locations at which to compute the points.
         * @param {Number[]} elevations An array of elevations to incorporate in the point calculations. There must be
         * one elevation value in the array for each generated point - ignoring border points - so there must be
         * numLat x numLon elements in the array. Elevations are in meters.
         * @param {Number} borderElevation The constant elevation assigned to border points, in meters.
         * @param {Vec3} offset The X, Y and Z Cartesian coordinates to subtract from the computed coordinates. This
         * makes the computed coordinates relative to the specified offset.
         * @param {Float32Array} resultPoints A typed array to hold the computed coordinates. It must be at least of
         * size ((numLat + 2) x (numLon + 2) x stride).
         * The points are returned in row major order, beginning with the row of minimum latitude.
         * @param {Number} stride The number of floats between successive points in the output array. Specifying a
         * stride of 3 indicates that the points are tightly packed in the output array.
         * @param {Float32Array} resultElevations A typed array to hold the elevation for each computed point. This
         * elevation has vertical exaggeration applied. It must be at least of size ((numLat + 2) x (numLon + 2).
         * @returns {Float32Array} The specified resultPoints argument.
         * @throws {ArgumentError} if the specified sector, elevations array or results arrays are null or undefined, if
         * the lengths of any of the results arrays are insufficient, or if the specified stride is less than 3.
         */
        Globe.prototype.computePointsFromPositions = function (sector, numLat, numLon, elevations,
                                                               borderElevation, offset, resultPoints,
                                                               stride, resultElevations) {
            if (!sector) {
                throw new ArgumentError(Logger.logMessage(Logger.LEVEL_SEVERE, "Globe",
                    "computePointsFromPositions", "missingSector"));
            }

            if (numLat < 1 || numLon < 1) {
                throw new ArgumentError(Logger.logMessage(Logger.LEVEL_SEVERE, "Globe", "computePointsFromPositions",
                    "Number of latitude or longitude locations is less than one."));
            }

            if (!elevations || elevations.length < numLat * numLon) {
                throw new ArgumentError(Logger.logMessage(Logger.LEVEL_SEVERE, "Globe", "computePointsFromPositions",
                    "Elevations array is null, undefined or insufficient length."));
            }

            if (!resultPoints || resultPoints.length < (numLat + 2) * (numLon + 2) * stride) {
                throw new ArgumentError(Logger.logMessage(Logger.LEVEL_SEVERE, "Globe", "computePointsFromPositions",
                    "Result points array is null, undefined or insufficient length."));
            }

            if (stride < 3) {
                throw new ArgumentError(Logger.logMessage(Logger.LEVEL_SEVERE, "Globe", "computePointsFromPositions",
                    "Stride is less than 3."));
            }

            if (!resultElevations || resultElevations.length < (numLat + 2) * (numLon + 2)) {
                throw new ArgumentError(Logger.logMessage(Logger.LEVEL_SEVERE, "Globe", "computePointsFromPositions",
                    "Result elevations array is null, undefined or insufficient length."));
            }

            var minLat = sector.minLatitude * Angle.DEGREES_TO_RADIANS,
                maxLat = sector.maxLatitude * Angle.DEGREES_TO_RADIANS,
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
                rpm = this.equatorialRadius / Math.sqrt(1.0 - this.eccentricitySquared * sinLat * sinLat);

                for (i = 0; i < numLon + 2; i++) {
                    if (j == 0 || j == numLat + 1 || i == 0 || i == numLon + 1) {
                        elev = borderElevation;
                    } else {
                        elev = elevations[elevOffset];
                        ++elevOffset;
                    }
                    resultElevations[vertexOffset / stride] = elev;

                    resultPoints[vertexOffset] = (rpm + elev) * cosLat * sinLon[i] - offsetX;
                    resultPoints[vertexOffset + 1] = (rpm * (1.0 - this.eccentricitySquared) + elev) * sinLat - offsetY;
                    resultPoints[vertexOffset + 2] = (rpm + elev) * cosLat * cosLon[i] - offsetZ;
                    vertexOffset += stride;
                }
            }

            return resultPoints;
        };

        /**
         * Computes a geographic position from a specified Cartesian point.
         *
         * See this class' Overview section for a description of the Cartesian coordinate system used.
         *
         * @param {Number} x The X coordinate.
         * @param {Number} y The Y coordinate.
         * @param {Number} z The Z coordinate.
         * @param {Position} result A pre-allocated {@link Position} instance in which to return the computed position.
         * @returns {Position} The specified result position.
         * @throws {ArgumentError} If the specified result is null or undefined.
         */
        Globe.prototype.computePositionFromPoint = function (x, y, z, result) {
            if (!result) {
                throw new ArgumentError(Logger.logMessage(Logger.LEVEL_SEVERE, "Globe", "computePositionFromPoint",
                    "missingResult"));
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
                sqrtXXpYY = Math.sqrt(XXpYY),
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
                        rad3 = WWMath.cbrt((rad1 + rad2) * (rad1 + rad2));
                        u = r + 0.5 * rad3 + 2 * r * r / rad3;
                    }
                    else {
                        u = r + 0.5 * WWMath.cbrt((rad1 + rad2) * (rad1 + rad2))
                        + 0.5 * WWMath.cbrt((rad1 - rad2) * (rad1 - rad2));
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

            result.latitude = Angle.RADIANS_TO_DEGREES * phi;
            result.longitude = Angle.RADIANS_TO_DEGREES * lambda;
            result.altitude = h;

            return result;
        };

        /**
         * Computes the normal vector to this globe's surface at a specified location.
         * @param {Number} latitude The location's latitude.
         * @param {Number} longitude The location's longitude.
         * @param {Vec3} result A pre-allocated {@Link Vec3} instance in which to return the computed vector. The returned
         * normal vector is unit length.
         * @returns {Vec3} The specified result vector.  The returned normal vector is unit length.
         * @throws {ArgumentError} If the specified result is null or undefined.
         */
        Globe.prototype.surfaceNormalAtLocation = function (latitude, longitude, result) {
            if (!result) {
                throw new ArgumentError(Logger.logMessage(Logger.LEVEL_SEVERE, "Globe", "surfaceNormalAtLocation",
                    "missingResult"));
            }

            var cosLat = Math.cos(latitude * Angle.DEGREES_TO_RADIANS),
                cosLon = Math.cos(longitude * Angle.DEGREES_TO_RADIANS),
                sinLat = Math.sin(latitude * Angle.DEGREES_TO_RADIANS),
                sinLon = Math.sin(longitude * Angle.DEGREES_TO_RADIANS),
                eqSquared = this.equatorialRadius * this.equatorialRadius,
                polSquared = this.polarRadius * this.polarRadius;

            result[0] = cosLat * sinLon / eqSquared;
            result[1] = (1 - this.eccentricitySquared) * sinLat / polSquared;
            result[2] = cosLat * cosLon / eqSquared;

            return result.normalize();
        };

        /**
         * Computes the normal vector to this globe's surface at a specified Cartesian point.
         * @param {Number} x The point's X coordinate.
         * @param {Number} y The point's Y coordinate.
         * @param {Number} z The point's Z coordinate.
         * @param {Vec3} result A pre-allocated {@Link Vec3} instance in which to return the computed vector. The returned
         * normal vector is unit length.
         * @returns {Vec3} The specified result vector.
         * @throws {ArgumentError} If the specified result is null or undefined.
         */
        Globe.prototype.surfaceNormalAtPoint = function (x, y, z, result) {
            if (!result) {
                throw new ArgumentError(Logger.logMessage(Logger.LEVEL_SEVERE, "Globe", "surfaceNormalAtPoint",
                    "missingResult"));
            }

            var eSquared = this.equatorialRadius * this.equatorialRadius,
                polSquared = this.polarRadius * this.polarRadius;

            result[0] = x / eSquared;
            result[1] = y / polSquared;
            result[2] = z / eSquared;

            return result.normalize();
        };

        /**
         * Computes the north-pointing tangent vector to this globe's surface at a specified location.
         * @param {Number} latitude The location's latitude.
         * @param {Number} longitude The location's longitude.
         * @param {Vec3} result A pre-allocated {@Link Vec3} instance in which to return the computed vector. The returned
         * tangent vector is unit length.
         * @returns {Vec3} The specified result vector.
         * @throws {ArgumentError} If the specified result is null or undefined.
         */
        Globe.prototype.northTangentAtLocation = function (latitude, longitude, result) {
            if (!result) {
                throw new ArgumentError(Logger.logMessage(Logger.LEVEL_SEVERE, "Globe", "northTangentAtLocation",
                    "missingResult"));
            }

            // The north-pointing tangent is derived by rotating the vector (0, 1, 0) about the Y-axis by longitude degrees,
            // then rotating it about the X-axis by -latitude degrees. The latitude angle must be inverted because latitude
            // is a clockwise rotation about the X-axis, and standard rotation matrices assume counter-clockwise rotation.
            // The combined rotation can be represented by a combining two rotation matrices Rlat, and Rlon, then
            // transforming the vector (0, 1, 0) by the combined transform:
            //
            // NorthTangent = (Rlon * Rlat) * (0, 1, 0)
            //
            // This computation can be simplified and encoded inline by making two observations:
            // - The vector's X and Z coordinates are always 0, and its Y coordinate is always 1.
            // - Inverting the latitude rotation angle is equivalent to inverting sinLat. We know this by the
            //  trigonometric identities cos(-x) = cos(x), and sin(-x) = -sin(x).

            var cosLat = Math.cos(latitude * Angle.DEGREES_TO_RADIANS),
                cosLon = Math.cos(longitude * Angle.DEGREES_TO_RADIANS),
                sinLat = Math.sin(latitude * Angle.DEGREES_TO_RADIANS),
                sinLon = Math.sin(longitude * Angle.DEGREES_TO_RADIANS);

            result[0] = -sinLat * sinLon;
            result[1] = cosLat;
            result[2] = -sinLat * cosLon;

            return result.normalize();
        };

        /**
         * Computes the north-pointing tangent vector to this globe's surface at a specified Cartesian position.
         * @param {Number} x The point's X coordinate.
         * @param {Number} y The point's Y coordinate.
         * @param {Number} z The point's Z coordinate.
         * @param {Vec3} result A pre-allocated {@Link Vec3} instance in which to return the computed vector. The returned
         * tangent vector is unit length.
         * @returns {Vec3} The specified result vector.
         * @throws {ArgumentError} If the specified result is null or undefined.
         */
        Globe.prototype.northTangentAtPoint = function (x, y, z, result) {
            if (!result) {
                throw new ArgumentError(Logger.logMessage(Logger.LEVEL_SEVERE, "Globe", "northTangentAtPoint",
                    "missingResult"));
            }

            this.computePositionFromPoint(x, y, z, this.scratchPosition);

            return this.northTangentAtLocation(this.scratchPosition.latitude, this.scratchPosition.longitude, result);
        };

        /**
         * Computes the first intersection of this globe with a specified line. The line is interpreted as a ray;
         * intersection points behind the line's origin are ignored.
         * @param {Line} line The line to intersect with this globe.
         * @param {Vec3} result A pre-allocated Vec3 in which to return the computed point.
         * @returns {boolean} <code>true</code> If the ray intersects the globe, otherwise <code>false</code>.
         * @throws {ArgumentError} If the specified line or result is null or undefined.
         */
        Globe.prototype.intersectWithRay = function (line, result) {
            if (!line) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Globe", "intersectWithRay", "missingLine"));
            }

            if (!result) {
                throw new ArgumentError(Logger.logMessage(Logger.LEVEL_SEVERE, "Globe", "intersectWithRay", "missingResult"));
            }

            return WWMath.computeEllipsoidalGlobeIntersection(line, this.equatorialRadius, this.polarRadius, result);
        };

        /**
         * Returns the time at which any elevations associated with this globe last changed.
         * @returns {number} The time in milliseconds relative to the Epoch of the most recent elevation change.
         */
        Globe.prototype.elevationTimestamp = function () {
            return this.elevationModel.timestamp;
        };

        /**
         * Returns this globe's minimum elevation.
         * @returns {number} This globe's minimum elevation.
         */
        Globe.prototype.minElevation = function () {
            return this.elevationModel.minElevation
        };

        /**
         * Returns this globe's maximum elevation.
         * @returns {number} This globe's maximum elevation.
         */
        Globe.prototype.minElevation = function () {
            return this.elevationModel.maxElevation
        };

        /**
         * Returns the minimum and maximum elevations within a specified sector of this globe.
         * @param {Sector} sector The sector for which to determine extreme elevations.
         * @param {Number[]} result A pre-allocated array in which to return the minimum and maximum elevations.
         * @returns {Number[]} The specified result argument containing, respectively, the minimum and maximum elevations.
         * @throws {ArgumentError} If the specified sector or result array is null or undefined.
         */
        Globe.prototype.minAndMaxElevationsForSector = function (sector, result) {
            if (!sector) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Globe", "minAndMaxElevationsForSector",
                        "missingSector"));
            }

            if (!result) {
                throw new ArgumentError(Logger.logMessage(Logger.LEVEL_SEVERE, "Globe", "minAndMaxElevationsForSector",
                    "missingResult"));
            }

            return this.elevationModel.minAndMaxElevationsForSector(sector, result);
        };

        Globe.prototype.elevationAtLocation = function (latitude, longitude) {
            return this.elevationModel.elevationAtLocation(latitude, longitude);
        };

        Globe.prototype.elevationsForSector = function (sector, numLatitude, numLongitude, targetResolution,
                                                        verticalExaggeration, result) {
            if (!sector) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Globe", "elevationsForSector", "missingSector"));
            }

            if (numLatitude <= 0 || numLongitude <= 0) {
                throw new ArgumentError(Logger.logMessage(Logger.LEVEL_SEVERE, "Globe",
                    "elevationsForSector", "numLatitude or numLongitude is less than 1"));
            }

            if (!result || result.length < numLatitude * numLongitude) {
                throw new ArgumentError(Logger.logMessage(Logger.LEVEL_SEVERE, "Globe",
                    "elevationsForSector", "missingArray"));
            }

            return this.elevationModel.elevationsForSector(sector, numLatitude, numLongitude, targetResolution,
                verticalExaggeration, result);
        };

        return Globe;
    }
)
;