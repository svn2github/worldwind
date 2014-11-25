/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */

define(function () {
    "use strict";

    function Vec2(x, y) {
        this[0] = x;
        this[1] = y;
    }

    Vec2.prototype = new Float64Array(2);

    Vec2.prototype.toArray = function (array, offset) {
        array[offset] = this[0];
        array[offset + 1] = this[1];

        return this;
    };

    Vec2.prototype.fromArray = function (array, offset) {
        this[0] = array[offset];
        this[1] = array[offset + 1];

        return this;
    };

    Vec2.prototype.add = function (vec) {
        var x = this[0] + vec[0],
            y = this[1] + vec[1];

        return new Vec2(x, y);
    };

    Vec2.prototype.subtract = function (vec) {
        var x = this[0] - vec[0],
            y = this[1] - vec[1];

        return new Vec2(x, y);
    };

    Vec2.prototype.multiply = function (vec) {
        var x = this[0] * vec[0],
            y = this[1] * vec[1];

        return new Vec2(x, y);
    };

    Vec2.prototype.scale = function (scale) {
        var x = this[0] * scale,
            y = this[1] * scale;

        return new Vec2(x, y);
    };

    Vec2.prototype.mix = function (vec, weight) {
        var w0 = 1 - weight,
            w1 = weight,
            x = this[0] * w0 + vec[0] * w1,
            y = this[1] * w0 + vec[1] * w1;

        return new Vec2(x, y);
    };

    Vec2.prototype.negate = function () {
        var x = -this[0],
            y = -this[1];

        return new Vec2(x, y);
    };

    Vec2.prototype.dot = function (vec) {
        return this[0] * vec[0] + this[1] * vec[1];
    };

    Vec2.prototype.getLengthSquared = function () {
        return this.dot(this);
    };

    Vec2.prototype.getLength = function () {
        return Math.sqrt(this.getLengthSquared());
    };

    Vec2.prototype.normalize = function () {
        var length = this.getLength(),
            lengthInverse = 1 / length,
            x = this[0] * lengthInverse,
            y = this[1] * lengthInverse;

        return new Vec2(x, y);
    };

    Vec2.prototype.distanceTo = function (vec) {
        var diff = this.subtract(vec);

        return diff.getLength();
    }

    return Vec2;
});