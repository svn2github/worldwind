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
        '../geom/Rectangle',
        '../geom/Vec3'],
    function (ArgumentError,
              Line,
              Logger,
              Rectangle,
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

            localCoordinateAxesAtPoint: function (origin, globe, xAxisResult, yAxisResult, zAxisResult) {
                // TODO
            },

            /**
             * Computes the distance to a globe's horizon from a viewer at a given altitude.
             *
             * Only the globe's ellipsoid is considered; terrain height is not incorporated. This returns zero if the radius is zero
             * or if the altitude is less than or equal to zero.
             *
             * @param {number} radius The globe's radius, in meters.
             * @param {number} altitude The viewer's altitude above the globe, in meters.
             * @returns {number} The distance to the horizon, in model coordinates.
             * @throws {ArgumentError} If the specified globe radius is negative.
             */
            horizonDistanceForGlobeRadius: function (radius, altitude) {
                if (radius < 0) {
                    throw new ArgumentError(Logger.logMessage(Logger.LEVEL_SEVERE, "WWMath",
                        "horizontalDistanceForGlobeRadius", "The specified globe radius is negative."));
                }

                return (radius > 0 && altitude > 0) ? Math.sqrt(altitude * (2 * radius + altitude)) : 0;
            },

            /**
             * Computes the near clip distance that corresponds to a specified far clip distance and resolution at the far clip
             * plane.
             *
             * This computes a near clip distance appropriate for use in [perspectiveFrustumRect]{@link WWMath#perspectiveFrustumRect}
             * and [setToPerspectiveProjection]{@link Matrix#setToPerspectiveProjection}. This returns zero if either the distance or the
             * resolution are zero.
             *
             * @param {number} farDistance The far clip distance, in meters.
             * @param {number} farResolution The depth resolution at the far clip plane, in meters.
             * @param {number} depthBits The number of bit-planes in the depth buffer.
             * @returns {number} The near clip distance, in meters.
             * @throws {ArgumentError} If either the distance or resolution is negative, or if the depth bits is less
             * than one.
             */
            perspectiveNearDistanceForFarDistance: function (farDistance, farResolution, depthBits) {
                if (farDistance < 0) {
                    throw new ArgumentError(Logger.logMessage(Logger.LEVEL_SEVERE, "WWMath", "perspectiveNearDistanceForFarDistance",
                        "The specified distance is negative."));
                }

                if (farResolution < 0) {
                    throw new ArgumentError(Logger.logMessage(Logger.LEVEL_SEVERE, "WWMath", "perspectiveNearDistanceForFarDistance",
                        "The specified resolution is negative."));
                }

                if (depthBits < 1) {
                    throw new ArgumentError(Logger.logMessage(Logger.LEVEL_SEVERE, "WWMath", "perspectiveNearDistanceForFarDistance",
                        "The specified depth bits is negative."));
                }

                var maxDepthValue = (1 << depthBits) - 1;

                return farDistance / (maxDepthValue / (1 - farResolution / farDistance) - maxDepthValue + 1);
            },

            /**
             * Computes the maximum near clip distance for a perspective projection that avoids clipping an object at a given
             * distance from the eye point.
             *
             * This computes a near clip distance appropriate for use in [perspectiveFrustumRect]{@link WWMath#perspectiveFrustumRect}
             * and [setToPerspectiveProjection]{@link Matrix#setToPerspectiveProjection}. The given distance should specify the
             * smallest distance between the eye and the object being viewed, but may be an approximation if an exact distance is not
             * required.
             *
             * The viewport is in the WebGL screen coordinate system, with its origin in the bottom-left corner and axes that extend
             * up and to the right from the origin point.
             *
             * @param {Rectangle} viewport The viewport rectangle, in WebGL screen coordinates.
             * @param {number} distanceToSurface The distance from the perspective eye point to the nearest object, in
             * meters.
             * @returns {number} The maximum near clip distance, in meters.
             * @throws {ArgumentError} If the specified viewport is null or undefined or either its width or height is
             * less than or equal to zero, or if the specified distance is negative.
             */
            perspectiveNearDistance: function (viewport, distanceToSurface) {
                if (!viewport) {
                    throw new ArgumentError(Logger.logMessage(Logger.LEVEL_SEVERE, "WWMath", "perspectiveNearDistance",
                        "missingViewport"));
                }

                if (viewport.width <= 0 || viewport.height <= 0) {
                    throw new ArgumentError(Logger.logMessage(Logger.LEVEL_SEVERE, "WWMath", "perspectiveNearDistance",
                        "invalidViewport"));
                }

                if (distanceToSurface < 0) {
                    throw new ArgumentError(Logger.logMessage(Logger.LEVEL_SEVERE, "WWMath", "perspectiveNearDistance",
                        "The specified distance is negative."));
                }

                // Compute the maximum near clip distance that avoids clipping an object at the specified distance from the eye.
                // Since the furthest points on the near clip rectangle are the four corners, we compute a near distance that puts
                // any one of these corners exactly at the given distance. The distance to one of the four corners can be expressed
                // in terms of the near clip distance, given distance to a corner 'd', near distance 'n', and aspect ratio 'a':
                //
                // d*d = x*x + y*y + z*z
                // d*d = (n*n/4 * a*a) + (n*n/4) + (n*n)
                //
                // Extracting 'n*n/4' from the right hand side gives:
                //
                // d*d = (n*n/4) * (a*a + 1 + 4)
                // d*d = (n*n/4) * (a*a + 5)
                //
                // Finally, solving for 'n' gives:
                //
                // n*n = 4 * d*d / (a*a + 5)
                // n = 2 * d / sqrt(a*a + 5)

                var aspect = (viewport.width < viewport.height) ?
                    (viewport.height / viewport.width) : (viewport.width / viewport.height);

                return 2 * distanceToSurface / Math.sqrt(aspect * aspect + 5);
            },

            /**
             * Computes the coordinates of a rectangle carved out of a perspective projection's frustum at a given distance in model
             * coordinates.
             *
             * This computes a frustum rectangle that preserves the scene's size relative to the viewport when the viewport width and
             * height are swapped. This has the effect of maintaining the scene's size on screen when the device is rotated.
             *
             * The viewport is in the WebGL screen coordinate system, with its origin in the bottom-left corner and axes that extend
             * up and to the right from the origin point.
             *
             * @param {Rectangle} viewport The viewport rectangle, in WebGL screen coordinates.
             * @param {number} distanceToSurface The distance along the negative Z axis, in model coordinates.
             * @returns {Rectangle} The frustum rectangle, in model coordinates.
             * @throws {ArgumentError} If the specified viewport is null or undefined or either its width or height is
             * less than or equal to zero, or if the specified distance is negative.
             */
            perspectiveFrustumRectangle: function (viewport, distanceToSurface) {
                if (!viewport) {
                    throw new ArgumentError(Logger.logMessage(Logger.LEVEL_SEVERE, "WWMath", "perspectiveFrustumRectangle",
                        "missingViewport"));
                }

                if (viewport.width <= 0 || viewport.height <= 0) {
                    throw new ArgumentError(Logger.logMessage(Logger.LEVEL_SEVERE, "WWMath", "perspectiveFrustumRectangle",
                        "invalidViewport"));
                }

                if (distanceToSurface < 0) {
                    throw new ArgumentError(Logger.logMessage(Logger.LEVEL_SEVERE, "WWMath", "perspectiveFrustumRectangle",
                        "The specified distance is negative."));
                }

                var viewportWidth = viewport.width,
                    viewportHeight = viewport.height,
                    x, y, width, height;

                // Compute a frustum rectangle that preserves the scene's size relative to the viewport when the viewport width and
                // height are swapped. This has the effect of maintaining the scene's size on screen when the device is rotated.

                if (viewportWidth < viewportHeight) {
                    width = distanceToSurface;
                    height = distanceToSurface * viewportHeight / viewportWidth;
                    x = -width / 2;
                    y = -height / 2;
                } else {
                    width = distanceToSurface * viewportWidth / viewportHeight;
                    height = distanceToSurface;
                    x = -width / 2;
                    y = -height / 2;
                }

                return new Rectangle(x, y, width, height);
            }
        };

        return WWMath;
    });