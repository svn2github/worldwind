/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports WorldWindow
 * @version $Id$
 */
define([
        'src/error/ArgumentError',
        'src/render/DrawContext',
        'src/util/FrameStatistics',
        'src/globe/Globe',
        'src/render/GpuResourceCache',
        'src/layer/LayerList',
        'src/util/Logger',
        'src/navigate/LookAtNavigator',
        'src/navigate/NavigatorState',
        'src/geom/Rectangle',
        'src/globe/Tessellator',
        'src/globe/ZeroElevationModel'],
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
         * @param canvasName the name assigned to the canvas in the HTML page.
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

            this.globe = new Globe(new ZeroElevationModel());

            this.tessellator = new Tessellator();

            this.verticalExaggeration = 1;

            this.gpuResourceCache = new GpuResourceCache();

            this.layers = new LayerList();

            this.navigator = new LookAtNavigator();

            this.frameStatistics = new FrameStatistics();

            this.drawContext = new DrawContext();
        };

        /**
         * Redraws the window.
         */
        WorldWindow.prototype.render = function () {
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

        WorldWindow.prototype.drawFrame = function () {
            var viewport = new Rectangle(0, 0, this.canvas.width, this.canvas.height);

            this.drawContext.currentGLContext = this.canvas.getContext("webgl");

            try {
                this.beginFrame(this.drawContext, viewport);
                this.createTerrain(this.drawContext);
                this.clearFrame(this.drawContext);
                this.doDraw(this.drawContext);
            } finally {
                this.endFrame(this.drawContext);
            }
        };

        WorldWindow.prototype.beginFrame = function (dc, viewport) {
            var gl = dc.currentGLContext;

            gl.viewport(viewport.x, viewport.y, viewport.width, viewport.height);
        };

        WorldWindow.prototype.endFrame = function (dc) {
        };

        WorldWindow.prototype.clearFrame = function (dc) {
            var gl = dc.currentGLContext;

            gl.clearColor(dc.clearColor.red, dc.clearColor.green, dc.clearColor.blue, dc.clearColor.alpha);
            gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
        };

        WorldWindow.prototype.doDraw = function (dc) {
        };

        WorldWindow.prototype.createTerrain = function (dc) {
            this.drawContext.terrain = this.tessellator.tessellate(this.globe, dc.navigatorState,
                dc.verticalExaggeration);
        };

        return WorldWindow;
    }
)
;