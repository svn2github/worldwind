/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports SurfaceTileRenderer
 * @version $Id$
 */
define([
        'src/util/Logger'
    ],
    function (Logger) {
        "use strict";

        /**
         * Constructs a new surface tile renderer.
         * @alias SurfaceTileRenderer
         * @constructor
         * @classdesc This class is responsible for rendering imagery onto the terrain.
         * it is meant to be used internally. Applications typically do not interact with this class.
         */
        var SurfaceTileRenderer = function() {
        };

        SurfaceTileRenderer.prototype.renderTiles = function(dc, surfaceTiles, opacity) {
            // TODO
        };

        SurfaceTileRenderer.prototype.beginRendering = function(dc, opacity) {
            // TODO
        };

        SurfaceTileRenderer.prototype.endRendering = function(dc) {
            // TODO
        };

        SurfaceTileRenderer.prototype.applyTileState = function(dc, terrainTile, surfaceTile) {
            // TODO
        };

        return SurfaceTileRenderer;
    });