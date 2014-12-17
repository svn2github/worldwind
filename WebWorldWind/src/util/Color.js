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
        var Color = function(red, green, blue, alpha) {

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

        return Color;
    });