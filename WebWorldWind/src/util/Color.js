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

            /**
             * The color white.
             * @type {Color}
             * @constant
             */
            this.WHITE = new Color(1, 1, 1, 1);

            /**
             * The color black.
             * @type {Color}
             * @constant
             */
            this.BLACK = new Color(0, 0, 0, 1);

            /**
             * The color red.
             * @type {Color}
             * @constant
             */
            this.RED = new Color(1, 0, 0, 1);

            /**
             * The color green.
             * @type {Color}
             * @constant
             */
            this.GREEN = new Color(0, 1, 0, 1);

            /**
             * The color blue.
             * @type {Color}
             * @constant
             */
            this.BLUE = new Color(0, 0, 1, 1);

            /**
             * The color cyan.
             * @type {Color}
             * @constant
             */
            this.CYAN = new Color(0, 1, 1, 1);

            /**
             * The color yellow.
             * @type {Color}
             * @constant
             */
            this.YELLOW = new Color(1, 1, 0, 1);

            /**
             * The color magenta.
             * @type {Color}
             * @constant
             */
            this.MAGENTA = new Color(1, 0, 1, 1);
        };

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