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

            this.vertexPointLocation = -1;
            this.vertexTexCoordLocation = -1;
            this.vertexElevationLocation = -1;
            this.modelViewProjectionMatrixLocation = -1;

            this.elevationShadingEnabled = false;

            this.sharedGeometry = undefined;

        };

        /**
         * Tessellates the geometry of the globe associated with this terrain.
         * @param {DrawContext} dc The draw context.
         * @returns {Terrain} The computed terrain, or null if terrain could not be computed.
         * @throws {ArgumentError} If the dc is null or undefined.
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

            return this.currentTiles;
        };

        /**
         * Initializes rendering state to draw a succession of terrain tiles.
         * @param {DrawContext} dc The draw context.
         * @throws {ArgumentError} If the dc is null or undefined.
         */
        Tessellator.prototype.beginRendering = function (dc) {
            if (!dc) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Tessellator", "beginRendering", "missingDc"));
            }

            var program = dc.currentProgram; // use the current program; the caller configures other program state
            if (!program) {
                Logger.logMessage(Logger.LEVEL_INFO, "Tessellator", "beginRendering", "Current Program is empty");
                return;
            }

            this.cacheSharedGeometryVBOs(dc);

            // Keep track of the program's attribute locations. The tessellator does not know which program the caller has
            // bound, and therefore must look up the location of attributes by name.
            this.vertexPointLocation = program.attributeLocation("vertexPoint");
            this.vertexTexCoordLocation = program.attributeLocation("vertexTexCoord");
            this.vertexElevationLocation = program.attributeLocation("vertexElevation");
            this.modelViewProjectionMatrixLocation = program.uniformLocation("mvpMatrix");
            dc.currentGlContext.glEnableVertexAttribArray(vertexPointLocation);

            if (this._elevationShadingEnabled && vertexElevationLocation >= 0) {
                dc.currentGlContext.glEnableVertexAttribArray(vertexElevationLocation);
            }

            var gpuResourceCache = dc.gpuResourceCache;

            if (this.vertexTexCoordLocation >= 0) // location of vertexTexCoord attribute is -1 when the basic program is bound
            {
                var texCoordVboId = dc.gpuResourceCache.resourceForKey(this.sharedGeometry.texCoordVboCacheKey);
                dc.currentGlContext.bindBuffer(dc.currentGlContext.GL_ARRAY_BUFFER, texCoordVboId.intValue);
                dc.currentGlContext.glVertexAttribPointer(vertexTexCoordLocation, 2, dc.currentGlContext.GL_FLOAT, false, 0, 0);
                dc.currentGlContext.glEnableVertexAttribArray(vertexTexCoordLocation);
            }

            var indicesVboId = gpuResourceCache.resourceForKey(this.sharedGeometry.indicesVboCacheKey);
            dc.currentGlContext.bindBuffer(dc.currentGlContext.GL_ELEMENT_ARRAY_BUFFER, indicesVboId.intValue);
        };

        /**
         * Restores rendering state after drawing a succession of terrain tiles.
         * @param {DrawContext} dc The draw context.
         * @throws {ArgumentError} If the dc or the specified tile is null or undefined.
         */
        Tessellator.prototype.endRendering = function (dc) {
            if (!dc) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Tessellator", "endRendering", "missingDc"));
            }

            dc.currentGlContext.bindBuffer(dc.currentGlContext.GL_ARRAY_BUFFER, 0);
            dc.currentGlContext.bindBuffer(dc.currentGlContext.GL_ELEMENT_ARRAY_BUFFER, 0);

            // Restore the global OpenGL vertex attribute array state.
            dc.currentGlContext.glDisableVertexAttribArray(vertexPointLocation);
            if (_elevationShadingEnabled && vertexElevationLocation >= 0)
                dc.currentGlContext.glDisableVertexAttribArray(vertexElevationLocation);

            if (vertexTexCoordLocation >= 0) // location of vertexTexCoord attribute is -1 when the basic program is bound
            {
                dc.currentGlContext.glDisableVertexAttribArray(vertexTexCoordLocation);
            }
        };

        /**
         * Initializes rendering state for drawing a specified terrain tile.
         * @param {DrawContext} dc The draw context.
         * @param {TerrainTile} terrainTile The terrain tile subsequently drawn via this tessellator's render function.
         * @throws {ArgumentError} If the dc or the specified tile is null or undefined.
         */
        Tessellator.prototype.beginRenderingTile = function (dc, terrainTile) {
            if (!dc) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Tessellator", "beginRenderingTile", "missingDc"));
            }
            if (!terrainTile) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Tessellator", "beginRenderingTile", "missingTile"));
            }

            // TODO
            throw new NotYetImplementedError(
                Logger.logMessage(Logger.LEVEL_SEVERE, "Tessellator", "beginRenderingTile", "notYetImplemented"));

            var modelViewProjection = new Object(dc.navigatorState.modelviewProjection); // TODO: verify that this cloned
            modelViewProjection.multiplyMatrix(tile.transformationMatrix);
            GpuProgram.loadUniformMatrix(dc.currentGlContext, modelViewProjection, this.modelViewProjectionMatrixLocation);

            var gpuResourceCache = dc.gpuResourceCache;
            var vbo = gpuResourceCache.resourceForKey(tile.geometryVboCacheKey);
            if (vbo) {
                var size = tile.numPoints * 3 * sizeof(float);
                var vbo = dc.currentGlContext.createBuffer();
                dc.currentGlContext.bindBuffer(dc.currentGlContext.GL_ARRAY_BUFFER, vbo);
                dc.currentGlContext.bufferData(dc.currentGlContext.GL_ARRAY_BUFFER,
                    size,
                    tile.points,
                    dc.currentGlContext.GL_STATIC_DRAW);
                gpuResourceCache.putResource(vboId, WW_GPU_VBO, size, tile.geometryVboCacheKey);
                tile.setGeometryVboTimestamp(tile.geometryTimestamp);
                dc.frameStatistics.incrementVboLoadCount(1);
            }
            else if (tile.geometryVboTimestamp != tile.geometryTimestamp) {
                var size = tile.numPoints * 3 * sizeof(float);
                var vbo = dc.currentGlContext.createBuffer();
                dc.currentGlContext.bindBuffer(dc.currentGlContext.GL_ARRAY_BUFFER, vbo);
                dc.currentGlContext.bufferSubData(dc.currentGlContext.GL_ARRAY_BUFFER, 0, size, tile.points);
                tile.setGeometryVboTimestamp(tile.geometryTimestamp);
            }
            else {
                var vbo = dc.currentGlContext.createBuffer();
                dc.currentGlContext.bindBuffer(dc.currentGlContext.GL_ARRAY_BUFFER, vbo);
            }

            dc.currentGlContext.vertexAttribPointer(this.vertexPointLocation, 3, dc.currentGlContext.GL_FLOAT, false, 0, 0);
            if (this.elevationShadingEnabled && this.vertexElevationLocation >= 0) {
                dc.currentGlContext.bindBuffer(GL_ARRAY_BUFFER, 0);
                dc.currentGlContext.vertexAttribPointer(this.vertexElevationLocation, 1, dc.currentGlContext.GL_FLOAT, false, 0, tile.elevations);
            }
        };

        /**
         * Restores rendering state after drawing the most recent tile specified to
         * [beginRenderingTile{@link Tessellator#beginRenderingTile}.
         * @param {DrawContext} dc The draw context.
         * @param {TerrainTile} terrainTile The terrain tile most recently rendered.
         * @throws {ArgumentError} If the dc or the specified tile is null or undefined.
         */
        Tessellator.prototype.endRenderingTile = function (dc, terrainTile) {
            if (!dc) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Tessellator", "endRenderingTile", "missingDc"));
            }
            if (!terrainTile) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Tessellator", "endRenderingTile", "missingTile"));
            }

            /*
             *  Note: the body of this function in the iOS version is empty.
             *  Perhaps this implementation is complete?
             */
        };

        /**
         * Renders a specified terrain tile.
         * @param {DrawContext} dc The draw context.
         * @param {TerrainTile} terrainTile The terrain tile to render.
         * @throws {ArgumentError} If the dc or the specified tile is null or undefined.
         */
        Tessellator.prototype.renderTile = function (dc, terrainTile) {
            if (!dc) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Tessellator", "endRenderingTile", "missingDc"));
            }
            if (!terrainTile) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Tessellator", "renderTile", "missingTile"));
            }

            dc.currentGlContext.glDrawElements(
                dc.currentGlContext.GL_TRIANGLE_STRIP,
                this.sharedGeometry.numIndices,
                dc.currentGlContext.GL_UNSIGNED_SHORT,
                0);
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

        Tessellator.prototype.tileMeetsRenderCriteria = function (dc, tile) {
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

        Tessellator.prototype.mustRegenerateTileGeometry = function (dc, tile) {
            // TODO: tile doesn't have a timestamp yet
            throw new NotYetImplementedError(
                Logger.logMessage(Logger.LEVEL_SEVERE, "Tessellator", "mustRegenerateTileGeometry", "notYetImplemented"));
            return tile.timestamp != this.elevationTimeStamp;
        };

        Tessellator.prototype.regenerateTileGeometry = function (dc, tile) {
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

        Tessellator.prototype.isTileTextureOnDisk = function (tile) {
            // TODO
            throw new NotYetImplementedError(
                Logger.logMessage(Logger.LEVEL_SEVERE, "Tessellator", "isTileTextureOnDisk", "notYetImplemented"));
        };

        Tessellator.prototype.isTextureOnDiskExpired = function (tile) {
            // TODO
            throw new NotYetImplementedError(
                Logger.logMessage(Logger.LEVEL_SEVERE, "Tessellator", "isTextureOnDiskExpired", "notYetImplemented"));
        };

        Tessellator.prototype.loadTileImage = function (dc, tile) {
            // TODO
            throw new NotYetImplementedError(
                Logger.logMessage(Logger.LEVEL_SEVERE, "Tessellator", "loadTileImage", "notYetImplemented"));
        };

        Tessellator.prototype.retrieveTileImage = function (tile) {
            // TODO
            throw new NotYetImplementedError(
                Logger.logMessage(Logger.LEVEL_SEVERE, "Tessellator", "retrieveTileImage", "notYetImplemented"));
        };

        Tessellator.prototype.cacheSharedGeometryVBOs = function (dc) {
            // TODO
            throw new NotYetImplementedError(
                Logger.logMessage(Logger.LEVEL_SEVERE, "Tessellator", "cacheSharedGeometryVBOs", "notYetImplemented"));

        };

        return Tessellator;
    });