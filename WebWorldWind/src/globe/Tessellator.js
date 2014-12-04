/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports Tessellator
 * @version $Id$
 */
define([
        '../error/ArgumentError',
        '../globe/Globe',
        '../util/LevelSet',
        '../geom/Location',
        '../util/Logger',
        '../navigate/NavigatorState',
        '../error/NotYetImplementedError',
        '../geom/Sector',
        '../globe/Terrain',
        '../globe/TerrainTile',
        '../globe/TerrainTileList',
        '../util/Tile',
        '../util/TileFactory'
    ],
    function (ArgumentError,
              Globe,
              LevelSet,
              Location,
              Logger,
              NavigatorState,
              NotYetImplementedError,
              Sector,
              Terrain,
              TerrainTile,
              TerrainTileList,
              Tile,
              TileFactory) {
        "use strict";

        /**
         * Constructs a Tessellator object for a specified globe.
         * @alias Tessellator
         * @constructor
         * @classdesc Represents a tessellator for a specified globe.
         */
        var Tessellator = function () {
            this.levels = new LevelSet(Sector.FULL_SPHERE, new Location(45, 45), 15, 32, 32);

            this.topLevelTiles = {};
            this.currentTiles = new TerrainTileList(this);
            this.currentCoverage = {};

            //this.tileCache = [[WWMemoryCache alloc] initWithCapacity:5000000 lowWater:4000000]; // Holds 316 32x32 tiles.

            this.detailHintOrigin = 1.1;

            this.elevationTimeStamp = undefined;
            this.lastModelViewProjection = undefined;

            this.expiration = undefined;

            this.currentAncestorTile = undefined;

            this.tileFactory = TileFactory;
        };

        /**
         * Tessellates the geometry of the globe associated with this terrain.
         * @returns {Terrain} The computed terrain, or null if terrain could not be computed.
         */
        Tessellator.prototype.tessellate = function (dc) {
            if (!dc) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Tessellator", "tessellate", "missingDC"));
            }

            // TODO: validate currentTiles with this.lastElevationChanged and this.lastModelViewProjection
            if (this.currentTiles) {
                return this.currentTiles;
            }

            var globe = dc.globe;
            var navigatorState = dc.navigatorState;

            this.lastModelViewProjection = navigatorState.modelviewProjection;

            this.currentTiles.removeAllTiles();
            this.currentCoverage = {};

            if (!this.topLevelTiles[globe].length == 0) {
                this.topLevelTiles[globe] = this.createTopLevelTiles();
            }

            for (var index = 0; index < this.topLevelTiles.length; index += 1) {
                var tile = this.topLevelTiles[index];

                tile.update(dc);

                if (this.isTileVisible(tile)) {
                    this.addTileOrDescendants(dc, tile);
                }

            }

            // TODO
            throw new NotYetImplementedError(
                Logger.logMessage(Logger.LEVEL_SEVERE, "Tessellator", "tessellate", "notYetImplemented"));

            return null;
        };

        /**
         * Initializes rendering state to draw a succession of terrain tiles.
         */
        Tessellator.prototype.beginRendering = function () {
            // TODO
            throw new NotYetImplementedError(
                Logger.logMessage(Logger.LEVEL_SEVERE, "Tessellator", "beginRendering", "notYetImplemented"));
        };

        /**
         * Restores rendering state after drawing a succession of terrain tiles.
         */
        Tessellator.prototype.endRendering = function () {
            // TODO
        };

        /**
         * Initializes rendering state for drawing a specified terrain tile.
         * @param {TerrainTile} terrainTile The terrain tile subsequently drawn via this tessellator's render function.
         * @throws {ArgumentError} If the specified tile is null or undefined.
         */
        Tessellator.prototype.beginRenderingTile = function (terrainTile) {
            if (!terrainTile) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Tessellator", "beginRenderingTile", "missingTile"));
            }

            // TODO
            throw new NotYetImplementedError(
                Logger.logMessage(Logger.LEVEL_SEVERE, "Tessellator", "beginRenderingTile", "notYetImplemented"));
        };

        /**
         * Restores rendering state after drawing the most recent tile specified to
         * [beginRenderingTile{@link Tessellator#beginRenderingTile}.
         * @param {TerrainTile} terrainTile The terrain tile most recently rendered.
         * @throws {ArgumentError} If the specified tile is null or undefined.
         */
        Tessellator.prototype.endRenderingTile = function (terrainTile) {
            if (!terrainTile) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Tessellator", "endRenderingTile", "missingTile"));
            }

            // TODO
            throw new NotYetImplementedError(
                Logger.logMessage(Logger.LEVEL_SEVERE, "Tessellator", "endRenderingTile", "notYetImplemented"));
        };

        /**
         * Renders a specified terrain tile.
         * @param {TerrainTile} terrainTile The terrain tile to render.
         * @throws {ArgumentError} If the specified tile is null or undefined.
         */
        Tessellator.prototype.renderTile = function (terrainTile) {
            if (!terrainTile) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Tessellator", "renderTile", "missingTile"));
            }

            // TODO
            throw new NotYetImplementedError(
                Logger.logMessage(Logger.LEVEL_SEVERE, "Tessellator", "renderTile", "notYetImplemented"));
        };

        Tessellator.prototype.createTopLevelTiles = function () {
            var tops = new Array(this.numLevel0LatSubdivisions * this.numLevel0LonSubdivisions);

            Tile.createTilesForLevel(0, this.tileFactory, tops);

            return tops;
        };

        Tessellator.prototype.isTileVisible = function (dc, tile) {
            return tile.extent.intersectsFrustum(dc.navigatorState.frustumInModelCoordinates);
        };

        Tessellator.prototype.addTileOrDescendants = function (dc, tile) {
            if (this.tileMeetsRenderCriteria(dc, tile)) {
                this.addTile(dc, tile);
                return;
            }

            var ancestorTile;

            if (this.isTileInTextureMemory(dc, tile) || tile.level == 0) {
                ancestorTile = this.currentAncestorTile;
                this.currentAncestorTile = tile;
            }

            var nextLevel = this.levels[tile.level + 1];
            var subTiles = [];
            tile.subdivideToCache(nextLevel, this.tileFactory, subTiles);
            subTiles.foreach(function (child) {
                child.update(dc);

                // TODO: confirm that "this" below is same as "this" of tessellator
                if (this.levels.sector.intersects(child.sector) &&
                    this.isTileVisible(dc, child)) {
                    this.addTileOrDescendants(dc, child);
                }
            });

            if (ancestorTile) {
                this.currentAncestorTile = ancestorTile;
            }

        };

        Tessellator.prototype.tileMeetsRenderCriteria = function(dc, tile) {
            this.addTile(dc, tile);
        };

        Tessellator.prototype.addTile = function (dc, tile) {
            throw new NotYetImplementedError(
                Logger.logMessage(Logger.LEVEL_SEVERE, "Tessellator", "addTile", "notYetImplemented"));

            if (this.mustRegenerateTileGeometry(dc, tile)) {
                this.regenerateTileGeometry(dc, tile);
            }

            this.currentTiles[dc.globe].addTile(dc, tile);

            if (!this.currentCoverage) {
                this.currentCoverage = tile.sector;
            }
            else {
                this.currentCoverage.union(tile.sector);
            }
        };

        Tessellator.prototype.mustRegenerateTileGeometry = function(dc, tile) {
            // TODO: tile doesn't have a timestamp yet
            throw new NotYetImplementedError(
                Logger.logMessage(Logger.LEVEL_SEVERE, "Tessellator", "mustRegenerateTileGeometry", "notYetImplemented"));
            return tile.timestamp != this.elevationTimeStamp;
        };

        Tessellator.prototype.regenerateTileGeometry = function(dc, tile) {
            // TODO
            throw new NotYetImplementedError(
                Logger.logMessage(Logger.LEVEL_SEVERE, "Tessellator", "regenerateTileGeometry", "notYetImplemented"));
        };

        Tessellator.prototype.isTextureExpired = function (texture) {
            // TODO: way too much undefined instance data to complete
            throw new NotYetImplementedError(
                Logger.logMessage(Logger.LEVEL_SEVERE, "Tessellator", "isTextureExpired", "notYetImplemented"));

            if (!this.expiration /* TODO || this.expiration > timeIntervalSinceNow */) {
                return false;
            }

            return false; // TODO: texture.fileModificationDate < this.expiration;
        };

        Tessellator.prototype.loadOrRetrieveTileImage = function (dc, tile) {
            if (this.isTileTextureOnDisk(tile)) {
                if (this.isTextureOnDiskExpired(tile)) {
                    this.retrieveTileImage(tile);// Existing image file is out of date, so initiate retrieval of an up-to-date one.

                    if (!this.isTileTextureInMemory(dc, tile)) {
                        return; // Out-of-date tile is in memory so don't load the old image file again.
                    }
                }

                // Load the existing image file whether it's out of date or not. This has the effect of showing expired
                // images until new ones arrive.
                this.loadTileImage(dc, tile);
            }
            else {
                this.retrieveTileImage(tile);
            }
        };

        Tessellator.prototype.isTileInTextureMemory = function (dc, tile) {
            // TODO
            throw new NotYetImplementedError(
                Logger.logMessage(Logger.LEVEL_SEVERE, "Tessellator", "isTileInTextureMemory", "notYetImplemented"));
        };

        Tessellator.prototype.isTileTextureOnDisk = function(tile) {
            // TODO
            throw new NotYetImplementedError(
                Logger.logMessage(Logger.LEVEL_SEVERE, "Tessellator", "isTileTextureOnDisk", "notYetImplemented"));
        };

        Tessellator.prototype.isTextureOnDiskExpired = function(tile) {
            // TODO
            throw new NotYetImplementedError(
                Logger.logMessage(Logger.LEVEL_SEVERE, "Tessellator", "isTextureOnDiskExpired", "notYetImplemented"));
        };

        Tessellator.prototype.loadTileImage = function(dc, tile) {
            // TODO
            throw new NotYetImplementedError(
                Logger.logMessage(Logger.LEVEL_SEVERE, "Tessellator", "loadTileImage", "notYetImplemented"));
        };

        Tessellator.prototype.retrieveTileImage = function(tile) {
            // TODO
            throw new NotYetImplementedError(
                Logger.logMessage(Logger.LEVEL_SEVERE, "Tessellator", "retrieveTileImage", "notYetImplemented"));
        };

        return Tessellator;
    });