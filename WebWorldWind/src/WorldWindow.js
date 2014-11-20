/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @version $Id$
 */

define(['src/util/Logger'], function (Logger) {
    "use strict";

    function WorldWindow(canvasName) {
        this.canvas = document.getElementById(canvasName);

        this.canvas.addEventListener("webglcontextlost", handleContextLost, false);
        this.canvas.addEventListener("webglcontextrestored", handleContextRestored, false);

        function handleContextLost(event)
        {
            event.preventDefault();
        }

        function handleContextRestored(event)
        {
        }
    }

    WorldWindow.prototype.render = function () {
        Logger.log(Logger.LEVEL_WARNING, "This is a test log message");

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