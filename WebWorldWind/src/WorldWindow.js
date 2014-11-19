/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @version $Id$
 */

define(function () {
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
        if (!window.WebGLRenderingContext) {
            console.log("No WebGL");
            return;
        }

        var gl = this.canvas.getContext("webgl");

        gl.clearColor(1.0, 0.0, 0.0, 1.0);
        gl.clear(gl.COLOR_BUFFER_BIT);
    };

    return WorldWindow;
});