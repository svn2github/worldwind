/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports Tile
 * @version $Id$
 */
define([
        'src/error/ArgumentError',
        'src/geom/BoundingBox',
        'src/render/DrawContext',
        'src/util/Logger',
        'src/cache/MemoryCache',
        'src/geom/Sector',
        'src/util/TileFactory',
        'src/geom/Vec3'
    ],
    function (ArgumentError,
              BoundingBox,
              DrawContext,
              Logger,
              MemoryCache,
              Sector,
              TileFactory,
              Vec3) {
        "use strict";

        /**
         * Constructs a tile for a specified sector, level, row and column.
         * @alias Tile
         * @constructor
         * @classdesc Represents a tile of terrain or imagery.
         * Provides a base class for texture tiles used by tiled image layers and elevation tiles used by elevation models.
         * Applications typically do not interact with this class.
         * @param {Sector} sector The sector represented by the tile.
         * @param {Number} levelNumber The tile's level in a tile pyramid.
         * @param {Number} row The tile's row in the specified level in a tile pyramid.
         * @param {Number} column The tile's column in the specified level in a tile pyramid.
         * @throws {ArgumentError} If the specified sector is null or undefined or the level, row or column arguments
         * are less than zero.
         */
        var Tile = function (sector, levelNumber, row, column) {
            if (!sector) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Tile", "constructor", "missingSector"));
            }

            if (levelNumber < 0) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Tile", "constructor",
                        "The specified level number is less than zero."));
            }

            if (row < 0 || column < 0) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Tile", "constructor",
                        "The specified row or column is less than zero."));
            }

            /**
             * The sector represented by this tile.
             * @type {Sector}
             */
            this.sector = sector;

            /**
             * The level at which this tile lies in a tile pyramid.
             * @type {Number}
             */
            this.levelNumber = levelNumber;

            /**
             * The row in this tile's level in which this tile lies in a tile pyramid.
             * @type {Number}
             */
            this.row = row;

            /**
             * The column in this tile's level in which this tile lies in a tile pyramid.
             * @type {Number}
             */
            this.column = column;

            /**
             * The Cartesian bounding box of this tile.
             * @type {BoundingBox}
             */
            this.extent = null;

            /**
             * The tile's local origin in model coordinates. Any model coordinate points associates with the tile
             * should be relative to this point.
             * @type {Vec3}
             */
            this.referencePoint = null;

            /**
             * The minimum elevation within the tile's sector.
             * @type {Number}
             */
            this.minElevation = 0;

            /**
             * The maximum elevation within the tile's sector.
             * @type {Number}
             */
            this.maxElevation = 0;

            /**
             * The width in pixels or cells of this tile's associated resource.
             * @type {Number}
             */
            this.tileWidth = 0;

            /**
             * The height in pixels or cells of this tile's associated resource.
             * @type {Number}
             */
            this.tileHeight = 0;

            /**
             * The size in radians of pixels or cells of this tile's associated resource.
             * @type {Number}
             */
            this.texelSize = 0;
        };

        /**
         * Indicates whether this tile is equivalent to a specified tile.
         * @param {Tile} that The tile to check equivalence with.
         * @returns {boolean} <code>true</code> if this tile is equivalent to the specified one, <code>false</code> if
         * they are not equivalent or the specified tile is null or undefined.
         */
        Tile.prototype.isEqual = function (that) {
            // TODO

            return false;
        };

        /**
         * Computes a hash value for this tile.
         * <p>
         * If two tiles are considered equivalent then their hash values are identical.
         * @returns {Number} The computed hash value.
         */
        Tile.prototype.hash = function () {
            // TODO

            return 0;
        };

        /**
         * Returns the four children formed by subdividing this tile.
         * @param {Number} levelNumber The level of the children.
         * @param {TileFactory} tileFactory The tile factory to use to create the children.
         * @param {Tile[]} result A pre-allocated array in which to return the results.
         * @returns {Tile[]} The specified result array containing the four tiles.
         * @throws {ArgumentError} if the specified tile factory is null or undefined, the specified level number is
         * negative or the specified result array is null or undefined.
         */
        Tile.prototype.subdivide = function (levelNumber, tileFactory, result) {
            if (levelNumber < 0) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Tile", "subdivide",
                        "The specified level number is less than zero."));
            }

            if (!tileFactory) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Tile", "subdivide",
                        "The specified tile factory is null or undefined."));
            }

            if (!result) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Tile", "subdivide", "missingResult"));
            }

            // TODO

            return result;
        };

        /**
         * Returns the four children formed by subdividing this tile, drawing those children from a specified cache
         * if they exist.
         * @param {Number} levelNumber The level of the children.
         * @param {TileFactory} tileFactory The tile factory to use to create the children.
         * @param {MemoryCache} cache A memory cache that may contain pre-existing tiles for one or more of the
         * child tiles. If non-null, the cache is checked for a child tile prior to creating that tile. If one exists
         * in the cache it is returned rather than creating a new tile.
         * @returns {Tile[]} An array containing the four tiles.
         * @throws {ArgumentError} if the specified tile factory is null or undefined or the specified level number is
         * negative.
         */
        Tile.prototype.subdivideToCache = function (levelNumber, tileFactory, cache) {
            if (levelNumber < 0) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Tile", "subdivideToCache",
                        "The specified level number is less than zero."));
            }

            if (!tileFactory) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Tile", "subdivideToCache",
                        "The specified tile factory is null or undefined."));
            }

            // TODO

            return null;
        };

        /**
         * Indicates whether this tile should be subdivided based on the current navigation state and a specified
         * detail factor.
         * @param {DrawContext} dc The current draw context.
         * @param {Number} detailFactor The detail factor to consider.
         * @returns {boolean} <code>true</code> if the tile should be subdivided, otherwise <code>false</code>.
         */
        Tile.prototype.mustSubdivide = function (dc, detailFactor) {
            // TODO

            return false;
        };

        /**
         * Updates this tile's frame-dependent properties according to the specified draw context.
         * <p>
         * The tile's frame-dependent properties include the extent (bounding volume), referencePoint, minElevation and
         * maxElevation. These properties are dependent on the tile's sector and the elevation values currently in memory, and
         * change when the globe's elevations change or when the scene's vertical exaggeration changes. Therefore <code>update</code>
         * must be called once per frame before these properties are used. <code>update</code> intelligently determines when it is
         * necessary to recompute these properties, and does nothing if the elevations or the vertical exaggeration have not
         * changed since the last call.
         * @param {DrawContext} dc The current draw context.
         */
        Tile.prototype.update = function (dc) {
            // TODO
        };

        /**
         * Computes a row number for a tile within a level given the tile's latitude.
         * @param {Number} delta The level's latitudinal tile delta in degrees.
         * @param {Number} latitude The tile's minimum latitude.
         * @returns {Number} The computed row number.
         */
        Tile.computeRow = function (delta, latitude) {
            // TODO

            return 0;
        };

        /**
         * Computes a column number for a tile within a level given the tile's longitude.
         * @param {Number} delta The level's longitudinal tile delta in degrees.
         * @param {Number} longitude The tile's minimum longitude.
         * @returns {Number} The computed column number.
         */
        Tile.computeColumn = function (delta, longitude) {
            // TODO

            return 0;
        };

        /**
         * Computes the last row number for a tile within a level given the tile's maximum latitude.
         * @param {Number} delta The level's latitudinal tile delta in degrees.
         * @param {Number} maxLatitude The tile's maximum latitude in degrees.
         * @returns {Number} The computed row number.
         */
        Tile.computeLastRow = function (delta, maxLatitude) {
            // TODO

            return 0;
        };

        /**
         * Computes the last column number for a tile within a level given the tile's maximum longitude.
         * @param {Number} delta The level's longitudinal tile delta in degrees.
         * @param {Number} maxLongitude The tile's maximum longitude in degrees.
         * @returns {Number} The computed column number.
         */
        Tile.computeLastColumn = function (delta, maxLongitude) {
            // TODO

            return 0;
        };

        /**
         * Computes a sector spanned by a tile with the specified level number, row and column.
         * @param {Number} levelNumber The tile's level number.
         * @param {Number} row The tile's row number.
         * @param {Number} column The tile's column number.
         * @returns {Sector} The sector spanned by the tile.
         * @throws {ArgumentError} if any argument is less than zero.
         */
        Tile.computeSector = function (levelNumber, row, column) {
            if (levelNumber < 0) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Tile", "computeSector",
                        "The specified level number is less than zero."));
            }

            if (row < 0 || column < 0) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Tile", "computeSector",
                        "The specified row or column is less than zero."));
            }

            // TODO

            return Sector.ZERO;
        };

        /**
         * Create all tiles for a specified level number.
         * @param {Number} levelNumber The level to create the tiles for.
         * @param {TileFactory} tileFactory The tile factory to use for creating tiles.
         * @param {Tile[]} result A pre-allocated array in which to return the results.
         * @throws {ArgumentError} If the level number is less than zero, the tile factory is null or undefined, or the
         * result array is null or undefined.
         */
        Tile.createTilesForLevel = function (levelNumber, tileFactory, result) {
            if (levelNumber < 0) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Tile", "createTilesForLevel",
                        "The specified level number is less than zero."));
            }

            if (!tileFactory) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Tile", "createTilesForLevel",
                        "The specified tile factory is null or undefined"));
            }

            if (!result) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Tile", "createTilesForLevel", "missingResult"));
            }

            // TODO
        };

        return Tile;
    });