/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports ElevationModel
 * @version $Id$
 */
define([
        '../error/ArgumentError',
        '../util/Logger',
        '../geom/Sector',
        '../error/UnsupportedOperationError'],
    function (ArgumentError,
              Logger,
              Sector,
              UnsupportedOperationError) {
        "use strict";

        /**
         * Constructs an elevation model. This type is abstract and is not expected to be instantiated directly.
         * @alias ElevationModel
         * @constructor
         * @classdesc Represents an elevation model.
         */
        var ElevationModel = function () {
            /**
             * Indicates this elevation model's display name.
             * @type {string}
             * @default "Elevations"
             */
            this.displayName = "Elevations";

            /**
             * Indicates the last time this elevation model changed, in milliseconds since midnight Jan 1, 1970.
             * @type {number}
             * @default Date.getTime() at construction
             */
            this.timestamp = new Date().getTime();

            /**
             * This elevation model's minimum elevation
             * @type {number}
             * @default 0
             */
            this.minElevation = 0;

            /**
             * This elevation model's maximum elevation.
             * @type {number}
             */
            this.maxElevation = 0;
        };

        /**
         * Returns the minimum and maximum elevations at a specified location.
         * @param {Number} latitude The location's latitude in degrees.
         * @param {Number} longitude The location's longitude in degrees.
         * @param {Number[]} result A pre-allocated two-element array in which to return the minimum and maximum elevations.
         * @returns {Number[]} The specified result argument containing, respectively, the minimum and maximum elevations.
         * @throws {ArgumentError} If the specified result array is null or undefined.
         */
        ElevationModel.prototype.minAndMaxElevationsAtLocation = function (latitude, longitude, result) {
            throw new UnsupportedOperationError(
                Logger.logMessage(Logger.LEVEL_SEVERE, "ElevationModel", "minAndMaxElevationsAtLocation", "abstractInvocation"));
        };

        /**
         * Returns the minimum and maximum elevations within a specified sector.
         * @param {Sector} sector The sector for which to determine extreme elevations.
         * @returns {Number[]} A two-element array containing, respectively, the minimum and maximum elevations within
         * the specified sector.
         * @throws {ArgumentError} If the specified sector or result array is null or undefined.
         */
        ElevationModel.prototype.minAndMaxElevationsForSector = function (sector, result) {
            throw new UnsupportedOperationError(
                Logger.logMessage(Logger.LEVEL_SEVERE, "ElevationModel", "minAndMaxElevationsForSector", "abstractInvocation"));
        };

        /**
         * Returns the elevation at a specified location.
         * @param {Number} latitude The location's latitude in degrees.
         * @param {Number} longitude The location's longitude in degrees.
         * @returns {Number} The elevation at the specified location.
         */
        ElevationModel.prototype.elevationAtLocation = function (latitude, longitude) {
            throw new UnsupportedOperationError(
                Logger.logMessage(Logger.LEVEL_SEVERE, "ElevationModel", "elevationAtLocation", "abstractInvocation"));
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
        ElevationModel.prototype.elevationsForSector = function (sector, numLatitude, numLongitude,
                                                                 targetResolution, verticalExaggeration,
                                                                 result) {
            throw new UnsupportedOperationError(
                Logger.logMessage(Logger.LEVEL_SEVERE, "ElevationModel", "elevationsForSector", "abstractInvocation"));
        };

        return ElevationModel;

    });