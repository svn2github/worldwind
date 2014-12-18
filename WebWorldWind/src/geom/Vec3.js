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
         * Constructs a three component vector.
         * @alias Vec3
         * @classdesc Represents a three component vector.
         * @param x x component of vector.
         * @param y y component of vector.
         * @param z z component of vector.
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
         * Vec3 inherits all methods and representation of FLoat64Array.
         * @type {Float64Array}
         */
        Vec3.prototype = new Float64Array(Vec3.NUM_ELEMENTS);

        /**
         * Computes the average of a specified array of points.
         * @param {Vec3[]} points The points whose average to compute.
         * @param {Vec3} result A pre-allocated Vec3 in which to return the computed average.
         * @returns {Vec3} The result argument set to the average of the specified lists of points.
         * @throws {ArgumentError} If the specified array of points is null, undefined or empty.
         */
        Vec3.average = function (points, result) {
            if (!points || points.length < 1) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Vec3", "average", "missingArray"));
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
         * @param x x component of vector.
         * @param y y component of vector.
         * @param z z component of vector.
         * @returns {Vec3} this vector returned in the "fluent" style.
         */
        Vec3.prototype.set = function(x, y, z) {
            this[0] = x;
            this[1] = y;
            this[2] = z;

            return this;
        };

        /**
         * Copy a vector.
         * @param {Vec3} vector The vector to copy.
         * @returns {Vec3} this vector returned in the "fluent" style.
         */
        Vec3.prototype.copy = function(vector) {
            this[0] = vector[0];
            this[1] = vector[1];
            this[2] = vector[2];

            return this;
        };

        /**
         * Write a vector to an array at an offset.
         * @param {number[]} array Array of numbers to write.
         * @param {number} offset Initial index of array to write.
         * @returns {Vec3} this vector returned in the "fluent" style.
         * @throws {ArgumentError} If the specified array is null, undefined, empty or too short.
         */
        Vec3.prototype.toArray = function (array, offset) {
            if (!array || array.length < offset + Vec3.NUM_ELEMENTS) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Vec3", "toArray", "missingArray"));
            }

            array[offset] = this[0];
            array[offset + 1] = this[1];
            array[offset + 2] = this[2];

            return this;
        };

        /**
         * Write a vector to an array in homogeneous form.
         * @param {number[]} array Array of numbers to write.
         * @param {number} offset Initial index of array to write.
         * @returns {Vec3} this vector returned in the "fluent" style.
         * @throws {ArgumentError} If the specified array is null, undefined, empty or too short.
         */
        Vec3.prototype.toArray4 = function (array, offset) {
            if (!array || array.length < offset + Vec3.NUM_ELEMENTS + 1) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Vec3", "toArray4", "missingArray"));
            }

            array[offset] = this[0];
            array[offset + 1] = this[1];
            array[offset + 2] = this[2];
            array[offset + 3] = 1;

            return this;
        };

        /**
         * Read a vector from an array.
         * @param {number[]} array Array of numbers to read.
         * @param {number} offset Initial index of array to read.
         * @returns {Vec3} this vector returned in the "fluent" style.
         * @throws {ArgumentError} If the specified array is null, undefined, empty or too short.
         */
        Vec3.prototype.fromArray = function (array, offset) {
            if (!array || array.length < offset + Vec3.NUM_ELEMENTS) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Vec3", "fromArray", "missingArray"));
            }

            this[0] = array[offset];
            this[1] = array[offset + 1];
            this[2] = array[offset + 2];

            return this;
        };

        /**
         * Read a vector from an array in homogeneous form.
         * @param {number[]} array Array of numbers to read.
         * @param {number} offset Initial index of array to read.
         * @returns {Vec3} this vector returned in the "fluent" style.
         * @throws {ArgumentError} If the specified array is null, undefined, empty or too short.
         */
        Vec3.prototype.fromArray4 = function (array, offset) {
            if (!array || array.length < offset + Vec3.NUM_ELEMENTS + 1) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Vec3", "fromArray4", "missingArray"));
            }

            var w = array[offset + 3];

            this[0] = array[offset] / w;
            this[1] = array[offset + 1] / w;
            this[2] = array[offset + 2] / w;

            return this;
        };

        /**
         * Add a vector to this vector, modifying this vector.
         * @param {Vec3} addend Vector to add.
         * @returns {Vec3} this vector returned in the "fluent" style.
         * @throws {ArgumentError} If the addend is null, undefined, or empty.
         */
        Vec3.prototype.add = function (addend) {
            this[0] += addend[0];
            this[1] += addend[1];
            this[2] += addend[2];

            return this;
        };

        /**
         * Subtract a vector from this vector, modifying this vector.
         * @param {Vec3} subtrahend vector to subtract
         * @returns {Vec3} this vector returned in the "fluent" style.
         * @throws {ArgumentError} If the subtrahend is null, undefined, or empty.
         */
        Vec3.prototype.subtract = function (subtrahend) {
            this[0] -= subtrahend[0];
            this[1] -= subtrahend[1];
            this[2] -= subtrahend[2];
        };

        /**
         * Multiply this vector by a constant factor, modifying this vector.
         * @param {number} scaler Constant factor to multiply.
         * @returns {Vec3} this vector returned in the "fluent" style.
         */
        Vec3.prototype.multiply = function (scaler) {
            this[0] *= scaler;
            this[1] *= scaler;
            this[2] *= scaler;

            return this;
        };

        /**
         * Divide this vector by a constant factor, modifying this vector.
         * @param {number} divisor Constant factor to divide.
         * @returns {Vec3} this vector returned in the "fluent" style.
         */
        Vec3.prototype.divide = function (divisor) {
            this[0] /= divisor;
            this[1] /= divisor;
            this[2] /= divisor;

            return this;
        };

        /**
         * Multiply this vector by a 4x4 matrix, modifying this vector.
         *
         * It is assumed that this vector has an implicit w component, which intereacts with the fourth
         * column of the matrix.
         *
         * The resultant w component of the product is then divided through the x, y, and z components.
         *
         * @param {Matrix} matrix Matrix to multiply.
         * @returns {Vec3} this vector returned in the "fluent" style.
         * @throws ArgumentError An invalid matrix argument was passed to this function.
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
         * Mix (interpolate) a vector with this vector, modifying this vector.
         * @param {Vec3} vector Vector to mix.
         * @param {number} weight Relative weight of this vector
         * @returns {Vec3} this vector returned in the "fluent" style.
         * @throws {ArgumentError} If the vector is null, undefined, or empty.
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
         * Negate this vector, modifying this vector.
         * @returns {Vec3} this vector returned in the "fluent" style.
         */
        Vec3.prototype.negate = function () {
            this[0] = -this[0];
            this[1] = -this[1];
            this[2] = -this[2];

            return this;
        };

        /**
         * Compute the scalar dot product of this vector and another vector.
         * @param {Vec3} vector vector to multiply
         * @returns {number} Scalar dot product of two vectors
         * @throws {ArgumentError} If the vector is null, undefined, or empty.
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
         * Compute the cross product of this vector and another vector, modifying this vector.
         * @param {Vec3} vector Vector to multiply in cross product
         * @returns {Vec3} this vector returned in the "fluent" style.
         * @throws {ArgumentError} If the vector is null, undefined, or empty.
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
         * @returns {number} Squared magnitude of this vector.
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
         * Construct a unit vector from this vector, modifying this vector.
         * @returns {Vec3} this vector returned in the "fluent" style.
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
         * Compute the squared distance from this vector to another vector.
         * @param {Vec3} vector Other vector
         * @returns {number} Squared distance between the vectors
         * @throws {ArgumentError} If the vector is null, undefined, or empty.
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
         * @param {Vec3} vector Other vector
         * @returns {number} Squared distance between the vectors
         * @throws {ArgumentError} If the vector is null, undefined, or empty.
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
         * @returns {Vec3} this vector returned in the "fluent" style.
         */
        Vec3.prototype.swap = function(that) {
            var tmp = this[0];
            this[0] = that[0];
            that[0] = tmp;

            var tmp = this[1];
            this[1] = that[1];
            that[1] = tmp;

            var tmp = this[2];
            this[2] = that[2];
            that[2] = tmp;

            return this;
        };

        return Vec3;
    }
);