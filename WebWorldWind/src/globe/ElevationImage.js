/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports ElevationImage
 * @version $Id$
 */
define([
        '../error/ArgumentError',
        '../util/Logger',
        '../util/WWMath'
    ],
    function (ArgumentError,
              Logger,
              WWMath) {
        "use strict";

        /**
         * Constructs an elevation image.
         * @alias ElevationImage
         * @constructor
         * @classdesc Holds elevation values for an elevation tile.
         * This class is typically not used directly by applications.
         * @param {String} imagePath A string uniquely identifying this elevation image relative to other elevation images.
         * @param {Sector} sector The sector spanned by this elevation image.
         * @param {Number} imageWidth The number of longitudinal sample points in this elevation image.
         * @param {Number} imageHeight The number of latitudinal sample points in this elevation image.
         */
        var ElevationImage = function (imagePath, sector, imageWidth, imageHeight) {
            if (!imagePath || (imagePath.length < 1)) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "ElevationImage", "constructor",
                        "The specified image path is null, undefined or zero length."));
            }

            this.sector = sector;
            this.imagePath = imagePath;
            this.imageWidth = imageWidth;
            this.imageHeight = imageHeight;
            this.size = this.imageWidth * this.imageHeight;
        };

        /**
         * Returns the elevation at a specified location.
         * @param {number} latitude The location's latitude.
         * @param {number} longitude The location's longitude.
         * @returns {Number} The elevation at the specified location.
         */
        ElevationImage.prototype.elevationAtLocation = function (latitude, longitude) {
            var maxLat = this.sector.maxLatitude,
                minLon = this.sector.minLongitude,
                deltaLat = this.sector.deltaLatitude(),
                deltaLon = this.sector.deltaLongitude(),
                x = (this.imageWidth - 1) * (longitude - minLon) / deltaLon,
                y = (this.imageHeight - 1) * (maxLat - latitude) / deltaLat,
                x0 = Math.floor(WWMath.clamp(x, 0, this.imageWidth - 1)),
                x1 = Math.floor(WWMath.clamp(x0 + 1, 0, this.imageWidth - 1)),
                y0 = Math.floor(WWMath.clamp(y, 0, this.imageHeight - 1)),
                y1 = Math.floor(WWMath.clamp(y0 + 1, 0, this.imageHeight - 1)),
                pixels = this.imageData,
                x0y0 = pixels[x0 + y0 * this.imageWidth],
                x1y0 = pixels[x1 + y0 * this.imageWidth],
                x0y1 = pixels[x0 + y1 * this.imageWidth],
                x1y1 = pixels[x1 + y1 * this.imageWidth],
                xf = x - x0,
                yf = y - y0;

            return WWMath.interpolate(yf, WWMath.interpolate(xf, x0y0, x1y0), WWMath.interpolate(xf, x0y1, x1y1));
        };

        /**
         * Returns the elevations for a specified sector.
         * @param {Sector} sector The sector for which to return the elevations.
         * @param {number} numLat The number of sample points in the longitudinal direction.
         * @param {number} numLon The number of sample points in the latitudinal direction.
         * @param {number} verticalExaggeration The vertical exaggeration to apply to the elevations.
         * @param {Number[]} result An array in which to return the computed elevations.
         * @throws {ArgumentError} If either the specified sector or result argument is null or undefined, or if the
         * specified number of sample points in either direction is less than 1.
         */
        ElevationImage.prototype.elevationsForSector = function (sector, numLat, numLon, verticalExaggeration, result) {
            if (!sector) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "ElevationImage", "elevationsForSector", "missingSector"));
            }

            if (numLat < 1 || numLon < 1) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "ElevationImage", "elevationsForSector",
                        "The specified number of sample points is less than 1."));
            }

            if (!result) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "ElevationImage", "elevationsForSector", "missingResult"));
            }

            var minLatSelf = this.sector.minLatitude,
                maxLatSelf = this.sector.maxLatitude,
                minLonSelf = this.sector.minLongitude,
                maxLonSelf = this.sector.maxLongitude,
                deltaLatSelf = maxLatSelf - minLatSelf,
                deltaLonSelf = maxLonSelf - minLonSelf,
                minLatOther = sector.minLatitude,
                maxLatOther = sector.maxLatitude,
                minLonOther = sector.minLongitude,
                maxLonOther = sector.maxLongitude,
                deltaLatOther = (maxLatOther - minLatOther) / (numLat > 1 ? numLat - 1 : 1),
                deltaLonOther = (maxLonOther - minLonOther) / (numLon > 1 ? numLon - 1 : 1),
                lat = minLatOther,
                lon = minLonOther,
                index = 0,
                pixels = this.imageData;

            for (var j = 0; j < numLat; j++) {
                // Explicitly set the first and last row to minLat and maxLat, respectively, rather than using the
                // accumulated lat value, in order to ensure that the Cartesian points of adjacent sectors match perfectly.
                if (j == 0) {
                    lat = minLatOther;
                } else if (j === numLat - 1) {
                    lat = maxLatOther;
                } else {
                    lat += deltaLatOther;
                }

                if (lat >= minLatSelf && lat <= maxLatSelf) {
                    // Image y-coordinate of the specified location, given an image origin in the top-left corner.
                    var y = (this.imageHeight - 1) * (maxLatSelf - lat) / deltaLatSelf,
                        y0 = Math.floor(WWMath.clamp(y, 0, this.imageHeight - 1)),
                        y1 = Math.floor(WWMath.clamp(y0 + 1, 0, this.imageHeight - 1)),
                        yf = y - y0;

                    for (var i = 0; i < numLon; i++) {
                        // Explicitly set the first and last row to minLon and maxLon, respectively, rather than using the
                        // accumulated lon value, in order to ensure that the Cartesian points of adjacent sectors match perfectly.
                        if (i == 0) {
                            lon = minLonOther;
                        } else if (i === numLon - 1) {
                            lon = maxLonOther;
                        } else {
                            lon += deltaLonOther;
                        }

                        if (lon >= minLonSelf && lon <= maxLonSelf) {
                            // Image x-coordinate of the specified location, given an image origin in the top-left corner.
                            var x = (this.imageWidth - 1) * (lon - minLonSelf) / deltaLonSelf,
                                x0 = Math.floor(WWMath.clamp(x, 0, this.imageWidth - 1)),
                                x1 = Math.floor(WWMath.clamp(x0 + 1, 0, this.imageWidth - 1)),
                                xf = x - x0;

                            var x0y0 = pixels[x0 + y0 * this.imageWidth],
                                x1y0 = pixels[x1 + y0 * this.imageWidth],
                                x0y1 = pixels[x0 + y1 * this.imageWidth],
                                x1y1 = pixels[x1 + y1 * this.imageWidth];

                            result[index] = WWMath.interpolate(yf,
                                WWMath.interpolate(xf, x0y0, x1y0), WWMath.interpolate(xf, x0y1, x1y1));
                            result[index] *= verticalExaggeration;
                            //if (isNaN(result[index]))
                            //    console.log(result[index]);
                        }

                        index++;
                    }
                } else {
                    index += numLon; // skip this row
                }
            }
        };

        /**
         * Returns the minimum and maximum elevations within a specified sector.
         * @param {Sector} sector The sector of interest.
         * @param {Number[]} result An array in which to return the minimum and maximum elevations, respectively,
         * within the sector.
         * @throws {ArgumentError} If either the specified sector or result argument is null or undefined.
         */
        ElevationImage.prototype.minAndMaxElevationsForSector = function (sector, result) {
            if (!sector) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "ElevationImage", "minAndMaxElevationsForSector", "missingSector"));
            }

            if (!result) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "ElevationImage", "minAndMaxElevationsForSector", "missingResult"));
            }

            if (sector.contains(this.sector)) { // The specified sector completely contains this image; return the image min and max.
                if (result[0] > this.minElevation) {
                    result[0] = this.minElevation;
                }

                if (result[1] < this.maxElevation) {
                    result[1] = this.maxElevation;
                }
            } else { // The specified sector intersects a portion of this image; compute the min and max from intersecting pixels.
                var maxLatSelf = this.sector.maxLatitude,
                    minLonSelf = this.sector.minLongitude,
                    deltaLatSelf = this.sector.deltaLatitude(),
                    deltaLonSelf = this.sector.deltaLongitude(),
                    minLatOther = sector.minLatitude,
                    maxLatOther = sector.maxLatitude,
                    minLonOther = sector.minLongitude,
                    maxLonOther = sector.maxLongitude;

                // Image coordinates of the specified sector, given an image origin in the top-left corner. We take the floor and
                // ceiling of the min and max coordinates, respectively, in order to capture all pixels that would contribute to
                // elevations computed for the specified sector in a call to elevationsForSector.
                var minY = Math.floor((this.imageHeight - 1) * (maxLatSelf - maxLatOther) / deltaLatSelf),
                    maxY = Math.ceil((this.imageHeight - 1) * (maxLatSelf - minLatOther) / deltaLatSelf),
                    minX = Math.floor((this.imageWidth - 1) * (minLonOther - minLonSelf) / deltaLonSelf),
                    maxX = Math.ceil((this.imageWidth - 1) * (maxLonOther - minLonSelf) / deltaLonSelf);

                minY = WWMath.clamp(minY, 0, this.imageHeight - 1);
                maxY = WWMath.clamp(maxY, 0, this.imageHeight - 1);
                minX = WWMath.clamp(minX, 0, this.imageWidth - 1);
                maxX = WWMath.clamp(maxX, 0, this.imageWidth - 1);

                var pixels = this.imageData,
                    min = Number.MAX_VALUE,
                    max = -min;

                for (var y = minY; y <= maxY; y++) {
                    for (var x = minX; x <= maxX; x++) {
                        var p = pixels[Math.floor(x + y * this.imageWidth)];
                        if (min > p) {
                            min = p;
                        }

                        if (max < p) {
                            max = p;
                        }
                    }
                }

                if (result[0] > min) {
                    result[0] = min;
                }

                if (result[1] < max) {
                    result[1] = max;
                }
            }
        };

        /**
         * Determines the minimum and maximum elevation within this elevation image and stores those values within
         * this object.
         */
        ElevationImage.prototype.findMinAndMaxElevation = function () {
            if (this.imageData && (this.imageData.length > 0)) {
                this.minElevation = Number.MAX_VALUE;
                this.maxElevation = -this.minElevation;

                var pixels = this.imageData,
                    pixelCount = this.imageWidth * this.imageHeight;

                for (var i = 0; i < pixelCount; i++) {
                    var p = pixels[i];

                    if (this.minElevation > p) {
                        this.minElevation = p;
                    }

                    if (this.maxElevation < p) {
                        this.maxElevation = p;
                    }
                }
            } else {
                this.minElevation = 0;
                this.maxElevation = 0;
            }
        };

        return ElevationImage;
    });