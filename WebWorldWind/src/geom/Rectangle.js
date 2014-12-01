/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports Rectangle
 * @version $Id$
 */
define([
        'src/util/Logger'
    ],
    function (Logger) {
        "use strict";

        var Rectangle = function(x, y, width, height) {

            this.x = x;

            this.y = y;

            this.width = width;

            this.height = height;
        };

        Rectangle.prototype.getMinX = function() {
            return this.x;
        };

        Rectangle.prototype.getMinY = function() {
            return this.y;
        };

        Rectangle.prototype.getMaxX = function() {
            return this.x + this.width - 1;
        };

        Rectangle.prototype.getMaxY = function() {
            return this.y + this.height - 1;
        };

        return Rectangle;
    });