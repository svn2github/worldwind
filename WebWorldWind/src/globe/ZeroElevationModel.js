/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @version $Id$
 */
define([
        'src/error/ArgumentError',
        'src/util/Logger',
        'src/geom/Sector'],
    function (ArgumentError,
              Logger,
              Sector) {
        "use strict";

        /**
         * Constructs a Zero elevation model whose elevations are zero at every location.
         * @alias ZeroElevationModel
         * @constructor
         * @classdesc Represents an elevation model whose elevations are zero at all locations.
         */
        var ZeroElevationModel = function () {
            /**
             * Indicates this elevation model's display name.
             * @type {string}
             * @default "Zero Elevations"
             */
            this.displayName = "Zero Elevations";

            /**
             * Indicates the last time this elevation model changed. Since a zero elevation model never changes, this
             * property always returns the date and time at which the elevation model was constructed, in milliseconds
             * since midnight Jan 1, 1970.
             * @type {number}
             * @constant
             * @default Date.getTime() at construction
             */
            this.timestamp = new Date().getTime();

            /**
             * This elevation model's minimum elevation, which is always zero.
             * @type {number}
             * @constant
             * @default 0
             */
            this.minimumElevation = 0;

            /**
             * This elevation model's maximum elevation, which is always zero.
             * @type {number}
             */
            this.maximumElevation = 0;
        }

        /**
         * Returns the minimum and maximum elevations at a specified location.
         * @param {Number} latitude The location's latitude in degrees.
         * @param {Number} longitude The location's longitude in degrees.
         * @returns {Number[]} A two-element array containing, respectively, the minimum and maximum elevations at the
         * specified location.
         */
        ZeroElevationModel.prototype.getExtremeElevationsAtLocation = function (latitude, longitude) {
            return [0, 0];
        };

        /**
         * Returns the minimum and maximum elevations within a specified sector.
         * @param {Sector} sector The sector for which to determine extreme elevations.
         * @returns {Number[]} A two-element array containing, respectively, the minimum and maximum elevations within
         * the specified sector.
         * @throws {ArgumentError} If the specified sector is null or undefined.
         */
        ZeroElevationModel.prototype.getExtremeElevationsForSector = function (sector) {
            if (!(sector instanceof Sector)) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "ZeroElevationModel", "getExtremeElevationsForSector",
                        "missingSector"));
            }

            return [0, 0];
        };

        /**
         * Returns the elevation at a specified location.
         * @param {Number} latitude The location's latitude in degrees.
         * @param {Number} longitude The location's longitude in degrees.
         * @returns {Number} The elevation at the specified location.
         */
        ZeroElevationModel.prototype.getElevationAtLocation = function (latitude, longitude) {
            return 0;
        };

        /**
         * Returns the elevations at locations within a specified sector.
         * @param {Sector} sector The sector for which to determine the elevations.
         * @param {Number} numLatitude The number of latitudinal sample locations within the sector.
         * @param {Number} numLongitude The number of longitudinal sample locations within the sector.
         * @param {Number} targetResolution The desired elevation resolution.
         * @param {Number} verticalExaggeration The vertical exaggeration to apply to the elevations.
         * @param {Number[]} result An array of size numLatitude x numLongitude to contain the requested elevations.
         * This array must be allocated when passed to this function.
         * @returns {Number} The resolution actually achieved, which may be greater than that requested if the
         * elevation data for the requested resolution is not currently available.
         * @throws {ArgumentError} If the specified sector or result array is null or undefined, if either of the
         * specified numLatitude or numLongitude values is less than 1, or the result array is not of sufficient length
         * to hold numLatitude x numLongitude values.
         */
        ZeroElevationModel.prototype.getElevationsForSector = function (sector, numLatitude, numLongitude,
                                                                        targetResolution, verticalExaggeration,
                                                                        result) {
            var msg;

            if (!(sector instanceof Sector)) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "ZeroElevationModel", "getElevationsForSector", "missingSector"));
            }

            if (numLatitude <= 0 || numLongitude <= 0) {
                throw new ArgumentError(Logger.logMessage(Logger.LEVEL_SEVERE, "ZeroElevationModel",
                    "getElevationsForSector", "numLatitude or numLongitude is less than 1"));
            }

            if (!(result instanceof Array) || result.length < numLatitude * numLongitude) {
                throw new ArgumentError(Logger.logMessage(Logger.LEVEL_SEVERE, "ZeroElevationModel",
                    "getElevationsForSector", "missingArray"));
            }

            for (var i = 0, len = locations.length; i < len; i++) {
                result[i] = 0;
            }

            return 0;
        };

        return ZeroElevationModel;
    });