/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @version $Id$
 */

define([
        'src/util/Logger',
        'src/error/ArgumentError',
        'src/geom/Vec3'
    ],
    function (Logger,
              ArgumentError,
              Vec3) {
        "use strict";

        /**
         * Constructs a two component vector.
         * @alias Vec2
         * @classdesc Represents a two component vector.
         * @param x x component of vector
         * @param y y component of vector
         * @constructor
         */
        function Vec2(x, y) {
            this[0] = x;
            this[1] = y;
        }

        /**
         * Number of elements in a Vec3.
         * @type {number}
         */
        Vec2.NUM_ELEMENTS = 2;

        /**
         * Vec2 inherits all methods and representation of FLoat64Array.
         * @type {Float64Array}
         */
        Vec2.prototype = new Float64Array(Vec2.NUM_ELEMENTS);

        /**
         * Write a vector to an array at an offset.
         * @param {Array} array array to write
         * @param {number} offset initial index of array to write
         * @returns {Vec2} <code>this</code> returned in the "fluent" style
         */
        Vec2.prototype.toArray = function (array, offset) {
            if (!array) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Vec2", "toArray", "missingArray"));
            }
            if (array.length < offset + Vec2.NUM_ELEMENTS) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Vec2", "toArray", "shortArray"));
            }
            array[offset] = this[0];
            array[offset + 1] = this[1];

            return this;
        };

        /**
         * Read a vector from an array.
         * @param {Array} array array to read
         * @param {number} offset initial index of array to read
         * @returns {Vec2} <code>this</code> returned in the "fluent" style
         */
        Vec2.prototype.fromArray = function (array, offset) {
            if (!array) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Vec2", "fromArray", "missingArray"));
            }
            if (array.length < offset + Vec2.NUM_ELEMENTS) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Vec2", "fromArray", "shortArray"));
            }

            this[0] = array[offset];
            this[1] = array[offset + 1];

            return this;
        };

        /**
         * Add a vector to <code>this</code> vector.
         * @param {Vec2} vec vector to add
         * @returns {Vec2} sum of two vectors
         */
        Vec2.prototype.add = function (vec) {
            var x = this[0] + vec[0],
                y = this[1] + vec[1];

            return new Vec2(x, y);
        };

        /**
         * Subtract a vector from <code>this</code> vector.
         * @param {Vec2} vec vector to subtract
         * @returns {Vec2} difference of two vectors
         */
        Vec2.prototype.subtract = function (vec) {
            var x = this[0] - vec[0],
                y = this[1] - vec[1];

            return new Vec2(x, y);
        };

        /**
         * Multiply a vector to <code>this</code> vector.
         * @param {Vec2} vec vector to multiply
         * @returns {Vec2} product of two vectors
         */
        Vec2.prototype.multiply = function (vec) {
            var x = this[0] * vec[0],
                y = this[1] * vec[1];

            return new Vec2(x, y);
        };

        /**
         * Multiply <code>this</code> vector by a scalar constant.
         * @param {number} scale scale factor
         * @returns {Vec2} product of <code>this</code> and scale factor
         */
        Vec2.prototype.scale = function (scale) {
            var x = this[0] * scale,
                y = this[1] * scale;

            return new Vec2(x, y);
        };

        /**
         * Mix (interpolate) a vector with <code>this</code> vector.
         * @param {Vec2} vec vector to mix
         * @param {number} weight relative weight of <code>this</code> vector
         * @returns {Vec2} a vector that is a blend of two vectors
         */
        Vec2.prototype.mix = function (vec, weight) {
            var w0 = 1 - weight,
                w1 = weight,
                x = this[0] * w0 + vec[0] * w1,
                y = this[1] * w0 + vec[1] * w1;

            return new Vec2(x, y);
        };

        /**
         * Negate <code>this</code> vector.
         * @returns {Vec2} <code>this</code> vector negated
         */
        Vec2.prototype.negate = function () {
            var x = -this[0],
                y = -this[1];

            return new Vec2(x, y);
        };

        /**
         * Compute the scalar dot product of <code>this</code> vector and another vector.
         * @param {Vec2} vec vector to multiply
         * @returns {number} scalar dot product of two vectors
         */
        Vec2.prototype.dot = function (vec) {
            return this[0] * vec[0] + this[1] * vec[1];
        };

        /**
         * Compute the squared length of <code>this</code> vector.
         * @returns {number} squared magnitude of <code>this</code> vector
         */
        Vec2.prototype.getLengthSquared = function () {
            return this.dot(this);
        };

        /**
         * Compute the length of <code>this</code> vector.
         * @returns {number} the magnitude of <code>this</code> vector
         */
        Vec2.prototype.getLength = function () {
            return Math.sqrt(this.getLengthSquared());
        };

        /**
         * Construct a unit vector from <code>this</code> vector.
         * @returns {Vec2} a vector that is a unit vector
         */
        Vec2.prototype.normalize = function () {
            var length = this.getLength(),
                lengthInverse = 1 / length,
                x = this[0] * lengthInverse,
                y = this[1] * lengthInverse;

            return new Vec2(x, y);
        };

        /**
         * Compute the distance from <code>this</code> vector to another vector
         * @param {Vec2} vec other vector
         * @returns {number} distance between the vectors
         */
        Vec2.prototype.distanceTo = function (vec) {
            var diff = this.subtract(vec);

            return diff.getLength();
        };

        /**
         * Construct a three dimensional vector from a two dimensional vector by augmenting a 0 z component.
         * @returns {Vec3} three dimensional version of <code>this</code> vector
         */
        Vec2.prototype.toVec3 = function () {
            return new Vec3(this[0], this[1], 0);
        };

        return Vec2;
    });