/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @version $Id$
 */
define(function () {
    /**
     * Provides math constants and functions.
     * @exports WWMath
     */
    var WWMath = {
        /**
         * Returns a number within the range of a specified minimum and maximum.
         * @param {Number} value The value to clamp.
         * @param {Number} minimum The minimum value to return.
         * @param {Number} maximum The maximum value to return.
         * @returns {Number} The minimum value if the specified value is less than the minimum, the maximum value if
         * the specified value is greater than the maximum, otherwise the value specified is returned.
         */
        clamp: function (value, minimum, maximum) {
            return value < minimum ? minimum : value > maximum ? maximum : value;
        },

        /**
         * Computes a number between two numbers.
         * @param amount {Number} The relative distance between the numbers at which to compute the new number. This
         * should normally be a number between 0 and 1 but whatever number is specified is applied.
         * @param {Number} value1 The first number.
         * @param {Number} value2 The second number.
         * @returns {Number} the computed value.
         */
        interpolate: function (amount, value1, value2) {
            return (1 - amount) * value1 + amount * value2;
        },

        /**
         * Returns the cube root of a specified value.
         * @param {Number} x The value whose cube root is computed.
         * @returns {Number} The cube root of the specified number.
         */
        cbrt: function (x) {
            // Taken from http://stackoverflow.com/questions/23402414/implementing-an-accurate-cbrt-function-without-extra-precision
            if (x == 0)
                return 0;
            if (x < 0)
                return -WWMath.cbrt(-x);

            var r = x;
            var ex = 0;

            while (r < 0.125) {
                r *= 8;
                ex--;
            }
            while (r > 1.0) {
                r *= 0.125;
                ex++;
            }

            r = (-0.46946116 * r + 1.072302) * r + 0.3812513;

            while (ex < 0) {
                r *= 0.5;
                ex++;
            }
            while (ex > 0) {
                r *= 2;
                ex--;
            }

            r = (2.0 / 3.0) * r + (1.0 / 3.0) * x / (r * r);
            r = (2.0 / 3.0) * r + (1.0 / 3.0) * x / (r * r);
            r = (2.0 / 3.0) * r + (1.0 / 3.0) * x / (r * r);
            r = (2.0 / 3.0) * r + (1.0 / 3.0) * x / (r * r);

            return r;
        }
    };

    return WWMath;
});