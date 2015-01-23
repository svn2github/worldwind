/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @version $Id$
 */

define([
        '../util/Logger',
        '../error/ArgumentError'
    ],
    function (Logger,
              ArgumentError) {
        "use strict";

        /**
         * Constructs a three-component vector.
         * @alias Vec3
         * @classdesc Represents a three-component vector.
         * @param x X component of vector.
         * @param y Y component of vector.
         * @param z Z component of vector.
         * @constructor
         */
        var Vec3 = function Vec3(x, y, z) {
            this[0] = x;
            this[1] = y;
            this[2] = z;
        };

        /**
         * Number of elements in a Vec3.
         * @type {number}
         */
        Vec3.NUM_ELEMENTS = 3;

        /**
         * Vec3 inherits all methods and representation of Float64Array.
         * @type {Float64Array}
         */
        Vec3.prototype = new Float64Array(Vec3.NUM_ELEMENTS);

        /**
         * Computes the average of a specified array of points.
         * @param {Vec3[]} points The points whose average to compute.
         * @param {Vec3} result A pre-allocated Vec3 in which to return the computed average.
         * @returns {Vec3} The result argument set to the average of the specified lists of points.
         * @throws {ArgumentError} If the specified array of points or the result argument is null or undefined..
         */
        Vec3.average = function (points, result) {
            if (!points || points.length < 1) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Vec3", "average", "missingArray"));
            }

            if (!result) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Vec3", "average", "missingResult"));
            }

            var count = points.length,
                vec;

            result[0] = 0;
            result[1] = 0;
            result[2] = 0;

            for (var i = 0, len = points.length; i < len; i++) {
                vec = points[i];

                result[0] += vec[0] / count;
                result[1] += vec[1] / count;
                result[2] += vec[2] / count;
            }

            return result;
        };

        /**
         * Assign the components of a vector.
         * @param x The X component of the vector.
         * @param y The Y component of the vector.
         * @param z The Z component of the vector.
         * @returns {Vec3} This vector with the specified components assigned.
         */
        Vec3.prototype.set = function (x, y, z) {
            this[0] = x;
            this[1] = y;
            this[2] = z;

            return this;
        };

        /**
         * Copy a vector.
         * @param {Vec3} vector The vector to copy.
         * @returns {Vec3} This vector set to the values of the specified vector.
         */
        Vec3.prototype.copy = function (vector) {
            this[0] = vector[0];
            this[1] = vector[1];
            this[2] = vector[2];

            return this;
        };

        /**
         * Add a vector to this vector.
         * @param {Vec3} addend The vector to add.
         * @returns {Vec3} this vector after adding the specified vector to it.
         * @throws {ArgumentError} If the addend is null or undefined.
         */
        Vec3.prototype.add = function (addend) {
            this[0] += addend[0];
            this[1] += addend[1];
            this[2] += addend[2];

            return this;
        };

        /**
         * Subtract a vector from this vector.
         * @param {Vec3} subtrahend The vector to subtract
         * @returns {Vec3} This vector after subtracting the specified vector from it.
         * @throws {ArgumentError} If the subtrahend is null or undefined.
         */
        Vec3.prototype.subtract = function (subtrahend) {
            this[0] -= subtrahend[0];
            this[1] -= subtrahend[1];
            this[2] -= subtrahend[2];

            return this;
        };

        /**
         * Multiply this vector by a scalar.
         * @param {number} scalar The scalar to multiply this vector by.
         * @returns {Vec3} This vector multiplied by the specified scalar.
         */
        Vec3.prototype.multiply = function (scalar) {
            this[0] *= scalar;
            this[1] *= scalar;
            this[2] *= scalar;

            return this;
        };

        /**
         * Divide this vector by a scalar.
         * @param {number} divisor The scalar to divide this vector by.
         * @returns {Vec3} This vector divided by the specified scalar.
         */
        Vec3.prototype.divide = function (divisor) {
            this[0] /= divisor;
            this[1] /= divisor;
            this[2] /= divisor;

            return this;
        };

        /**
         * Multiply this vector by a 4x4 matrix. The multiplication is performed with an implicit W component of 1.
         * The resultant W component of the product is then divided through the X, Y, and Z components.
         *
         * @param {Matrix} matrix The matrix to multiply this vector by.
         * @returns {Vec3} This vector multiplied by the specified matrix.
         * @throws ArgumentError If the specified matrix is null or undefined.
         */
        Vec3.prototype.multiplyByMatrix = function (matrix) {
            if (!matrix) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Vec3", "multiplyByMatrix", "missingMatrix"));
            }

            var x = matrix[0] * this[0] + matrix[1] * this[1] + matrix[2] * this[2] + matrix[3],
                y = matrix[4] * this[0] + matrix[5] * this[1] + matrix[6] * this[2] + matrix[7],
                z = matrix[8] * this[0] + matrix[9] * this[1] + matrix[10] * this[2] + matrix[11],
                w = matrix[12] * this[0] + matrix[13] * this[1] + matrix[14] * this[2] + matrix[15];

            this[0] = x / w;
            this[1] = y / w;
            this[2] = z / w;

            return this;
        };

        /**
         * Mix (interpolate) a specified vector with this vector, modifying this vector.
         * @param {Vec3} vector The vector to mix with this one.
         * @param {number} weight The relative weight of this vector.
         * @returns {Vec3} This vector modified to the mix of itself and the specified vector.
         * @throws {ArgumentError} If the specified vector is null or undefined.
         */
        Vec3.prototype.mix = function (vector, weight) {
            if (!vector) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Vec3", "mix", "missingVector"));
            }

            var w0 = 1 - weight,
                w1 = weight;

            this[0] = this[0] * w0 + vector[0] * w1;
            this[1] = this[1] * w0 + vector[1] * w1;
            this[2] = this[2] * w0 + vector[2] * w1;

            return this;
        };

        /**
         * Negate this vector.
         * @returns {Vec3} This vector, negated.
         */
        Vec3.prototype.negate = function () {
            this[0] = -this[0];
            this[1] = -this[1];
            this[2] = -this[2];

            return this;
        };

        /**
         * Compute the scalar dot product of this vector and a specified vector.
         * @param {Vec3} vector The vector to multiply.
         * @returns {number} The dot product of the two vectors.
         * @throws {ArgumentError} If the specified vector is null or undefined.
         */
        Vec3.prototype.dot = function (vector) {
            if (!vector) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Vec3", "dot", "missingVector"));
            }

            return this[0] * vector[0] +
                this[1] * vector[1] +
                this[2] * vector[2];
        };

        /**
         * Compute the cross product of this vector and a specified vector, modifying this vector.
         * @param {Vec3} vector The vector to cross with this vector.
         * @returns {Vec3} This vector set to the cross product of itself and the specified vector.
         * @throws {ArgumentError} If the specified vector is null or undefined.
         */
        Vec3.prototype.cross = function (vector) {
            if (!vector) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Vec3", "cross", "missingVector"));
            }

            var x = this[1] * vector[2] - this[2] * vector[1],
                y = this[2] * vector[0] - this[0] * vector[2],
                z = this[0] * vector[1] - this[1] * vector[0];

            this[0] = x;
            this[1] = y;
            this[2] = z;

            return this;
        };

        /**
         * Compute the squared magnitude of this vector.
         * @returns {number} The squared magnitude of this vector.
         */
        Vec3.prototype.magnitudeSquared = function () {
            return this.dot(this);
        };

        /**
         * Compute the magnitude of this vector.
         * @returns {number} The magnitude of this vector.
         */
        Vec3.prototype.magnitude = function () {
            return Math.sqrt(this.magnitudeSquared());
        };

        /**
         * Normalize this vector to a unit vector.
         * @returns {Vec3} This vector, normalized.
         */
        Vec3.prototype.normalize = function () {
            var magnitude = this.magnitude(),
                magnitudeInverse = 1 / magnitude;

            this[0] *= magnitudeInverse;
            this[1] *= magnitudeInverse;
            this[2] *= magnitudeInverse;

            return this;
        };

        /**
         * Compute the squared distance from this vector to a specified vector.
         * @param {Vec3} vector The vector to compute the distance to.
         * @returns {number} The squared distance between the vectors
         * @throws {ArgumentError} If the specified vector is null or undefined.
         */
        Vec3.prototype.distanceToSquared = function (vector) {
            if (!vector) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Vec3", "distanceToSquared", "missingVector"));
            }

            var dx = this[0] - vector[0],
                dy = this[1] - vector[1],
                dz = this[2] - vector[2];

            return dx * dx + dy * dy + dz * dz;
        };

        /**
         * Compute the distance from this vector to another vector.
         * @param {Vec3} vector The vector to compute the distance to.
         * @returns {number} The distance between the vectors.
         * @throws {ArgumentError} If the specified vector is null or undefined.
         */
        Vec3.prototype.distanceTo = function (vector) {
            if (!vector) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Vec3", "distanceTo", "missingVector"));
            }

            return Math.sqrt(this.distanceToSquared(vector));
        };

        /**
         * Swap this vector with that vector.
         * @param {Vec3} that The vector to swap.
         * @returns {Vec3} This vector set to the values of the specified vector.
         */
        Vec3.prototype.swap = function (that) {
            var tmp = this[0];
            this[0] = that[0];
            that[0] = tmp;

            tmp = this[1];
            this[1] = that[1];
            that[1] = tmp;

            tmp = this[2];
            this[2] = that[2];
            that[2] = tmp;

            return this;
        };

        return Vec3;
    }
);