/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports Rectangle
 * @version $Id$
 */
define([
        '../util/Logger'
    ],
    function (Logger) {
        "use strict";

        /**
         * Constructs a rectangle.
         * @alias Rectangle
         * @constructor
         * @classdesc Represents a rectangle in 2D Cartesian coordinates.
         * @param {Number} x The X coordinate of the rectangle's origin.
         * @param {Number} y The Y coordinate of the rectangle's origin.
         * @param {Number} width The rectangle's width.
         * @param {Number} height The rectangle's height.
         */
        var Rectangle = function(x, y, width, height) {

            this.x = x;

            this.y = y;

            this.width = width;

            this.height = height;
        };

        /**
         * Returns the minimum X value of the rectangle.
         * @returns {Number} The rectangle's minimum X value.
         */
        Rectangle.prototype.getMinX = function() {
            return this.x;
        };

        /**
         * Returns the minimum Y value of the rectangle.
         * @returns {Number} The rectangle's minimum Y value.
         */
        Rectangle.prototype.getMinY = function() {
            return this.y;
        };

        /**
         * Returns the maximum X value of the rectangle.
         * @returns {Number} The rectangle's maximum X value.
         */
        Rectangle.prototype.getMaxX = function() {
            return this.x + this.width;
        };

        /**
         * Returns the maximum Y value of the rectangle.
         * @returns {Number} The rectangle's maximum Y value.
         */
        Rectangle.prototype.getMaxY = function() {
            return this.y + this.height;
        };

        return Rectangle;
    });