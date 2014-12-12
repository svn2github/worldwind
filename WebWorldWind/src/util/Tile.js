/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports Tile
 * @version $Id$
 */
define([
        '../error/ArgumentError',
        '../geom/BoundingBox',
        '../render/DrawContext',
        '../util/Level',
        '../util/Logger',
        '../cache/MemoryCache',
        '../error/NotYetImplementedError',
        '../geom/Sector',
        '../util/TileFactory',
        '../geom/Vec3',
        '../util/WWMath'
    ],
    function (ArgumentError,
              BoundingBox,
              DrawContext,
              Level,
              Logger,
              MemoryCache,
              NotYetImplementedError,
              Sector,
              TileFactory,
              Vec3,
              WWMath) {
        "use strict";

        /**
         * Constructs a tile for a specified sector, level, row and column.
         * @alias Tile
         * @constructor
         * @classdesc Represents a tile of terrain or imagery.
         * Provides a base class for texture tiles used by tiled image layers and elevation tiles used by elevation models.
         * Applications typically do not interact with this class.
         * @param {Sector} sector The sector represented by the tile.
         * @param {Level} level The tile's level in a tile pyramid.
         * @param {Number} row The tile's row in the specified level in a tile pyramid.
         * @param {Number} column The tile's column in the specified level in a tile pyramid.
         * @throws {ArgumentError} If the specified sector or level is null or undefined or the row or column arguments
         * are less than zero.
         */
        var Tile = function (sector, level, row, column) {
            if (!sector) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Tile", "constructor", "missingSector"));
            }

            if (!level) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Tile", "constructor",
                        "The specified level is null or undefined."));
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
            this.level = level;

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
            this.tileWidth = level.tileWidth;

            /**
             * The height in pixels or cells of this tile's associated resource.
             * @type {Number}
             */
            this.tileHeight = level.tileHeight;

            /**
             * The size in radians of pixels or cells of this tile's associated resource.
             * @type {Number}
             */
            this.texelSize = 0;

            this.extentTimestamp = undefined;
            this.extentVerticalExaggeration = undefined;
        };

        /**
         * Indicates whether this tile is equivalent to a specified tile.
         * @param {Tile} that The tile to check equivalence with.
         * @returns {boolean} <code>true</code> if this tile is equivalent to the specified one, <code>false</code> if
         * they are not equivalent or the specified tile is null or undefined.
         */
        Tile.prototype.isEqual = function (that) {
            // TODO
            throw new NotYetImplementedError(
                Logger.logMessage(Logger.LEVEL_SEVERE, "Tile", "isEqual", "notYetImplemented"));

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
            throw new NotYetImplementedError(
                Logger.logMessage(Logger.LEVEL_SEVERE, "Tile", "hash", "notYetImplemented"));

            return 0;
        };

        /**
         * Returns the four children formed by subdividing this tile.
         * @param {Level} level The level of the children.
         * @param {TileFactory} tileFactory The tile factory to use to create the children.
         * @param {Tile[]} result A pre-allocated array in which to return the results.
         * @returns {Tile[]} The specified result array containing the four tiles.
         * @throws {ArgumentError} if the specified tile factory or level is null or undefined or the specified result
         * array is null or undefined.
         */
        Tile.prototype.subdivide = function (level, tileFactory, result) {
            if (!level) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Tile", "subdivide",
                        "The specified level is null or undefined."));
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

            var nextLevel = level.nextLevel(),
                latMin = this.sector.minLatitude,
                latMax = this.sector.maxLatitude,
                latMid = this.sector.centroidLat,

                lonMin = this.sector.minLongitude,
                lonMax = this.sector.maxLongitude,
                lonMid = this.sector.centroidLon,

                subRow,
                subCol,
                childSector;

            subRow = 2 * this.row;
            subCol = 2 * this.column;
            childSector = new Sector(latMin, latMid, lonMin, lonMid);
            result.push(tileFactory.createTile(childSector, nextLevel, subRow, subCol));

            subRow = 2 * this.row;
            subCol = 2 * this.column + 1;
            childSector = new Sector(latMin, latMid, lonMid,lonMax);
            result.push(tileFactory.createTile(childSector, nextLevel, subRow, subCol));

            subRow = 2 * this.row + 1;
            subCol = 2 * this.column;
            childSector = new Sector(latMid, latMax, lonMin, lonMid);
            result.push(tileFactory.createTile(childSector, nextLevel, subRow, subCol));

            subRow = 2 * this.row + 1;
            subCol = 2 * this.column + 1;
            childSector = new Sector(latMid, latMax, lonMid, lonMax);
            result.push(tileFactory.createTile(childSector, nextLevel, subRow, subCol));

            return result;
        };

        /**
         * Returns the four children formed by subdividing this tile, drawing those children from a specified cache
         * if they exist.
         * @param {Level} level The level of the children.
         * @param {TileFactory} tileFactory The tile factory to use to create the children.
         * @param {MemoryCache} cache A memory cache that may contain pre-existing tiles for one or more of the
         * child tiles. If non-null, the cache is checked for a child tile prior to creating that tile. If one exists
         * in the cache it is returned rather than creating a new tile.
         * @returns {Tile[]} An array containing the four tiles.
         * @throws {ArgumentError} if the specified tile factory or level is null or undefined.
         */
        Tile.prototype.subdivideToCache = function (level, tileFactory, cache) {
            if (!level) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Tile", "subdivideToCache",
                        "The specified level is null or undefined."));
            }

            if (!tileFactory) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Tile", "subdivideToCache",
                        "The specified tile factory is null or undefined."));
            }

            // TODO
            throw new NotYetImplementedError(
                Logger.logMessage(Logger.LEVEL_SEVERE, "Tile", "subdivideToCache", "notYetImplemented"));

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
            var globe = dc.globe,
                eyePos = dc.eyePosition;

            // Compute the point on the tile that is nearest to the eye point. Use the minimum elevation because it provides a
            // reasonable estimate for distance, and the eye point always gets closer to the point as it moves closer to the
            // terrain surface.
            var nearestLat = WWMath.clamp(eyePos.latitude, this.sector.minLatitude, this.sector.maxLatitude),
                nearestLon = WWMath.clamp(eyePos.longitude, this.sector.minLongitude, this.sector.maxLongitude),
                minHeight = this.minElevation * dc.verticalExaggeration;

            var nearestPoint = new Vec3();
            globe.computePointFromPosition(nearestLat, nearestLon, minHeight, nearestPoint);

            // Compute the cell size and distance to the nearest point on the tile. Cell size is radius * radian texel size.
            var cellSize = Math.max(globe.equatorialRadius, globe.polarRadius) * this.texelSize,
                distance = nearestPoint.distanceTo(dc.navigatorState.eyePoint);

            // Split when the cell height (length of a texel) becomes greater than the specified fraction of the eye distance.
            // The fraction is specified as a power of 10. For example, a detail factor of 3 means split when the cell height
            // becomes more than one thousandth of the eye distance. Another way to say it is, use the current tile if the cell
            // height is less than the specified fraction of the eye distance.
            //
            // Note: It's tempting to instead compare a screen pixel size to the texel size, but that calculation is window-
            // size dependent and results in selecting an excessive number of tiles when the window is large.

            return cellSize > distance * Math.pow(10, -detailFactor);
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
            var globe = dc.globe,
                elevationTimestamp = globe.elevationTimestamp(),
                verticalExaggeration = dc.verticalExaggeration;

            if (!this.extentTimestamp ||
                this.extentTimestamp != elevationTimestamp ||
                !this.extentVerticalExaggeration ||
                this.extentVerticalExaggeration != verticalExaggeration) {
                // Compute the minimum and maximum elevations for this tile's sector, or use zero if the globe has no elevations
                // in this tile's coverage area. In the latter case the globe does not modify the result parameter.
                var extremes = [0, 0];
                globe.minAndMaxElevationsForSector(this.sector, extremes);
                var minElevation = extremes[0],
                    maxElevation = extremes[1];

                // Multiply the minimum and maximum elevations by the scene's vertical exaggeration. This ensures that the
                // elevations to used build the terrain are contained by this tile's extent.
                var minHeight = this.minElevation * verticalExaggeration,
                    maxHeight = this.maxElevation * verticalExaggeration;
                if (minHeight == maxHeight) {
                    minHeight = maxHeight + 10; // TODO: Determine if this is necessary.
                }

                // Compute a bounding box for this tile that contains the terrain surface in the tile's coverage area.
                if (!this.extent) {
                    this.extent = new BoundingBox();
                }
                this.extent.setToSector(this.sector, globe, minHeight, maxHeight);

                // Compute the reference point used as a local coordinate origin for the tile.
                if (!this.referencePoint) {
                    this.referencePoint = new Vec3(0, 0, 0);
                }
                globe.computePointFromPosition(this.sector.centroidLatitude(), this.sector.centroidLongitude(), minHeight, this.referencePoint);

                // Set the geometry extent to the globe's elevation timestamp on which the geometry is based. This ensures that
                // the geometry timestamp can be reliably compared to the elevation timestamp in subsequent frames.
                this.extentTimestamp = elevationTimestamp;
                this.extentVerticalExaggeration = verticalExaggeration;

                dc.frameStatistics.incrementTileUpdateCount(1);
            }
        };

        /**
         * Computes a row number for a tile within a level given the tile's latitude.
         * @param {Number} delta The level's latitudinal tile delta in degrees.
         * @param {Number} latitude The tile's minimum latitude.
         * @returns {Number} The computed row number.
         */
        Tile.computeRow = function (delta, latitude) {
            var row = Math.floor((latitude + 90) / delta);

            // If latitude is at the end of the grid, subtract 1 from the computed row to return the last row.
            if (latitude == 90)
            {
                row -= 1;
            }

            return row;
        };

        /**
         * Computes a column number for a tile within a level given the tile's longitude.
         * @param {Number} delta The level's longitudinal tile delta in degrees.
         * @param {Number} longitude The tile's minimum longitude.
         * @returns {Number} The computed column number.
         */
        Tile.computeColumn = function (delta, longitude) {
            var col = Math.floor((longitude + 180) / delta);

            // If longitude is at the end of the grid, subtract 1 from the computed column to return the last column.
            if (longitude == 180)
            {
                col -= 1;
            }

            return col;
        };

        /**
         * Computes the last row number for a tile within a level given the tile's maximum latitude.
         * @param {Number} delta The level's latitudinal tile delta in degrees.
         * @param {Number} maxLatitude The tile's maximum latitude in degrees.
         * @returns {Number} The computed row number.
         */
        Tile.computeLastRow = function (delta, maxLatitude) {
            var row = Math.ceil((maxLatitude + 90) / delta - 1);

            // If max latitude is in the first row, set the max row to 0.
            if (maxLatitude + 90 < delta)
            {
                row = 0;
            }

            return row;
        };

        /**
         * Computes the last column number for a tile within a level given the tile's maximum longitude.
         * @param {Number} delta The level's longitudinal tile delta in degrees.
         * @param {Number} maxLongitude The tile's maximum longitude in degrees.
         * @returns {Number} The computed column number.
         */
        Tile.computeLastColumn = function (delta, maxLongitude) {
            var col = Math.ceil((maxLongitude + 180) / delta - 1);

            // If max longitude is in the first column, set the max column to 0.
            if (maxLongitude + 180 < delta)
            {
                col = 0;
            }

            return col;
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

            var deltaLat = level.tileDelta.latitude,
                deltaLon = level.tileDelta.longitude,

                minLat = -90 + row * deltaLat,
                minLon = -180 + column * deltaLon,
                maxLat = minLat + deltaLat,
                maxLon = minLon + deltaLon;

            return new Sector(minLat, maxLat, minLon, maxLon);
        };

        /**
         * Create all tiles for a specified level number.
         * @param {Level} level The level to create the tiles for.
         * @param {TileFactory} tileFactory The tile factory to use for creating tiles.
         * @param {Tile[]} result A pre-allocated array in which to return the results.
         * @throws {ArgumentError} If any argument is null or undefined.
         */
        Tile.createTilesForLevel = function (level, tileFactory, result) {
            if (!level) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Tile", "createTilesForLevel",
                        "The specified level is null or undefined."));
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

            var deltaLat = level.tileDelta.latitude,
                deltaLon = level.tileDelta.longitude,

                sector = level.sector,
                firstRow = Tile.computeRow(deltaLat, sector.minLatitude),
                lastRow = Tile.computeRow(deltaLat, sector.maxLatitude),

                firstCol = Tile.computeColumn(deltaLon, sector.minLongitude),
                lastCol = Tile.computeColumn(deltaLon, sector.maxLongitude),

                firstRowLat = -90 + firstRow * deltaLat,
                firstRowLon = -180 + firstCol * deltaLon,

                minLat = firstRowLat,
                minLon,
                maxLat,
                maxLon;

            for (var row = firstRow; row <= lastRow; row += 1) {
                maxLat = minLat + deltaLat;
                minLon = firstRowLon;

                for (var col = firstCol; col <= lastCol; col += 1) {
                    maxLon = minLon + deltaLon;
                    var tileSector = new Sector(minLat,
                        maxLat,
                        minLon,
                        maxLon),
                        tile = tileFactory.createTile(tileSector, level, row, col);
                    result.push(tile);

                    minLon = maxLon;
                }

                minLat = maxLat;
            }
        };

        return Tile;
    });