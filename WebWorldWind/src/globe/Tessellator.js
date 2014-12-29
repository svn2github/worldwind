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

            // TileSamples - the sampling grid for vertices in a tile.
            this.numRowsTileSamples = 32; // baseline: 32
            this.numColumnsTileSamples = 32; // baseline: 32

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
                this.numRowsTileSamples,
                this.numColumnsTileSamples);

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
                numPoints = (numLatVertices + 2) * (numLonVertices + 2);
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
                numLatVertices,
                numLonVertices,
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
            // The number of vertices in each dimension is 3 more than the number of cells. Two of those are for the skirt.
            var numLatVertices = tileHeight + 3,
                numLonVertices = tileWidth + 3,
                vertexStride = 2;

            // Allocate an array to hold the texture coordinates.
            var numTexCoords = numLatVertices * numLonVertices,
                texCoords = new Float32Array(numTexCoords * vertexStride);

            var minS = 0,
                maxS = 1,
                minT = 0,
                maxT = 1,
                deltaS = (maxS - minS) / tileWidth,
                deltaT = (maxT - minT) / tileHeight,
                s = minS, // Horizontal texture coordinate; varies along tile width or longitude.
                t = minT; // Vertical texture coordinate; varies along tile height or latitude.

            var k = 0;
            for (var j = 0; j < numLatVertices; j += 1) {
                if (j <= 1) {// First two columns repeat the min T-coordinate to provide a column for the skirt.
                    t = minT;
                }
                else if (j >= numLatVertices - 2) {// Last two columns repeat the max T-coordinate to provide a column for the skirt.
                    t = maxT;
                }
                else {
                    t += deltaT; // Non-boundary latitudes are separated by the cell latitude delta.
                }

                for (var i = 0; i < numLonVertices; i += 1) {
                    if (i <= 1) {// First two rows repeat the min S-coordinate to provide a row for the skirt.
                        s = minS;
                    }
                    else if (i >= numLonVertices - 2) {// Last two rows repeat the max S-coordinate to provide a row for the skirt.
                        s = maxS;
                    }
                    else {
                        s += deltaS; // Non-boundary longitudes are separated by the cell longitude delta.
                    }

                    texCoords[k] = s;
                    texCoords[k + 1] = t;
                    k += vertexStride;
                }
            }

            this.texCoords = texCoords;
            this.numTexCoords = numTexCoords;
        };

        Tessellator.prototype.buildIndices = function (tileWidth, tileHeight) {
            // The number of vertices in each dimension is 3 more than the number of cells. Two of those are for the skirt.
            var numLatVertices = tileHeight + 3;
            var numLonVertices = tileWidth + 3;

            // Allocate an array to hold the indices used to draw a tile of the specified width and height as a triangle strip.
            // Shorts are the largest primitive that OpenGL ES allows for an index buffer. The largest tileWidth and tileHeight
            // that can be indexed by a short is 256x256 (excluding the extra rows and columns to convert between cell count and
            // vertex count, and the extra rows and columns for the tile skirt).
            var numIndices = 2 * (numLatVertices - 1) * numLonVertices + 2 * (numLatVertices - 2);
            var indices = new Int16Array(numIndices);

            var k = 0;
            for (var j = 0; j < numLatVertices - 1; j += 1) {
                if (j != 0) {
                    // Attach the previous and next triangle strips by repeating the last and first vertices of the previous
                    // and current strips, respectively. This creates a degenerate triangle between the two strips which is
                    // not rasterized because it has zero area. We don't perform this step when j==0 because there is no
                    // previous triangle strip to connect with.
                    indices[k] = ((numLonVertices - 1) + (j - 1) * numLonVertices); // last vertex of previous strip
                    indices[k + 1] = (j * numLonVertices + numLonVertices); // first vertex of current strip
                    k += 2;
                }

                for (var i = 0; i < numLonVertices; i += 1) {
                    // Create a triangle strip joining each adjacent row of vertices, starting in the lower left corner and
                    // proceeding upward. The first vertex starts with the upper row of vertices and moves down to create a
                    // counter-clockwise winding order.
                    var vertex = i + j * numLonVertices;
                    indices[k] = (vertex + numLonVertices);
                    indices[k + 1] = vertex;
                    k += 2;
                }
            }

            this.indices = indices;
            this.numIndices = numIndices;
        };

        Tessellator.prototype.buildWireframeIndices = function (tileWidth, tileHeight) {
            // The wireframe representation ignores the tile skirt and draws only the vertices that appear on the surface.

            // The number of vertices in each dimension is 1 more than the number of cells.
            var numLatVertices = tileHeight + 1;
            var numLonVertices = tileWidth + 1;

            // Allocate an array to hold the computed indices.
            var numIndices = 2 * tileWidth * (tileHeight + 1) + 2 * tileHeight * (tileWidth + 1);
            var indices = new Int16Array(numIndices);

            // Add two columns of vertices to the row stride to account for the west and east skirt vertices.
            var rowStride = numLonVertices + 2;
            // Skip the skirt row and column to start an the first interior vertex.
            var offset = rowStride + 1;

            // Add a line between each row to define the horizontal cell outlines. Starts and ends at the vertices that
            // appear on the surface, thereby ignoring the tile skirt.
            var k = 0,
                i,
                j,
                vertex;
            for (j = 0; j < numLatVertices; j += 1) {
                for (i = 0; i < tileWidth; i += 1) {
                    vertex = offset + i + j * rowStride;
                    indices[k] = vertex;
                    indices[k + 1] = (vertex + 1);
                    k += 2
                }
            }

            // Add a line between each column to define the vertical cell outlines. Starts and ends at the vertices that
            // appear on the surface, thereby ignoring the tile skirt.
            for (i = 0; i < numLonVertices; i += 1) {
                for (j = 0; j < tileHeight; j += 1) {
                    vertex = offset + i + j * rowStride;
                    indices[k] = vertex;
                    indices[k + 1] = (vertex + rowStride);
                    k += 2;
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

            // Allocate an array to hold the computed indices. The outline indices ignore the extra rows and columns for the
            // tile skirt.
            var numIndices = 2 * (numLatVertices - 1) + 2 * numLonVertices - 1;
            var indices = new Int16Array(numIndices);

            // Add two columns of vertices to the row stride to account for the two additional vertices that provide an
            // outer row/column for the tile skirt.
            var rowStride = numLonVertices + 2;

            // Bottom row. Offset by rowStride + 1 to start at the lower left corner, ignoring the tile skirt.
            var offset = rowStride + 1,
                k = 0,
                i,
                j;
            for (i = 0; i < numLonVertices; i += 1) {
                indices[k] = (offset + i);
                k += 1;
            }

            // Rightmost column. Offset by rowStride - 2 to start at the lower right corner, ignoring the tile skirt. Skips
            // the bottom vertex, which is already included in the bottom row.
            offset = 2 * rowStride - 2;
            for (j = 1; j < numLatVertices; j += 1) {
                indices[k] = (offset + j * rowStride);
                k += 1
            }

            // Top row. Offset by tileHeight* rowStride + 1 to start at the top left corner, ignoring the tile skirt. Skips
            // the rightmost vertex, which is already included in the rightmost column.
            offset = numLatVertices * rowStride + 1;
            for (i = numLonVertices - 2; i >= 0; i -= 1) {
                indices[k] = (offset + i);
                k += 1
            }

            // Leftmost column. Offset by rowStride + 1 to start at the lower left corner, ignoring the tile skirt. Skips
            // the topmost vertex, which is already included in the top row.
            offset = rowStride + 1;
            for (j = numLatVertices - 2; j >= 0; j -= 1) {
                indices[k] = (offset + j * rowStride);
                k += 1
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