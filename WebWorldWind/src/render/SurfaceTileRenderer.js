/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports SurfaceTileRenderer
 * @version $Id$
 */
define([
        '../error/ArgumentError',
        '../render/DrawContext',
        '../util/Logger',
        '../geom/Matrix',
        '../error/NotYetImplementedError',
        '../render/SurfaceTile',
        '../globe/Terrain',
        '../globe/Tessellator'
    ],
    function (ArgumentError,
              DrawContext,
              Logger,
              Matrix,
              NotYetImplementedError,
              SurfaceTile,
              Terrain,
              Tesselator) {
        "use strict";

        /**
         * Constructs a new surface tile renderer.
         * @alias SurfaceTileRenderer
         * @constructor
         * @classdesc This class is responsible for rendering imagery onto the terrain.
         * It is meant to be used internally. Applications typically do not interact with this class.
         */
        var SurfaceTileRenderer = function () {

            // Scratch values to avoid constantly recreating these matrices.
            this.texMaskMatrix = Matrix.fromIdentity();
            this.texSamplerMatrix = Matrix.fromIdentity();
        };

        /**
         * Render a specified collection of surface tiles.
         * @param {DrawContext} dc The current draw context.
         * @param {SurfaceTile[]} surfaceTiles The surface tiles to render.
         * @param {number} opacity The opacity at which to draw the surface tiles.
         */
        SurfaceTileRenderer.prototype.renderTiles = function (dc, surfaceTiles, opacity) {
            if (!surfaceTiles) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "SurfaceTileRenderer", "renderTiles",
                        "Specified surface tiles array is null or undefined."));
            }

            if (surfaceTiles.length < 1)
                return;

            var terrain = dc.terrain,
                tileCount = 0, // for frame statistics
                terrainTile,
                terrainTileSector,
                surfaceTile;

            if (!terrain || !terrain.surfaceGeometry)
                return;

            // For each terrain tile, render it for each overlapping surface tile.
            this.beginRendering(dc, opacity);
            terrain.beginRendering(dc);
            try {
                for (var i = 0, ttLen = terrain.surfaceGeometry.length; i < ttLen; i++) {
                    terrainTile = terrain.surfaceGeometry[i];
                    terrainTileSector = terrainTile.sector;

                    terrain.beginRenderingTile(dc, terrainTile);
                    try {
                        // Render the terrain tile for each overlapping surface tile.
                        for (var j = 0, stLen = surfaceTiles.length; j < stLen; j++) {
                            surfaceTile = surfaceTiles[i];
                            if (surfaceTile.sector.overlaps(terrainTileSector)) {
                                if (surfaceTile.bind(dc)) {
                                    this.applyTileState(dc, terrainTile, surfaceTile);
                                    terrain.renderTile(dc, terrainTile);
                                    ++tileCount;
                                }
                            }
                        }
                    } finally {
                        terrain.endRenderingTile(dc, terrainTile);
                    }
                }
            } finally {
                terrain.endRendering(dc);
                this.endRendering(dc);
                dc.frameStatistics.incrementRenderedTileCount(tileCount);
            }
        };

        SurfaceTileRenderer.prototype.beginRendering = function (dc, opacity) {
            // TODO
        };

        SurfaceTileRenderer.prototype.endRendering = function (dc) {
            // TODO
        };

        SurfaceTileRenderer.prototype.applyTileState = function (dc, terrainTile, surfaceTile) {
            // TODO
        };

        return SurfaceTileRenderer;
    });