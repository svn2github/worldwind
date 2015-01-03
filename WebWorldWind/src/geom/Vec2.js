/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @version $Id$
 */

define([
        '../util/Logger',
        '../error/ArgumentError',
        '../geom/Vec3'
    ],
    function (Logger,
              ArgumentError,
              Vec3) {
        "use strict";

        /**
         * Constructs a two-component vector.
         * @alias Vec2
         * @classdesc Represents a two-component vector.
         * @param x X component of vector.
         * @param y Y component of vector.
         * @constructor
         */
        var Vec2 = function Vec2(x, y) {
            this[0] = x;
            this[1] = y;
        };

        /**
         * Number of elements in a Vec2.
         * @type {number}
         */
        Vec2.NUM_ELEMENTS = 2;

        /**
         * Vec2 inherits all methods and representation of Float64Array.
         * @type {Float64Array}
         */
        Vec2.prototype = new Float64Array(Vec2.NUM_ELEMENTS);

        /**
         * Assign the components of a vector.
         * @param {Number} x X component of vector.
         * @param {Number} y Y component of vector.
         * @returns {Vec2} this vector with the specified components assigned.
         */
        Vec2.prototype.set = function(x, y) {
            this[0] = x;
            this[1] = y;

            return this;
        };

        /**
         * Copy a vector.
         * @param vector The vector to copy.
         * @returns {Vec2} this vector set to the values of the specified vector.
         */
        Vec2.prototype.copy = function(vector) {
            this[0] = vector[0];
            this[1] = vector[1];

            return this;
        };

        /**
         * Computes the average of a specified array of points.
         * @param {Vec2[]} points The points whose average to compute.
         * @param {Vec2} result A pre-allocated Vec2 in which to return the computed average.
         * @returns {Vec2} The result argument set to the average of the specified lists of points.
         * @throws {ArgumentError} If the specified array of points is null, undefined or empty.
         */
        Vec2.average = function (points, result) {
            if (!points || points.length < 1) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Vec2", "average", "missingArray"));
            }

            var count = points.length,
                vec;

            result[0] = 0;
            result[1] = 0;

            for (var i = 0, len = points.length; i < len; i++) {
                vec = points[i];

                result[0] += vec[0] / count;
                result[1] += vec[1] / count;
            }

            return result;
        };

        /**
         * Add a vector to this vector.
         * @param {Vec2} addend The vector to add.
         * @returns {Vec2} This vector after adding the specified vector to it.
         * @throws {ArgumentError} If the addend is null or undefined.
         */
        Vec2.prototype.add = function (addend) {
            this[0] += addend[0];
            this[1] += addend[1];

            return this;
        };

        /**
         * Subtract a vector from this vector.
         * @param {Vec2} subtrahend The vector to subtract from this one.
         * @returns {Vec2} this vector after subtracting the specified vector from it.
         * @throws {ArgumentError} If the subtrahend is null or undefined.
         */
        Vec2.prototype.subtract = function (subtrahend) {
            this[0] -= subtrahend[0];
            this[1] -= subtrahend[1];
        };

        /**
         * Multiply this vector by a scalar.
         * @param {number} scalar The scalar to multiply this vector by.
         * @returns {Vec2} This vector multiplied by the specified scalar.
         */
        Vec2.prototype.multiply = function (scalar) {
            this[0] *= scalar;
            this[1] *= scalar;

            return this;
        };

        /**
         * Divide this vector by a scalar.
         * @param {number} divisor The scalar to divide this vector by.
         * @returns {Vec2} This vector divided by the specified scalar.
         */
        Vec2.prototype.divide = function (divisor) {
            this[0] /= divisor;
            this[1] /= divisor;

            return this;
        };

        /**
         * Mix (interpolate) a specified vector with this vector, modifying this vector.
         * @param {Vec2} vector The vector to mix.
         * @param {number} weight The relative weight of this vector
         * @returns {Vec2} This vector modified to the mix of itself and the specified vector.
         * @throws {ArgumentError} If the specified vector is null or undefined.
         */
        Vec2.prototype.mix = function (vector, weight) {
            if (!vector) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Vec2", "mix", "missingVector"));
            }

            var w0 = 1 - weight,
                w1 = weight;

            this[0] = this[0] * w0 + vector[0] * w1;
            this[1] = this[1] * w0 + vector[1] * w1;

            return this;
        };

        /**
         * Negate this vector.
         * @returns {Vec2} this vector, negated.
         */
        Vec2.prototype.negate = function () {
            this[0] = -this[0];
            this[1] = -this[1];

            return this;
        };

        /**
         * Compute the scalar dot product of this vector and another vector.
         * @param {Vec2} vector The vector to multiply.
         * @returns {number} The scalar dot product of the vectors.
         * @throws {ArgumentError} If the vector is null or undefined.
         */
        Vec2.prototype.dot = function (vector) {
            if (!vector) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Vec2", "dot", "missingVector"));
            }

            return this[0] * vector[0] + this[1] * vector[1];
        };

        /**
         * Compute the squared magnitude of this vector.
         * @returns {number} The squared magnitude of this vector.
         */
        Vec2.prototype.magnitudeSquared = function () {
            return this.dot(this);
        };

        /**
         * Compute the magnitude of this vector.
         * @returns {number} The magnitude of this vector.
         */
        Vec2.prototype.magnitude = function () {
            return Math.sqrt(this.magnitudeSquared());
        };

        /**
         * Normalize this vector to a unit vector.
         * @returns {Vec2} this vector, normalized.
         */
        Vec2.prototype.normalize = function () {
            var magnitude = this.magnitude(),
                magnitudeInverse = 1 / magnitude;

            this[0] *= magnitudeInverse;
            this[1] *= magnitudeInverse;

            return this;
        };

        /**
         * Compute the squared distance from this vector to another vector.
         * @param {Vec2} vector The vector to compute the distance to.
         * @returns {number} The squared distance between the vectors.
         * @throws {ArgumentError} If the vector is null or undefined.
         */
        Vec2.prototype.distanceToSquared = function (vector) {
            if (!vector) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Vec2", "distanceToSquared", "missingVector"));
            }

            var dx = this[0] - vector[0],
                dy = this[1] - vector[1];

            return dx * dx + dy * dy;
        };

        /**
         * Compute the distance from this vector to another vector.
         * @param {Vec2} vector The vector to compute the distance to.
         * @returns {number} The distance between the vectors.
         * @throws {ArgumentError} If the vector is null or undefined.
         */
        Vec2.prototype.distanceTo = function (vector) {
            if (!vector) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Vec2", "distanceTo", "missingVector"));
            }

            return Math.sqrt(this.distanceToSquared(vector));
        };

        /**
         * Creates a {@link Vec3} using this vector's X and Y components and a Z component of 0.
         * @returns {Vec3} A new vector whose X and Y components are those of this vector and whose Z component is 0.
         */
        Vec2.prototype.toVec3 = function() {
            return new Vec3(this[0], this[1], 0);
        };

        /**
         * Swap this vector with that vector.
         * @param {Vec2} that The vector to swap.
         * @returns {Vec2} this vector.
         */
        Vec2.prototype.swap = function(that) {
            var tmp = this[0];
            this[0] = that[0];
            that[0] = tmp;

            var tmp = this[1];
            this[1] = that[1];
            that[1] = tmp;

            return this;
        };


        return Vec2;
    });