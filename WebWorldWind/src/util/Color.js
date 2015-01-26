/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports Color
 * @version $Id$
 */
define([
        '../util/Logger'
    ],
    function (Logger) {
        "use strict";

        /**
         * Constructs a color from red, green, blue and alpha values.
         * @alias Color
         * @constructor
         * @classdesc Represents a red, green, blue, alpha, color.
         * @param {Number} red The red component, a number between 0 and 1.
         * @param {Number} green The green component, a number between 0 and 1.
         * @param {Number} blue The blue component, a number between 0 and 1.
         * @param {Number} alpha The alpha component, a number between 0 and 1.
         */
        var Color = function (red, green, blue, alpha) {

            /**
             * This color's red component.
             * @type {Number}
             */
            this.red = red;

            /**
             * This color's green component.
             * @type {Number}
             */
            this.green = green;

            /**
             * This color's blue component.
             * @type {Number}
             */
            this.blue = blue;

            /**
             * This color's alpha component.
             * @type {Number}
             */
            this.alpha = alpha;
        };

        /**
         * The color white.
         * @type {Color}
         * @constant
         */
        Color.WHITE = new Color(1, 1, 1, 1);

        /**
         * The color black.
         * @type {Color}
         * @constant
         */
        Color.BLACK = new Color(0, 0, 0, 1);

        /**
         * The color red.
         * @type {Color}
         * @constant
         */
        Color.RED = new Color(1, 0, 0, 1);

        /**
         * The color green.
         * @type {Color}
         * @constant
         */
        Color.GREEN = new Color(0, 1, 0, 1);

        /**
         * The color blue.
         * @type {Color}
         * @constant
         */
        Color.BLUE = new Color(0, 0, 1, 1);

        /**
         * The color cyan.
         * @type {Color}
         * @constant
         */
        Color.CYAN = new Color(0, 1, 1, 1);

        /**
         * The color yellow.
         * @type {Color}
         * @constant
         */
        Color.YELLOW = new Color(1, 1, 0, 1);

        /**
         * The color magenta.
         * @type {Color}
         * @constant
         */
        Color.MAGENTA = new Color(1, 0, 1, 1);

        /**
         * A light gray.
         * @type {Color}
         */
        Color.LIGHT_GRAY = new Color(0.75, 0.75, 0.75, 1);

        /**
         * A medium gray.
         * @type {Color}
         */
        Color.MEDIUM_GRAY = new Color(0.5, 0.5, 0.5, 1);

        /**
         * A dark gray.
         * @type {Color}
         */
        Color.DARK_GRAY = new Color(0.25, 0.25, 0.25, 1);

        /**
         * A transparent color.
         * @type {Color}
         */
        Color.TRANSPARENT = new Color(0, 0, 0, 0);

        /**
         * Returns this color's components premultiplied by this color's alpha component.
         * @param {Float32Array} array A pre-allocated array in which to return the color components.
         * @returns {Float32Array} This colors premultiplied components as an array, in the order RGBA.
         */
        Color.prototype.premultipliedComponents = function (array) {
            var a = this.alpha;

            array[0] = this.red * a;
            array[1] = this.green * a;
            array[2] = this.blue * a;
            array[3] = a;

            return array;
        };

        Color.colorFromBytes = function (bytes) {
            return new Color(bytes[0] / 255, bytes[1] / 255, bytes[2] / 255, bytes[3] / 255);
        };

        /**
         * Converts a color expressed in bytes to a number.
         * @param {Number} r The color's red component in the range [0, 255).
         * @param {Number} g The color's green component in the range [0, 255).
         * @param {Number} b The color's blue component in the range [0, 255).
         * @param {Number} a The color's alpha component in the range [0, 255).
         * @returns {number} A number representing the specified color components.
         */
        Color.makeColorIntFromBytes = function (r, g, b) {
            return r << 16 | g << 8 | b;
        };

        /**
         * Converts a color to a number.
         * @param {Color} color The color to convert.
         * @returns {number} A number representing the specified color.
         */
        Color.makeColorIntFromColor = function (color) {
            return Color.makeColorIntFromBytes(Math.round(color.red * 255), Math.round(color.green * 255), Math.round(color.blue * 255));
        };

        /**
         * Computes and sets this color to the next higher RBG color. If the color overflows, this color is set to
         * (1 / 255, 0, 0, *), where * indicates the current alpha value.
         * @returns {Color} This color, set to the next possible color.
         */
        Color.prototype.nextColor = function () {
            var rb = Math.round(this.red * 255),
                gb = Math.round(this.green * 255),
                bb = Math.round(this.blue * 255);

            if (rb < 255) {
                this.red = (rb + 1) / 255;
            } else if (gb < 255) {
                this.green = (gb + 1) / 255;
            } else if (bb < 255) {
                this.blue = (bb + 1) / 255;
            } else {
                this.red = 1 / 255;
                this.green = 0;
                this.blue = 0;
            }

            return this;
        };

        /**
         * Indicates whether this color is equal to a specified color after converting the floating-point component
         * values of each color to byte values.
         * @param {Color} color The color to test,
         * @returns {boolean} <code>true</code> if the colors are equal, otherwise false.
         */
        Color.prototype.equals = function (color) {
            var rbA = Math.round(this.red * 255),
                gbA = Math.round(this.green * 255),
                bbA = Math.round(this.blue * 255),
                abA = Math.round(this.alpha * 255),
                rbB = Math.round(color.red * 255),
                gbB = Math.round(color.green * 255),
                bbB = Math.round(color.blue * 255),
                abB = Math.round(color.alpha * 255);

            return rbA === rbB && gbA === gbB && bbA === bbB && abA === abB
        };

        /**
         * Indicates whether this color is equal to another color expressed as an array of bytes.
         * @param {Uint8Array} bytes The red, green, blue and alpha color components.
         * @returns {boolean} <code>true</code> if the colors are equal, otherwise false.
         */
        Color.prototype.equalsBytes = function (bytes) {
            var rb = Math.round(this.red * 255),
                gb = Math.round(this.green * 255),
                bb = Math.round(this.blue * 255),
                ab = Math.round(this.alpha * 255);

            return rb === bytes[0] && gb === bytes[1] && bb === bytes[2] && ab === bytes[3];
        };

        /**
         * Returns a string representation of this color, indicating the byte values corresponding to this color's
         * floating-point component values.
         * @returns {string}
         */
        Color.prototype.toByteString = function () {
            var rb = Math.round(this.red * 255),
                gb = Math.round(this.green * 255),
                bb = Math.round(this.blue * 255),
                ab = Math.round(this.alpha * 255);

            return "(" + rb + "," + gb + "," + bb + "," + ab + ")";
            return Color.makeColorIntFromBytes(color.red * 255, color.green * 255, color.blue * 255, color.alpha * 255);
        };

        /**
         * Create a hex color string that CSS and SVG can use. Optionally, inhibit capturing alpha,
         * because some uses don't like a four-component color specification.
         * @param isUsingAlpha Enable the use of an alpha component.
         * @returns {string} A color string suitable for CSS and SVG.
         */
        Color.prototype.toHexString = function(isUsingAlpha) {
            // Use Math.ceil() to get 0.75 to map to 0xc0. This is important is the display is dithering.
            var redHex = Math.ceil(this.red * 255).toString(16),
                greenHex = Math.ceil(this.green * 255).toString(16),
                blueHex = Math.ceil(this.blue * 255).toString(16),
                alphaHex = Math.ceil(this.alpha * 255).toString(16);

            var result = "#";
            result += (redHex.length < 2) ? ('0' + redHex) : redHex;
            result += (greenHex.length < 2) ? ('0' + greenHex) : greenHex;
            result += (blueHex.length < 2) ? ('0' + blueHex) : blueHex;
            if (isUsingAlpha) {
                result += (alphaHex.length < 2) ? ('0' + alphaHex) : alphaHex;
            }

            return result;
        };

        return Color;
    });