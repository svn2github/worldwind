/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports Terrain
 * @version $Id$
 */
define([
        '../error/ArgumentError',
        '../globe/Globe',
        '../util/Logger',
        '../geom/Sector',
        '../globe/TerrainTile',
        '../geom/Vec3'
    ],
    function (ArgumentError,
              Globe,
              Logger,
              Sector,
              TerrainTile,
              Vec3) {
        "use strict";

        /**
         * Constructs a Terrain object.
         * @alias Terrain
         * @constructor
         * @classdesc Represents terrain and provides functions for computing points on or relative to the terrain.
         */
        var Terrain = function () {

            /**
             * The globe associated with this terrain.
             * @type {Globe}
             * @default null
             */
            this.globe = null;

            /**
             * The vertical exaggeration of this terrain.
             * @type {Number}
             * @default 1
             */
            this.verticalExaggeration = 1;

            /**
             * The sector spanned by this terrain.
             * @type {Sector}
             */
            this.sector = null;
        };

        /**
         * Returns the surface geometry for this terrain.
         * @returns {TerrainTile[]} The surface geometry for this terrain, or null if there is no current surface
         * geometry for this terrain.
         */
        Terrain.prototype.surfaceGeometry = function () {
            // TODO
            throw new NotYetImplementedError(
                Logger.logMessage(Logger.LEVEL_SEVERE, "Terrain", "surfaceGeometry", "notYetImplemented"));
        };

        /**
         * Computes a Cartesian point at a location on the surface of this terrain.
         * @param {Number} latitude The location's latitude.
         * @param {Number} longitude The location's longitude.
         * @param {Number} offset Distance above the terrain, in meters, at which to compute the point.
         * @param {Vec3} result A pre-allocated Vec3 in which to return the computed point.
         * @returns {Vec3} The specified result parameter, set to the coordinates of the computed point.
         * @throws {ArgumentError} If the specified result argument is null or undefined.
         */
        Terrain.prototype.surfacePoint = function (latitude, longitude, offset, result) {
            if (!result) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Terrain", "surfacePoint", "missingResult"));
            }

            // TODO
            throw new NotYetImplementedError(
                Logger.logMessage(Logger.LEVEL_SEVERE, "Terrain", "surfacePoint", "notYetImplemented"));

            return result;
        };

        /**
         * Computes a Cartesian point at a location on the surface of this terrain according to a specified
         * altitude mode.
         * @param {Number} latitude The location's latitude.
         * @param {Number} longitude The location's longitude.
         * @param {Number} offset Distance above the terrain, in meters relative to the specified altitude mode, at
         * which to compute the point.
         * @param {String} altitudeMode The altitude mode to use to compute the point. Recognized values are
         * <code>WorldWind.ABSOLUTE</code>, <code>WorldWind.CLAMP_TO_GROUND</code> and
         * <code>WorldWind.RELATIVE_TO_GROUND</code>. The mode <code>WorldWind.ABSOLUTE</code> is used if the
         * specified mode is null, undefined or unrecognized.
         * @param {Vec3} result A pre-allocated Vec3 in which to return the computed point.
         * @returns {Vec3} The specified result parameter, set to the coordinates of the computed point.
         * @throws {ArgumentError} If the specified result argument is null or undefined.
         */
        Terrain.prototype.surfacePointForMode = function (latitude, longitude, offset, altitudeMode, result) {
            if (!result) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Terrain", "surfacePointForMode", "missingResult"));
            }

            if (!altitudeMode)
                altitudeMode = WorldWind.ABSOLUTE;

            if (altitudeMode === WorldWind.CLAMP_TO_GROUND) {
                this.surfacePoint(latitude, longitude, 0, result);
            } else if (altitudeMode === WorldWind.RELATIVE_TO_GROUND) {
                this.surfacePoint(latitude, longitude, offset, result);
            } else {
                var height = offset * this.verticalExaggeration;
                this.globe.computePointFromPosition(latitude, longitude, height, result);
            }

            return result;
        };

        return Terrain;
    });