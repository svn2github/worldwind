/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports ShowTessellationLayer
 * @version $Id$
 */
define([
        '../shaders/BasicProgram',
        '../util/Color',
        '../render/DrawContext',
        '../layer/Layer',
        '../globe/Terrain',
        '../globe/TerrainTile',
        '../globe/Tessellator'
    ],
    function (BasicProgram,
              Color,
              DrawContext,
              Layer,
              Terrain,
              TerrainTile,
              Tessellator) {
        "use strict";

        /**
         * Constructs a layer that displays a globe's tessellated geometry.
         * @alias ShowTessellationLayer
         * @constructor
         * @augments Layer
         * @classdesc Displays a globe's tessellated geometry.
         */
        var ShowTessellationLayer = function () {
            Layer.call(this, "Show Tessellation");

        };

        ShowTessellationLayer.prototype = Object.create(Layer.prototype);

        ShowTessellationLayer.prototype.beginRendering = function (dc) {
            var gl = dc.currentGlContext;

            dc.findAndBindProgram(gl, BasicProgram);
            gl.depthMask(false); // Disable depth buffer writes. Diagnostics should not occlude any other objects.
        };

        ShowTessellationLayer.prototype.endRendering = function (dc) {
            var gl = dc.currentGlContext;

            dc.bindProgram(gl, null);
            gl.depthMask(true); // re-enable depth buffer writes that were disabled in beginRendering.
        };

        ShowTessellationLayer.prototype.doRender = function (dc) {
            if (!dc.hasTerrain() || !dc.terrain.tessellator)
                return;

            var terrain = dc.terrain,
                tessellator = terrain.tessellator,
                surfaceGeometry = terrain.surfaceGeometry,
                gl = dc.currentGlContext,
                terrainTile,
                program;

            this.beginRendering(dc);
            try {
                program = dc.currentProgram;
                tessellator.beginRendering(dc);

                for (var i = 0, len = surfaceGeometry.length; i < len; i++)
                {
                    terrainTile = surfaceGeometry[i];

                    tessellator.beginRenderingTile(dc, terrainTile);
                    program.loadColor(gl, Color.WHITE); // wireframe color
                    tessellator.renderWireframeTile(dc, terrainTile);
                    program.loadColor(gl, Color.RED); // outline color
                    tessellator.renderTileOutline(dc, terrainTile);
                    tessellator.endRenderingTile(dc, terrainTile);
                }
            } finally {
                tessellator.endRendering(dc);
                this.endRendering(dc);
            }
        };

        return ShowTessellationLayer;
    });