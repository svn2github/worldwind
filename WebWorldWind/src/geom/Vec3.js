/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */

define(function () {
        "use strict";

        function Vec3(x, y, z) {
            this[0] = x;
            this[1] = y;
            this[2] = z;
        }

        Vec3.prototype = new Float64Array(3);

        Vec3.prototype.toArray = function (array, offset) {
            array[offset] = this[0];
            array[offset + 1] = this[1];
            array[offset + 2] = this[2];

            return this;
        };

        Vec3.prototype.toArray4 = function (array, offset) {
            array[offset] = this[0];
            array[offset + 1] = this[1];
            array[offset + 2] = this[2];
            array[offset + 3] = 1;

            return this;
        };

        Vec3.prototype.fromArray = function (array, offset) {
            this[0] = array[offset];
            this[1] = array[offset + 1];
            this[2] = array[offset + 2];

            return this;
        };

        Vec3.prototype.fromArray4 = function (array, offset) {
            var w = array[offset + 3];

            this[0] = array[offset] / w;
            this[1] = array[offset + 1] / w;
            this[2] = array[offset + 2] / w;

            return this;
        };

        Vec3.prototype.add = function (vec) {
            var x = this[0] + vec[0],
                y = this[1] + vec[1],
                z = this[2] + vec[2];

            return new Vec3(x, y, z);
        };

        Vec3.prototype.subtract = function (vec) {
            var x = this[0] - vec[0],
                y = this[1] - vec[1],
                z = this[2] - vec[2];

            return new Vec3(x, y, z);
        };

        Vec3.prototype.multiply = function (vec) {
            var x = this[0] * vec[0],
                y = this[1] * vec[1],
                z = this[2] * vec[2];

            return new Vec3(x, y, z);
        };

        Vec3.prototype.scale = function (scale) {
            var x = this[0] * scale,
                y = this[1] * scale,
                z = this[2] * scale;

            return new Vec3(x, y, z);
        };

        Vec3.prototype.mix = function (vec, weight) {
            var w0 = 1 - weight,
                w1 = weight,
                x = this[0] * w0 + vec[0] * w1,
                y = this[1] * w0 + vec[1] * w1,
                z = this[2] * w0 + vec[2] * w1;

            return new Vec3(x, y, z);
        };

        Vec3.prototype.negate = function () {
            var x = -this[0],
                y = -this[1],
                z = -this[2];

            return new Vec3(x, y, z);
        };

        Vec3.prototype.dot = function (vec) {
            return this[0] * vec[0] +
                this[1] * vec[1] +
                this[2] * vec[2];
        };

        Vec3.prototype.cross = function(vec) {
            var x = this[1] * vec[2] - this[2] * vec[1],
                y = this[2] * vec[0] - this[0] * vec[2],
                z = this[0] * vec[1] - this[1] * vec[0];
            
            return new Vec3(x, y, z);
        };

        Vec3.prototype.getLengthSquared = function () {
            return this.dot(this);
        };

        Vec3.prototype.getLength = function () {
            return Math.sqrt(this.getLengthSquared());
        };

        Vec3.prototype.normalize = function () {
            var length = this.getLength(),
                lengthInverse = 1 / length,
                x = this[0] * lengthInverse,
                y = this[1] * lengthInverse,
                z = this[2] * lengthInverse;
            
            return new Vec3(x, y, z);
        };

        Vec3.prototype.distanceTo = function (vec) {
            var diff = this.subtract(vec);
            
            return diff.getLength();
        };

        return Vec3;
    });