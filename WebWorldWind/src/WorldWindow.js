/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports WorldWindow
 * @version $Id$
 */
define([
        './error/ArgumentError',
        './render/DrawContext',
        './util/FrameStatistics',
        './globe/Globe',
        './render/GpuResourceCache',
        './layer/LayerList',
        './util/Logger',
        './navigate/LookAtNavigator',
        './navigate/NavigatorState',
        './geom/Rectangle',
        './globe/Tessellator',
        './globe/ZeroElevationModel'],
    function (ArgumentError,
              DrawContext,
              FrameStatistics,
              Globe,
              GpuResourceCache,
              LayerList,
              Logger,
              LookAtNavigator,
              NavigatorState,
              Rectangle,
              Tessellator,
              ZeroElevationModel) {
        "use strict";

        /**
         * Constructs a World Wind window for an HTML canvas.
         * @alias WorldWindow
         * @constructor
         * @classdesc Represents a World Wind window for an HTML canvas.
         * @param {String} canvasName The name assigned to the canvas in the HTML page.
         */
        var WorldWindow = function (canvasName) {
            this.canvas = document.getElementById(canvasName);

            this.canvas.addEventListener("webglcontextlost", handleContextLost, false);
            this.canvas.addEventListener("webglcontextrestored", handleContextRestored, false);

            function handleContextLost(event) {
                event.preventDefault();
            }

            function handleContextRestored(event) {
            }

            /**
             * The globe displayed.
             * @type {Globe}
             */
            this.globe = new Globe(new ZeroElevationModel());

            /**
             * The layers to display.
             * @type {LayerList}
             */
            this.layers = new LayerList();

            /**
             * The navigator used to manipulate the globe.
             * @type {LookAtNavigator}
             * @default [LookAtNavigator]{@link LookAtNavigator}
             */
            this.navigator = new LookAtNavigator();

            /**
             * The tessellator used to create the globe's terrain.
             * @type {Tessellator}
             */
            this.tessellator = new Tessellator();

            /**
             * The vertical exaggeration to apply to the terrain.
             * @type {Number}
             */
            this.verticalExaggeration = 1;

            /**
             * Performance statistics for this WorldWindow.
             * @type {FrameStatistics}
             */
            this.frameStatistics = new FrameStatistics();

            // Internal. Intentionally not documented.
            this.gpuResourceCache = new GpuResourceCache();

            // Internal. Intentionally not documented.
            this.drawContext = new DrawContext();
        };

        /**
         * Redraws the window.
         */
        WorldWindow.prototype.redraw = function () {
            if (!(window.WebGLRenderingContext)) {
                Logger.log(Logger.LEVEL_SEVERE, "Canvas does not support WebGL");
                return;
            }

            try {
                this.resetDrawContext();
                this.drawFrame();
            } catch (e) {
                Logger.logMessage(Logger.LEVEL_SEVERE, "WorldWindow", "render",
                    "Exception occurred during rendering: " + e.toString());
            }
        };

        // Internal. Intentionally not documented.
        WorldWindow.prototype.resetDrawContext = function () {
            var dc = this.drawContext;

            dc.reset();
            dc.globe = this.globe;
            dc.layerList = this.layers;
            dc.navigatorState = this.navigator.currentState();
            dc.verticalExaggeration = this.verticalExaggeration;
            dc.frameStatistics = this.frameStatistics;
            dc.update();
        };

        // Internal function. Intentionally not documented.
        WorldWindow.prototype.drawFrame = function () {
            var viewport = new Rectangle(0, 0, this.canvas.width, this.canvas.height);

            this.drawContext.currentGlContext = this.canvas.getContext("webgl");

            try {
                this.beginFrame(this.drawContext, viewport);
                this.createTerrain(this.drawContext);
                this.clearFrame(this.drawContext);
                this.doDraw(this.drawContext);
            } finally {
                this.endFrame(this.drawContext);
            }
        };

        // Internal function. Intentionally not documented.
        WorldWindow.prototype.beginFrame = function (dc, viewport) {
            var gl = dc.currentGlContext;

            gl.viewport(viewport.x, viewport.y, viewport.width, viewport.height);
        };

        // Internal function. Intentionally not documented.
        WorldWindow.prototype.endFrame = function (dc) {
        };

        // Internal function. Intentionally not documented.
        WorldWindow.prototype.clearFrame = function (dc) {
            var gl = dc.currentGlContext;

            gl.clearColor(dc.clearColor.red, dc.clearColor.green, dc.clearColor.blue, dc.clearColor.alpha);
            gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
        };

        // Internal function. Intentionally not documented.
        WorldWindow.prototype.doDraw = function (dc) {
        };

        // Internal function. Intentionally not documented.
        WorldWindow.prototype.createTerrain = function (dc) {
            this.drawContext.terrain = this.tessellator.tessellate(dc);
        };

        return WorldWindow;
    }
)
;