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
        mix: function (amount, value1, value2) {
            if (amount < 0)
                return value1;
            else if (amount > 1)
                return value2;

            return value1; // TODO: implement the mixing.
        }
    };

    return WWMath;
});