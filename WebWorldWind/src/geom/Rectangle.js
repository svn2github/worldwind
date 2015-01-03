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
         * Constructs a rectangle with a specified origin and size.
         * @alias Rectangle
         * @constructor
         * @classdesc Represents a rectangle in 2D Cartesian coordinates.
         * @param {Number} x The X coordinate of the rectangle's origin.
         * @param {Number} y The Y coordinate of the rectangle's origin.
         * @param {Number} width The rectangle's width.
         * @param {Number} height The rectangle's height.
         */
        var Rectangle = function(x, y, width, height) {

            /**
             * The X coordinate of this rectangle's origin.
             * @type {Number}
             */
            this.x = x;

            /**
             * The Y coordinate of this rectangle's origin.
             * @type {Number}
             */
            this.y = y;

            /**
             * This rectangle's width.
             * @type {Number}
             */
            this.width = width;

            /**
             * This rectangle's height.
             * @type {Number}
             */
            this.height = height;
        };

        /**
         * Returns the minimum X value of this rectangle.
         * @returns {Number} The rectangle's minimum X value.
         */
        Rectangle.prototype.getMinX = function() {
            return this.x;
        };

        /**
         * Returns the minimum Y value of this rectangle.
         * @returns {Number} The rectangle's minimum Y value.
         */
        Rectangle.prototype.getMinY = function() {
            return this.y;
        };

        /**
         * Returns the maximum X value of this rectangle.
         * @returns {Number} The rectangle's maximum X value.
         */
        Rectangle.prototype.getMaxX = function() {
            return this.x + this.width;
        };

        /**
         * Returns the maximum Y value of this rectangle.
         * @returns {Number} The rectangle's maximum Y value.
         */
        Rectangle.prototype.getMaxY = function() {
            return this.y + this.height;
        };

        return Rectangle;
    });