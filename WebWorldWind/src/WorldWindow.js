/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports WorldWindow
 * @version $Id$
 */
define([
        'src/util/Logger'],
    function (Logger) {
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
        };

        /**
         * Redraws the window.
         */
        WorldWindow.prototype.render = function () {
            if (!window.WebGLRenderingContext) {
                Logger.log(Logger.LEVEL_SEVERE, "Canvas does not support WebGL");
                return;
            }

            var gl = this.canvas.getContext("webgl");

            gl.clearColor(1.0, 0.0, 0.0, 1.0);
            gl.clear(gl.COLOR_BUFFER_BIT);
        };

        return WorldWindow;
    });