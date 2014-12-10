/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @version $Id$
 */
define([
        '../error/ArgumentError',
        '../geom/Line',
        '../util/Logger',
        '../geom/Vec3'],
    function (ArgumentError,
              Line,
              Logger,
              Vec3) {
        "use strict";
        /**
         * Provides math constants and functions.
         * @exports WWMath
         */
        var WWMath = {

            POSITIVE_ZERO: +0.0,

            NEGATIVE_ZERO: -0.0,

            isZero: function (value) {
                return value === this.POSITIVE_ZERO || value === this.NEGATIVE_ZERO;
            },

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
                // Use the built-in version if it exists. cbrt() is defined in ECMA6.
                if (typeof Math.cbrt == 'function')
                    return Math.cbrt(x);

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
            },

            /**
             * Computes the Cartesian intersection point of a specified line with an ellipsoid.
             * @param {Line} line The line for which to compute the intersection.
             * @param {Number} equatorialRadius The ellipsoid's major radius.
             * @param {Number} polarRadius The ellipsoid's minor radius.
             * @param {Vec3} result A pre-allocated{@Link Vec3} instance in which to return the computed point.
             * @returns {boolean} <code>true</code> if the line intersects the ellipsoid, otherwise <code>false</code>.
             * @throws {ArgumentError} If the specified line or result is null, undefined or not the correct type.
             */
            computeEllipsoidalGlobeIntersection: function (line, equatorialRadius, polarRadius, result) {
                if (!line instanceof Line) {
                    throw new ArgumentError(Logger.logMessage(Logger.LEVEL_SEVERE, "WWMath",
                        "computeEllipsoidalGlobeIntersection",
                        "The specified line is null, undefined or not a Line type"));
                }
                if (!result instanceof Vec3) {
                    throw new ArgumentError(Logger.logMessage(Logger.LEVEL_SEVERE, "WWMath",
                        "computeEllipsoidalGlobeIntersection", "missingResult"));
                }

                // Taken from "Mathematics for 3D Game Programming and Computer Graphics, Second Edition", Section 5.2.3.
                //
                // Note that the parameter n from in equations 5.70 and 5.71 is omitted here. For an ellipsoidal globe this
                // parameter is always 1, so its square and its product with any other value simplifies to the identity.

                var m = equatorialRadius / polarRadius, // ratio of the x semi-axis length to the y semi-axis length
                    m2 = m * m,
                    r2 = equatorialRadius * equatorialRadius, // nominal radius squared

                    vx = line.direction[0],
                    vy = line.direction[1],
                    vz = line.direction[2],
                    sx = line.origin[0],
                    sy = line.origin[1],
                    sz = line.origin[2],
                    a = vx * vx + m2 * vy * vy + vz * vz,
                    b = 2 * (sx * vx + m2 * sy * vy + sz * vz),
                    c = sx * sx + m2 * sy * sy + sz * sz - r2,
                    d = b * b - 4 * a * c, // discriminant
                    t;

                if (d < 0) {
                    return false;
                }
                else {
                    t = (-b - Math.sqrt(d)) / (2 * a);
                    line.pointAt(t, result);
                    return true;
                }
            },

            /**
             * Computes the absolute value of a specified value.
             * @param {Number} a The value whose absolute value to compute.
             * @returns {Number} The absolute value of the specified number.
             */
            fabs: function (a) {
                return a >= 0 ? a : -a;
            },

            /**
             * Computes the floating-point modulus of a specified number.
             * @param {Number} number The number whose modulus to compute.
             * @param {Number} modulus The modulus.
             * @returns {Number} The remainder after dividing the number by the modulus: <code>number % modulus</code>.
             */
            fmod: function (number, modulus) {
                // TODO: Verify that javascript's modulo operator produces same values as Java's fmod function.
                return number % modulus;
            },

            /**
             * Returns the maximum of two specified numbers.
             * @param {number} value1 The first value to compare.
             * @param {number} value2 The second value to compare.
             * @returns {number} The maximum of the two specified values.
             */
            max: function (value1, value2) {
                return value1 > value2 ? value1 : value2;
            },

            localCoordinateAxesAtPoint : function(origin, globe, xAxisResult, yAxisResult, zAxisResult) {
                // TODO
            },

            perspectiveFrustumRectangle: function(viewport, distance) {
                // TODO
            },

            horizontalDistanceFor: function (globeRadius, eyeAltitude) {
                // TODO
            },

            perspectiveNearDistanceForFarDistance: function (farDistance, farResolution, viewDeptBits) {
                // TODO
            },

            perspectiveNearDistance: function (viewport, distanceToSurface) {
                // TODO
            }
        };

        return WWMath;
    });