/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports Font
 * @version $Id: Font.js 2660 2015-01-20 19:20:11Z danm $
 */
define([
        '../error/ArgumentError',
        '../util/Color',
        '../util/Logger'
    ],
    function (ArgumentError,
              Color,
              Logger) {
        "use strict";

        /**
         * Construct a font descriptor.
         * Parameters are based on CSS parameters that HTML uses.
         * @param {number} size The size of font.
         * @param {string} style The style of the font.
         * @param {string} variant The variant of the font.
         * @param {number} weight The weight of the font.
         * @param {string} family The family of the font.
         * @param {Color} color The color of the font.
         * @param {Color} backgroundColor The background color of the font.
         * @param {string} horizontalAlignment The vertical alignment of the font.
         * @param {string} verticalAlignment The horizontal alignment of the font.
         * @alias Font
         * @constructor
         * @classdesc A font descriptor.
         */
        var Font = function(size, style, variant, weight, family, color, backgroundColor, horizontalAlignment, verticalAlignment) {
            if (!size) {
                throw new ArgumentError(Logger.logMessage(Logger.LEVEL_SEVERE, "Font", "constructor",
                    "missingSize"));
            }
            else if (size <= 0) {
                throw new ArgumentError(Logger.logMessage(Logger.LEVEL_SEVERE, "Font", "constructor",
                    "invalidSize"));
            }
            else {
                this.size = size;
            }

            this.style = style || Font.styles.default;
            this.variant = variant || Font.variants.default;
            this.weight = weight || Font.weights.default;
            this.family = family || Font.families.default;
            this.color = color || Color.WHITE;
            this.backgroundColor = backgroundColor || Color.TRANSPARENT;
            this.horizontalAlignment = horizontalAlignment || Font.horizontalAlignments.default;
            this.verticalAlignment = verticalAlignment || Font.verticalAlignments.default;
        };

        Font.styles = {
            'default': "normal",
            'normal': "normal",
            'italic': "italic",
            'oblique': "oblique"
        };

        Font.variants = {
            'default': "normal",
            'normal': "normal",
            'small-caps': "small-caps"
        };

        Font.weights = {
            'default': "normal",
            'normal': "normal",
            'bold': "bold",
            '100': "100",
            '200': "200",
            '300': "300",
            '400': "400",
            '500': "500",
            '600': "600",
            '700': "700",
            '800': "800",
            '900': "900"
        };

        Font.families = {
            'default': "monospace",
            'serif': "serif",
            'sans_serif': "sans-serif", // '-' is not a valid character in a variable name.
            'sans-serif': "sans-serif", // But you can still access it as a property.
            'cursive': "cursive",
            'fantasy': "fantasy",
            'monospace': "monospace"
        };

        Font.horizontalAlignments = {
            'default': "left",
            'start': "start",
            'left': "left",
            'center': "center",
            'right': "right",
            'end': "end"
        };

        Font.verticalAlignments = {
            'default': 'alphabetic',
            'bottom': "bottom",
            'alphabetic': "alphabetic",
            'middle': "middle",
            'hanging': "hanging",
            'top': "top"
        };

        return Font;
    }
);