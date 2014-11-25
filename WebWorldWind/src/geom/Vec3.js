/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @version $Id$
 */

define([
        'src/util/Logger',
        'src/error/ArgumentError'
    ],
    function (Logger,
              ArgumentError) {
        "use strict";

        /**
         * Constructs a three component vector.
         * @alias Vec3
         * @classdesc Represents a three component vector.
         * @param x x component of vector
         * @param y y component of vector
         * @param z z component of vector
         * @constructor
         */
        function Vec3(x, y, z) {
            this[0] = x;
            this[1] = y;
            this[2] = z;
        }

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
         * Write a vector to an array at an offset.
         * @param {Array} array array to write
         * @param {number} offset initial index of array to write
         * @returns {Vec3} <code>this</code> returned in the "fluent" style
         */
        Vec3.prototype.toArray = function (array, offset) {
            var msg;
            if (!(array instanceof Array)) {
                msg = "Vec3.toArray: " + "generic.ArrayExpected - " + "array";
                Logger.log(Logger.LEVEL_SEVERE, msg);
                throw new ArgumentError(msg);
            }
            if (array.length < offset + Vec3.NUM_ELEMENTS) {
                msg = "Vec3.toArray: " + "generic.ArrayInvalidLength - " + "array";
                Logger.log(Logger.LEVEL_SEVERE, msg);
                throw new ArgumentError(msg);
            }

            array[offset] = this[0];
            array[offset + 1] = this[1];
            array[offset + 2] = this[2];

            return this;
        };

        /**
         * Write a vector to an array in homogeneous form.
         * @param {Array} array array to write
         * @param {number} offset initial index of array to write
         * @returns {Vec3} <code>this</code> returned in the "fluent" style
         */
        Vec3.prototype.toArray4 = function (array, offset) {
            var msg;
            if (!(array instanceof Array)) {
                msg = "Vec3.toArray4: " + "generic.ArrayExpected - " + "array";
                Logger.log(Logger.LEVEL_SEVERE, msg);
                throw new ArgumentError(msg);
            }
            if (array.length < offset + Vec3.NUM_ELEMENTS + 1) {
                msg = "Vec3.toArray4: " + "generic.ArrayInvalidLength - " + "array";
                Logger.log(Logger.LEVEL_SEVERE, msg);
                throw new ArgumentError(msg);
            }

            array[offset] = this[0];
            array[offset + 1] = this[1];
            array[offset + 2] = this[2];
            array[offset + 3] = 1;

            return this;
        };

        /**
         * Read a vector from an array.
         * @param {Array} array array to read
         * @param {number} offset initial index of array to read
         * @returns {Vec3} <code>this</code> returned in the "fluent" style
         */
        Vec3.prototype.fromArray = function (array, offset) {
            var msg;
            if (!(array instanceof Array)) {
                msg = "Vec3.fromArray: " + "generic.ArrayExpected - " + "array";
                Logger.log(Logger.LEVEL_SEVERE, msg);
                throw new ArgumentError(msg);
            }
            if (array.length < offset + Vec3.NUM_ELEMENTS) {
                msg = "Vec3.fromArray: " + "generic.ArrayInvalidLength - " + "array";
                Logger.log(Logger.LEVEL_SEVERE, msg);
                throw new ArgumentError(msg);
            }

            this[0] = array[offset];
            this[1] = array[offset + 1];
            this[2] = array[offset + 2];

            return this;
        };

        /**
         * Read a vector from an array in homogeneous form.
         * @param {Array} array array to read
         * @param {number} offset initial index of array to read
         * @returns {Vec3} <code>this</code> returned in the "fluent" style
         */
        Vec3.prototype.fromArray4 = function (array, offset) {
            var msg;
            if (!(array instanceof Array)) {
                msg = "Vec3.fromArray4: " + "generic.ArrayExpected - " + "array";
                Logger.log(Logger.LEVEL_SEVERE, msg);
                throw new ArgumentError(msg);
            }
            if (array.length < offset + Vec3.NUM_ELEMENTS + 1) {
                msg = "Vec3.fromArray4: " + "generic.ArrayInvalidLength - " + "array";
                Logger.log(Logger.LEVEL_SEVERE, msg);
                throw new ArgumentError(msg);
            }

            var w = array[offset + 3];

            this[0] = array[offset] / w;
            this[1] = array[offset + 1] / w;
            this[2] = array[offset + 2] / w;

            return this;
        };

        /**
         * Add a vector to <code>this</code> vector.
         * @param {Vec3} vec vector to add
         * @returns {Vec3} sum of two vectors
         */
        Vec3.prototype.add = function (vec) {
            var x = this[0] + vec[0],
                y = this[1] + vec[1],
                z = this[2] + vec[2];

            return new Vec3(x, y, z);
        };

        /**
         * Subtract a vector from <code>this</code> vector.
         * @param {Vec3} vec vector to subtract
         * @returns {Vec3} difference of two vectors
         */
        Vec3.prototype.subtract = function (vec) {
            var x = this[0] - vec[0],
                y = this[1] - vec[1],
                z = this[2] - vec[2];

            return new Vec3(x, y, z);
        };

        /**
         * Multiply a vector to <code>this</code> vector.
         * @param {Vec3} vec vector to multiply
         * @returns {Vec3} product of two vectors
         */
        Vec3.prototype.multiply = function (vec) {
            var x = this[0] * vec[0],
                y = this[1] * vec[1],
                z = this[2] * vec[2];

            return new Vec3(x, y, z);
        };

        /**
         * Multiply <code>this</code> vector by a scalar constant.
         * @param {number} scale scale factor
         * @returns {Vec3} product of <code>this</code> and scale factor
         */
        Vec3.prototype.scale = function (scale) {
            var x = this[0] * scale,
                y = this[1] * scale,
                z = this[2] * scale;

            return new Vec3(x, y, z);
        };

        /**
         * Mix (interpolate) a vector with <code>this</code> vector.
         * @param {Vec3} vec vector to mix
         * @param {number} weight relative weight of <code>this</code> vector
         * @returns {Vec3} a vector that is a blend of two vectors
         */
        Vec3.prototype.mix = function (vec, weight) {
            var w0 = 1 - weight,
                w1 = weight,
                x = this[0] * w0 + vec[0] * w1,
                y = this[1] * w0 + vec[1] * w1,
                z = this[2] * w0 + vec[2] * w1;

            return new Vec3(x, y, z);
        };

        /**
         * Negate <code>this</code> vector.
         * @returns {Vec3} <code>this</code> vector negated
         */
        Vec3.prototype.negate = function () {
            var x = -this[0],
                y = -this[1],
                z = -this[2];

            return new Vec3(x, y, z);
        };

        /**
         * Compute the scalar dot product of <code>this</code> vector and another vector.
         * @param {Vec3} vec vector to multiply
         * @returns {number} scalar dot product of two vectors
         */
        Vec3.prototype.dot = function (vec) {
            return this[0] * vec[0] +
                this[1] * vec[1] +
                this[2] * vec[2];
        };

        /**
         * Compute the cross product of <code>this</code> vector and another vector.
         * @param {Vec3} vec vector to multiply in cross product
         * @returns {Vec3} a vector that is mutually perpendicular to both vectors
         */
        Vec3.prototype.cross = function (vec) {
            var x = this[1] * vec[2] - this[2] * vec[1],
                y = this[2] * vec[0] - this[0] * vec[2],
                z = this[0] * vec[1] - this[1] * vec[0];

            return new Vec3(x, y, z);
        };

        /**
         * Compute the squared length of <code>this</code> vector.
         * @returns {number} squared magnitude of <code>this</code> vector
         */
        Vec3.prototype.getLengthSquared = function () {
            return this.dot(this);
        };

        /**
         * Compute the length of <code>this</code> vector.
         * @returns {number} the magnitude of <code>this</code> vector
         */
        Vec3.prototype.getLength = function () {
            return Math.sqrt(this.getLengthSquared());
        };

        /**
         * Construct a unit vector from <code>this</code> vector.
         * @returns {Vec3} a vector that is a unit vector
         */
        Vec3.prototype.normalize = function () {
            var length = this.getLength(),
                lengthInverse = 1 / length,
                x = this[0] * lengthInverse,
                y = this[1] * lengthInverse,
                z = this[2] * lengthInverse;

            return new Vec3(x, y, z);
        };

        /**
         * Compute the distance from <code>this</code> vector to another vector
         * @param {Vec3} vec other vector
         * @returns {number} distance between the vectors
         */
        Vec3.prototype.distanceTo = function (vec) {
            var diff = this.subtract(vec);

            return diff.getLength();
        };

        return Vec3;
    });