/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @version $Id$
 */

define(function () {
    "use strict";

    function WorldWindow(canvasName)
    {
        this.canvas = document.getElementById(canvasName);
        this.context = this.canvas.getContext("2d");
    }

    WorldWindow.prototype.drawScreen = function() {
        this.context.fillStyle = "#ffffaa";
        this.context.fillRect(0, 0, 500, 500);

        this.context.fillStyle = "#000000";
        this.context.font = "20px Sans-Serif";
        this.context.textBaseline = "top";
        this.context.fillText("Hello World Window!", 50, 80);
        //
        //var helloImage = new Image();
        //helloImage.onload = function(context) {
        //    this.context.drawImage(helloImage, 195, 80);
        //}.bind(this);
        //helloImage.src = "images/2DMode.png";

        this.context.strokeStyle = "#000000";
        this.context.strokeRect(5, 5, 490, 290);
    };

    return WorldWindow;
});