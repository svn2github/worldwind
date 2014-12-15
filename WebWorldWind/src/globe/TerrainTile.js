/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports TerrainTile
 * @version $Id$
 */
define([
        '../error/ArgumentError',
        '../globe/Globe',
        '../util/Level',
        '../util/Logger',
        '../geom/Matrix',
        '../error/NotYetImplementedError',
        '../geom/Sector',
        '../util/Tile',
        '../geom/Vec3'
    ],
    function (ArgumentError,
              Globe,
              Level,
              Logger,
              Matrix,
              NotYetImplementedError,
              Sector,
              Tile,
              Vec3) {
        "use strict";

        /**
         * Constructs a terrain tile.
         * @alias TerrainTile
         * @constructor
         * @classdesc Represents a portion of a globe's terrain.
         * @param {Sector} sector The sector this tile covers.
         * @param {Level} level The level this tile is associated with.
         * @param {Number} row This tile's row in the associated level.
         * @param {Number} column This tile's column in the associated level.
         *
         */
        var TerrainTile = function (sector, level, row, column) {
            Tile.call(this, sector, level, row, column); // args are checked in the superclass' constructor

            /**
             * The transformation matrix that maps tile local coordinates to model coordinates.
             * @type {Matrix}
             */
            this.transformationMatrix = Matrix.fromIdentity();

            /**
             * The number of model coordinate points this tile contains.
             * @type {number}
             */
            this.numPoints = 0;

            /**
             * The tile's model coordinate points.
             * @type {null}
             */
            this.points = null;

            /**
             * The elevations corresponding to the tile's model coordinate points.
             * @type {null}
             */
            this.elevations = null;

            /**
             * Indicates the date and time at which this tile's terrain geometry was computed.
             * This is used to invalidate the terrain geometry when the globe's elevations change.
             * @type {number}
             */
            this.geometryTimestamp = 0;

            /**
             * Indicates the date and time at which this tile's terrain geometry VBO was loaded.
             * This is used to invalidate the terrain geometry when the globe's elevations change.
             * @type {number}
             */
            this.geometryVboTimestamp = 0;

            /**
             * The GPU resource cache ID for this tile's model coordinates VBO.
             * @type {null}
             */
            this.geometryVboCacheKey = level.levelNumber.toString() + "." + row.toString() + "." + column.toString();
        };

        TerrainTile.prototype = Object.create(Tile.prototype);

        /**
         * Computes a point on the terrain at a specified location.
         * @param {Number} latitude The location's latitude.
         * @param {Number} longitude The location's longitude.
         * @param {Number} offset An distance in meters from the terrain surface at which to place the point. The
         * computed point is located this distance along the normal vector to the globe at the specified location.
         * @param {Vec3} result A pre-allocated Vec3 in which to return the computed point.
         * @returns {Vec3} The result argument set to the computed point.
         * @throws {ArgumentError} If the specified result is null or undefined.
         */
        TerrainTile.prototype.surfacePoint = function (latitude, longitude, offset, result) {
            if (!result) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "TerrainTile", "surfacePoint", "missingResult"));
            }

            // TODO
            throw new NotYetImplementedError(
                Logger.logMessage(Logger.LEVEL_SEVERE, "TerrainTile", "surfacePoint", "notYetImplemented"));
        };

        return TerrainTile;
    });