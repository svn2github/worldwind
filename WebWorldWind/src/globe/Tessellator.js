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
        '../shaders/GpuProgram',
        '../util/Level',
        '../util/LevelSet',
        '../geom/Location',
        '../util/Logger',
        '../geom/Matrix',
        '../cache/MemoryCache',
        '../navigate/NavigatorState',
        '../error/NotYetImplementedError',
        '../geom/Rectangle',
        '../geom/Sector',
        '../globe/Terrain',
        '../globe/TerrainTile',
        '../globe/TerrainTileList',
        '../util/Tile'
    ],
    function (ArgumentError,
              Globe,
              GpuProgram,
              Level,
              LevelSet,
              Location,
              Logger,
              Matrix,
              MemoryCache,
              NavigatorState,
              NotYetImplementedError,
              Rectangle,
              Sector,
              Terrain,
              TerrainTile,
              TerrainTileList,
              Tile) {
        "use strict";

        /**
         * Constructs a Tessellator object for a specified globe.
         * @alias Tessellator
         * @constructor
         * @classdesc Represents a tessellator for a specified globe.
         */
        var Tessellator = function () {
            // Parameterize top level subdivision in one place.

            // TilesInTopLevel describes the most coarse tile structure.
            this.numRowsTilesInTopLevel = 4; // baseline: 4
            this.numColumnsTilesInTopLevel = 8; // baseline: 8

            // The maximum number of levels that will ever be tessellated.
            this.maximumSubdivisionDepth = 15; // baseline: 15

            // tileWidth, tileHeight - the number of subdivisions a single tile has; this determines the sampling grid.
            this.tileWidth = 32; // baseline: 32
            this.tileHeight = 32; // baseline: 32

            // detailHintOrigin - a parameter that describes the size of the sampling grid when fully zoomed in.
            // The size of the tile sampling grid when fully zoomed in is related to the logarithm base 10 of this parameter.
            // A parameter of 2 will have a sampling size approximately 10 times finer than a parameter of 1.
            // Parameters which result in changes of a factor of two are: 1.1, 1.4, 1.7, 2.0.
            this.detailHintOrigin = 1.1; // baseline: 1.1
            this.detailHint = 0;

            this.levels = new LevelSet(
                Sector.FULL_SPHERE,
                new Location(
                    180 / this.numRowsTilesInTopLevel,
                    360 / this.numColumnsTilesInTopLevel),
                this.maximumSubdivisionDepth,
                this.tileWidth,
                this.tileHeight);

            this.topLevelTiles = undefined;
            this.currentTiles = new TerrainTileList(this);
            this.currentCoverage = undefined;

            this.tileCache = new MemoryCache(5000000, 4000000); // Holds 316 32x32 tiles.

            this.detailHintOrigin = 1.1;
            this.detailHint = 0;

            this.elevationTimestamp = undefined;
            this.lastModelViewProjection = undefined;

            this.vertexPointLocation = -1;
            this.vertexTexCoordLocation = -1;
            this.vertexElevationLocation = -1;
            this.modelViewProjectionMatrixLocation = -1;

            this.elevationShadingEnabled = false;

            // was in sharedGeometry
            this.texCoords = undefined;
            this.numTexCoords = undefined;
            this.indices = undefined;
            this.numIndices = undefined;
            this.outlineIndices = undefined;
            this.numOutlineIndices = undefined;
            this.wireframeIndices = undefined;
            this.numWireframeIndices = undefined;

            this.indicesVboCacheKey = 'global_indices';
            this.wireframeIndicesVboCacheKey = 'global_wireframe_indices';
            this.outlineIndicesVboCacheKey = 'global_outline_indices';
            this.texCoordVboCacheKey = 'global_tex_coords';

            this.tileElevations = undefined;

            this.scratchMatrix = Matrix.fromIdentity();
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

            var lastElevationsChange = dc.globe.elevationTimestamp();
            if (this.currentTiles &&
                this.elevationTimestamp == lastElevationsChange &&
                !this.lastModelViewProjection &&
                dc.navigatorState.modelviewProjection.equals(this.lastModelViewProjection)) {
                return this.currentTiles;
            }

            var navigatorState = dc.navigatorState;

            this.lastModelViewProjection = navigatorState.modelviewProjection;

            this.currentTiles.removeAllTiles();
            this.currentCoverage = undefined;
            this.elevationTimestamp = lastElevationsChange;

            if (!this.topLevelTiles || this.topLevelTiles.length == 0) {
                this.createTopLevelTiles();
            }

            for (var index = 0; index < this.topLevelTiles.length; index += 1) {
                var tile = this.topLevelTiles[index];

                tile.update(dc);

                if (this.isTileVisible(dc, tile)) {
                    this.addTileOrDescendants(dc, tile);
                }
            }

            /*
            var terrain = new Terrain();
            terrain.surfaceGeometry = this.currentTiles.tileArray;
            terrain.globe = globe;
            terrain.tessellator = this;
            terrain.verticalExaggeration = dc.verticalExaggeration;
            terrain.sector = Sector.FULL_SPHERE;

            return terrain;
            */

            return this.currentTiles;
        };

        /**
         * Constructs a tile for a specified sector, level, row and column. Called as a factory method.
         * @param {Sector} tileSector The sector represented by the tile.
         * @param {Number} level The tile's level in a tile pyramid.
         * @param {Number} row The tile's row in the specified level in a tile pyramid.
         * @param {Number} column The tile's column in the specified level in a tile pyramid.
         * @throws {ArgumentError} If the specified sector or level is null or undefined or the row or column arguments
         * are less than zero.
         */
        Tessellator.prototype.createTile = function(tileSector, level, row, column) {
            if (!tileSector) {
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

            return new TerrainTile(tileSector, level, row, column);
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

            var gl = dc.currentGlContext,
                gpuResourceCache = dc.gpuResourceCache;

            // Keep track of the program's attribute locations. The tessellator does not know which program the caller has
            // bound, and therefore must look up the location of attributes by name.
            this.vertexPointLocation = program.attributeLocation(gl, "vertexPoint");
            this.vertexTexCoordLocation = program.attributeLocation(gl, "vertexTexCoord");
            this.vertexElevationLocation = program.attributeLocation(gl, "vertexElevation");
            this.modelViewProjectionMatrixLocation = program.uniformLocation(gl, "mvpMatrix");
            gl.enableVertexAttribArray(this.vertexPointLocation);

            if (this.elevationShadingEnabled && this.vertexElevationLocation >= 0) {
                gl.enableVertexAttribArray(this.vertexElevationLocation);
            }

            if (this.vertexTexCoordLocation >= 0) { // location of vertexTexCoord attribute is -1 when the basic program is bound
                var texCoordVbo = gpuResourceCache.resourceForKey(this.texCoordVboCacheKey);
                gl.bindBuffer(WebGLRenderingContext.ARRAY_BUFFER, texCoordVbo);
                gl.vertexAttribPointer(this.vertexTexCoordLocation, 2, WebGLRenderingContext.FLOAT, false, 0, 0);
                gl.enableVertexAttribArray(this.vertexTexCoordLocation);
            }

            var indicesVbo = gpuResourceCache.resourceForKey(this.indicesVboCacheKey);
            gl.bindBuffer(WebGLRenderingContext.ELEMENT_ARRAY_BUFFER, indicesVbo);
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

            var gl = dc.currentGlContext;

            gl.bindBuffer(WebGLRenderingContext.ARRAY_BUFFER, null);
            gl.bindBuffer(WebGLRenderingContext.ELEMENT_ARRAY_BUFFER, null);

            // Restore the global OpenGL vertex attribute array state.
            if (this.vertexPointLocation >= 0) {
                gl.disableVertexAttribArray(this.vertexPointLocation);
            }
            if (this.elevationShadingEnabled && this.vertexElevationLocation >= 0)
                gl.disableVertexAttribArray(this.vertexElevationLocation);

            if (this.vertexTexCoordLocation >= 0) { // location of vertexTexCoord attribute is -1 when the basic program is bound
                gl.disableVertexAttribArray(this.vertexTexCoordLocation);
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

            var gl = dc.currentGlContext,
                gpuResourceCache = dc.gpuResourceCache;

            this.scratchMatrix.setToMultiply(dc.navigatorState.modelviewProjection, terrainTile.transformationMatrix);
            GpuProgram.loadUniformMatrix(gl, this.scratchMatrix, this.modelViewProjectionMatrixLocation);

            var vbo = gpuResourceCache.resourceForKey(terrainTile.geometryVboCacheKey);
            if (!vbo) {
                vbo = gl.createBuffer();
                gl.bindBuffer(WebGLRenderingContext.ARRAY_BUFFER, vbo);
                gl.bufferData(WebGLRenderingContext.ARRAY_BUFFER, terrainTile.points, WebGLRenderingContext.STATIC_DRAW);
                dc.frameStatistics.incrementVboLoadCount(1);
                gpuResourceCache.putResource(gl, terrainTile.geometryVboCacheKey, vbo, WorldWind.GPU_BUFFER, terrainTile.points.length * 3 * 4);
                terrainTile.geometryVboTimestamp = terrainTile.geometryTimestamp;
            }
            else if (terrainTile.geometryVboTimestamp != terrainTile.geometryTimestamp) {
                gl.bindBuffer(WebGLRenderingContext.ARRAY_BUFFER, vbo);
                gl.bufferSubData(WebGLRenderingContext.ARRAY_BUFFER, 0, terrainTile.points);
                terrainTile.geometryVboTimestamp = terrainTile.geometryTimestamp;
            }
            else {
                dc.currentGlContext.bindBuffer(WebGLRenderingContext.ARRAY_BUFFER, vbo);
            }

            gl.vertexAttribPointer(this.vertexPointLocation, 3, WebGLRenderingContext.FLOAT, false, 0, 0);
            if (this.elevationShadingEnabled && this.vertexElevationLocation >= 0) {
                gl.bindBuffer(WebGLRenderingContext.ARRAY_BUFFER, null);
                gl.vertexAttribPointer(this.vertexElevationLocation,
                    1,
                    WebGLRenderingContext.FLOAT,
                    false,
                    0,
                    terrainTile.elevations);
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
            // Intentionally empty until there's some reason to add code here.
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
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Tessellator", "renderTile", "missingDc"));
            }
            if (!terrainTile) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Tessellator", "renderTile", "missingTile"));
            }

            var gl = dc.currentGlContext;

            gl.drawElements(
                WebGLRenderingContext.TRIANGLE_STRIP,
                this.numIndices,
                WebGLRenderingContext.UNSIGNED_SHORT,
                0);
        };

        /**
         * Draws outlines of the triangles composing the tile.
         * @param {DrawContext} dc The current draw context.
         * @param {TerrainTile} terrainTile The tile to draw.
         */
        Tessellator.prototype.renderWireframeTile = function (dc, terrainTile) {
            if (!dc) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Tessellator", "renderWireframeTile", "missingDc"));
            }
            if (!terrainTile) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Tessellator", "renderWireframeTile", "missingTile"));
            }

            var gl = dc.currentGlContext,
                gpuResourceCache = dc.gpuResourceCache;

            // Must turn off texture coordinates, which were turned on in beginRendering.
            if (this.vertexTexCoordLocation >= 0) {
                gl.disableVertexAttribArray(this.vertexTexCoordLocation);
            }

            var wireframeIndicesVbo = gpuResourceCache.resourceForKey(this.wireframeIndicesVboCacheKey);
            gl.bindBuffer(WebGLRenderingContext.ELEMENT_ARRAY_BUFFER, wireframeIndicesVbo);

            gl.drawElements(
                WebGLRenderingContext.LINES,
                this.numWireframeIndices,
                WebGLRenderingContext.UNSIGNED_SHORT,
                0);
        };

        /**
         * Draws the outer boundary of a specified terrain tile.
         * @param {DrawContext} dc The current draw context.
         * @param {TerrainTile} terrainTile The tile whose outer boundary to draw.
         */
        Tessellator.prototype.renderTileOutline = function (dc, terrainTile) {
            if (!dc) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Tessellator", "renderTileOutline", "missingDc"));
            }
            if (!terrainTile) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Tessellator", "renderTileOutline", "missingTile"));
            }

            var gl = dc.currentGlContext,
                gpuResourceCache = dc.gpuResourceCache;

            // Must turn off texture coordinates, which were turned on in beginRendering.
            if (this.vertexTexCoordLocation >= 0) {
                gl.disableVertexAttribArray(this.vertexTexCoordLocation);
            }

            var outlineIndicesVbo = gpuResourceCache.resourceForKey(this.outlineIndicesVboCacheKey);
            gl.bindBuffer(WebGLRenderingContext.ELEMENT_ARRAY_BUFFER, outlineIndicesVbo);

            gl.drawElements(
                WebGLRenderingContext.LINE_LOOP,
                this.numOutlineIndices,
                WebGLRenderingContext.UNSIGNED_SHORT,
                0);
        };

        /***********************************************************************
         * Internal methods - assume that arguments have been validated already.
         ***********************************************************************/

        Tessellator.prototype.createTopLevelTiles = function (dc) {
            this.topLevelTiles = [];
            Tile.createTilesForLevel(this.levels.firstLevel(), this, this.topLevelTiles);
        };

        Tessellator.prototype.addTileOrDescendants = function (dc, tile) {
            if (this.tileMeetsRenderCriteria(dc, tile)) {
                this.addTile(dc, tile);
                return;
            }

            var nextLevel = tile.level.nextLevel();
            var subTiles = tile.subdivideToCache(nextLevel, this, this.tileCache);
            for (var index = 0; index < subTiles.length; index += 1) {
                var child = subTiles[index];

                child.update(dc);

                if (this.levels.sector.intersects(child.sector) && this.isTileVisible(dc, child)) {
                    this.addTileOrDescendants(dc, child);
                }
            }
        };

        Tessellator.prototype.addTile = function (dc, tile) {
            if (this.mustRegenerateTileGeometry(dc, tile)) {
                this.regenerateTileGeometry(dc, tile);
            }

            this.currentTiles.addTile(tile);

            if (!this.currentCoverage) {
                this.currentCoverage = new Sector(tile.sector.minLatitude,
                    tile.sector.maxLatitude,
                    tile.sector.minLongitude,
                    tile.sector.maxLongitude);
            }
            else {
                this.currentCoverage.union(tile.sector);
            }
        };

        Tessellator.prototype.isTileVisible = function (dc, tile) {
            var isVisible =  tile.extent.intersectsFrustum(dc.navigatorState.frustumInModelCoordinates);
            return isVisible;
        };

        Tessellator.prototype.tileMeetsRenderCriteria = function (dc, tile) {
            return tile.level.isLastLevel() || !tile.mustSubdivide(dc, this.detailHintOrigin + this.detailHint);
        };

        Tessellator.prototype.mustRegenerateTileGeometry = function (dc, tile) {
            return tile.geometryTimestamp != this.elevationTimestamp;
        };

        Tessellator.prototype.regenerateTileGeometry = function (dc, tile) {
            this.buildTileVertices(dc, tile);
            this.buildSharedGeometry(tile);
            tile.geometryTimestamp = this.elevationTimestamp;
        };

        Tessellator.prototype.buildTileVertices = function (dc, tile) {
            var sector = tile.sector,
                ve = dc.verticalExaggeration;

            // Cartesian tile coordinates are relative to a local origin, called the reference center. Compute the reference
            // center here and establish a translation transform that is used later to move the tile coordinates into place
            // relative to the globe.
            var refCenter = tile.referencePoint;
            tile.transformationMatrix.setTranslation(refCenter[0], refCenter[1], refCenter[2]);

            // The number of vertices in each dimension is 1 more than the number of cells.
            var numLatVertices = tile.tileWidth + 1,
                numLonVertices = tile.tileHeight + 1,
                vertexStride = 3;

            // Retrieve the elevations for all vertices in the tile. The returned elevations will already have vertical
            // exaggeration applied.
            if (!this.tileElevations) {
                this.tileElevations = new Float64Array(numLatVertices * numLonVertices);
            }
            dc.globe.elevationsForSector(sector, numLatVertices, numLonVertices, tile.texelSize, ve, this.tileElevations);

            // Allocate space for the Cartesian vertices.
            var points = tile.points,
                numPoints = -1;
            if (!points) {
                numPoints = numLatVertices * numLonVertices;
                points = new Float32Array(numPoints * vertexStride);
                tile.numPoints = numPoints;
                tile.points = points;
            }

            var elevations = tile.elevations;
            if (!elevations) {
                elevations = new Float32Array(tile.numPoints);
                tile.elevations = elevations;
            }

            // Compute the tile's Cartesian vertices. The tile's min elevation is used to determine the necessary depth of the
            // tile border. Use the tile's min elevation instead of the global min elevation in order to reduce tile border
            // height. As of SVN revision 1768 this change reduces worst-case frame time for terrain rendering by ~20 ms.
            var borderElevation = tile.minElevation * ve;
            dc.globe.computePointsFromPositions(
                sector,
                tile.tileWidth,
                tile.tileHeight,
                this.tileElevations,
                borderElevation,
                refCenter,
                points,
                vertexStride,
                elevations);

            if (ve != 1.0) {
                // Need to back out vertical exaggeration from the elevations computed above.
                numPoints = tile.numPoints;
                for (var i = 0; i < numPoints; i += 1) {
                    elevations[i] /= ve;
                }
            }
        };

        Tessellator.prototype.buildSharedGeometry = function (tile) {
            if (this.sharedGeometry)
                return;

            this.buildTexCoords(tile.tileWidth, tile.tileHeight);

            // TODO: put all indices into a single buffer
            
            // Build the surface-tile indices.
            this.buildIndices(tile.tileWidth, tile.tileHeight);

            // Build the wireframe indices.
            this.buildWireframeIndices(tile.tileWidth, tile.tileHeight);

            // Build the outline indices.
            this.buildOutlineIndices(tile.tileWidth, tile.tileHeight);
        };

        Tessellator.prototype.buildTexCoords = function (tileWidth, tileHeight) {
            var numLatVertices = tileHeight + 1,
                numLonVertices = tileWidth + 1,
                vertexStride = 2;

            // Allocate an array to hold the texture coordinates.
            var numTexCoords = numLatVertices * numLonVertices,
                texCoords = new Float32Array(numTexCoords * vertexStride);

            var s, // Horizontal texture coordinate; varies along tile width or longitude.
                t; // Vertical texture coordinate; varies along tile height or latitude.

            var texIndex = 0;
            for (var row = 0; row <= tileHeight; row += 1) {
                t = row / tileHeight;

                for (var col = 0; col <= tileWidth; col += 1) {
                    s = col / tileWidth;

                    texCoords[texIndex] = s;
                    texCoords[texIndex + 1] = t;
                    texIndex += vertexStride;
                }
            }

            this.texCoords = texCoords;
            this.numTexCoords = numTexCoords;
        };

        Tessellator.prototype.buildIndices = function (tileWidth, tileHeight) {
            // The number of vertices in each dimension is 1 more than the number of cells.
            var numLatVertices = tileHeight + 1,
                numLonVertices = tileWidth + 1;

            // Each vertex has two indices associated with it: the current vertex index and the index of the row.
            // There are tileHeight rows.
            // There are tileHeight + 2 columns
            var numIndices = 2 * (numLatVertices - 1) * (numLonVertices + 1);
            var indices = new Int16Array(numIndices);

            var index = 0;
            for (var latIndex = 0; latIndex < numLatVertices - 1; latIndex += 1) {
                var vertexIndex; // The index of the vertex in the sample grid.
                for (var lonIndex = 0; lonIndex < numLonVertices; lonIndex += 1) {
                    vertexIndex = lonIndex + latIndex * numLonVertices;

                    // Create a triangle strip joining each adjacent row of vertices, starting in the top left corner and
                    // proceeding downward. The first vertex starts with the upper row of vertices and moves down to create a
                    // clockwise winding order.
                    indices[index] = vertexIndex;
                    indices[index + 1] = vertexIndex + numLonVertices;
                    index += 2;
                }

                // Insert indices to create 2 degenerate triangles:
                //      one for the end of the current row, and
                //      one for the beginning of the next row.
                indices[index] = vertexIndex + numLonVertices;
                indices[index + 1] = vertexIndex + 1;
                index += 2;
            }

            this.indices = indices;
            this.numIndices = numIndices;
        };

        Tessellator.prototype.buildWireframeIndices = function (tileWidth, tileHeight) {
            // The wireframe representation draws the vertices that appear on the surface.

            // The number of vertices in each dimension is 1 more than the number of cells.
            var numLatVertices = tileHeight + 1;
            var numLonVertices = tileWidth + 1;

            // Allocate an array to hold the computed indices.
            var numIndices = 2 * tileWidth * numLatVertices + 2 * tileHeight * numLonVertices;
            var indices = new Int16Array(numIndices);

            var rowStride = numLonVertices;

            var index = 0,
                lonIndex,
                latIndex,
                vertexIndex;

            // Add a line between each row to define the horizontal cell outlines.
            for (latIndex = 0; latIndex < numLatVertices; latIndex += 1) {
                for (lonIndex = 0; lonIndex < tileWidth; lonIndex += 1) {
                    vertexIndex = lonIndex + latIndex * rowStride;
                    indices[index] = vertexIndex;
                    indices[index + 1] = (vertexIndex + 1);
                    index += 2
                }
            }

            // Add a line between each column to define the vertical cell outlines.
            for (lonIndex = 0; lonIndex < numLonVertices; lonIndex += 1) {
                for (latIndex = 0; latIndex < tileHeight; latIndex += 1) {
                    vertexIndex = lonIndex + latIndex * rowStride;
                    indices[index] = vertexIndex;
                    indices[index + 1] = (vertexIndex + rowStride);
                    index += 2;
                }
            }

            this.wireframeIndices = indices;
            this.numWireframeIndices = numIndices;
        };

        Tessellator.prototype.buildOutlineIndices = function (tileWidth, tileHeight) {
            // The outline representation traces the tile's outer edge on the surface.

            // The number of vertices in each dimension is 1 more than the number of cells.
            var numLatVertices = tileHeight + 1;
            var numLonVertices = tileWidth + 1;

            // Allocate an array to hold the computed indices.
            var numIndices = 2 * (numLatVertices - 2) + 2 * numLonVertices + 1;
            var indices = new Int16Array(numIndices);

            var rowStride = numLatVertices;

            var index = 0,
                lonIndex,
                latIndex,
                vertexIndex;

            // Bottom row, starting at the left and going right.
            latIndex = 0;
            for (lonIndex = 0; lonIndex < numLonVertices; lonIndex += 1) {
                vertexIndex = lonIndex + latIndex * numLonVertices;
                indices[index] = vertexIndex;
                index += 1;
            }

            // Right column, starting at the bottom and going up.
            lonIndex = numLonVertices - 1;
            for (latIndex = 1; latIndex < numLatVertices; latIndex += 1) {
                vertexIndex = lonIndex + latIndex * numLonVertices;
                indices[index] = vertexIndex;
                index += 1
            }

            // Top row, starting on the right and going to the left.
            latIndex = numLatVertices - 1;
            for (lonIndex = numLonVertices - 1; lonIndex >= 0; lonIndex -= 1) {
                vertexIndex = lonIndex + latIndex * numLonVertices;
                indices[index] = vertexIndex;
                index += 1
            }

            // Leftmost column, starting at the top and going down.
            lonIndex = 0;
            for (latIndex = numLatVertices - 1; latIndex >= 0; latIndex -= 1) {
                vertexIndex = lonIndex + latIndex * numLonVertices;
                indices[index] = vertexIndex;
                index += 1
            }

            this.outlineIndices = indices;
            this.numOutlineIndices = numIndices;
        };

        Tessellator.prototype.cacheSharedGeometryVBOs = function (dc) {
            var gl = dc.currentGlContext,
                gpuResourceCache = dc.gpuResourceCache;

            var texCoordVbo = gpuResourceCache.resourceForKey(this.texCoordVboCacheKey);
            if (!texCoordVbo) {
                texCoordVbo = gl.createBuffer();
                gl.bindBuffer(WebGLRenderingContext.ARRAY_BUFFER, texCoordVbo);
                gl.bufferData(WebGLRenderingContext.ARRAY_BUFFER, this.texCoords, WebGLRenderingContext.STATIC_DRAW);
                dc.frameStatistics.incrementVboLoadCount(1);
                gpuResourceCache.putResource(gl, this.texCoordVboCacheKey, texCoordVbo, WorldWind.GPU_BUFFER, this.texCoords.length * 4 / 2);
            }

            var indicesVbo = gpuResourceCache.resourceForKey(this.indicesVboCacheKey);
            if (!indicesVbo) {
                indicesVbo = gl.createBuffer();
                gl.bindBuffer(WebGLRenderingContext.ELEMENT_ARRAY_BUFFER, indicesVbo);
                gl.bufferData(WebGLRenderingContext.ELEMENT_ARRAY_BUFFER, this.indices, WebGLRenderingContext.STATIC_DRAW);
                dc.frameStatistics.incrementVboLoadCount(1);
                gpuResourceCache.putResource(gl, this.indicesVboCacheKey, indicesVbo, WorldWind.GPU_BUFFER, this.indices.length * 4);
            }

            var outlineIndicesVbo = gpuResourceCache.resourceForKey(this.outlineIndicesVboCacheKey);
            if (!outlineIndicesVbo) {
                outlineIndicesVbo = gl.createBuffer();
                gl.bindBuffer(WebGLRenderingContext.ELEMENT_ARRAY_BUFFER, outlineIndicesVbo);
                gl.bufferData(WebGLRenderingContext.ELEMENT_ARRAY_BUFFER, this.outlineIndices, WebGLRenderingContext.STATIC_DRAW);
                dc.frameStatistics.incrementVboLoadCount(1);
                gpuResourceCache.putResource(gl, this.outlineIndicesVboCacheKey, outlineIndicesVbo, WorldWind.GPU_BUFFER, this.outlineIndices.length * 4);
            }

            var wireframeIndicesVbo = gpuResourceCache.resourceForKey(this.wireframeIndicesVboCacheKey);
            if (!wireframeIndicesVbo) {
                wireframeIndicesVbo = gl.createBuffer();
                gl.bindBuffer(WebGLRenderingContext.ELEMENT_ARRAY_BUFFER, wireframeIndicesVbo);
                gl.bufferData(WebGLRenderingContext.ELEMENT_ARRAY_BUFFER, this.wireframeIndices, WebGLRenderingContext.STATIC_DRAW);
                dc.frameStatistics.incrementVboLoadCount(1);
                gpuResourceCache.putResource(gl, this.wireframeIndicesVboCacheKey, wireframeIndicesVbo, WorldWind.GPU_BUFFER, this.wireframeIndices.length * 4);
            }
        };

        return Tessellator;
    });