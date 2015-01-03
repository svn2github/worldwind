/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports Line
 * @version $Id$
 */
define([
        '../error/ArgumentError',
        '../util/Logger'],
    function (ArgumentError,
              Logger) {
        "use strict";

        /**
         * Constructs a line from a specified origin and direction.
         * @alias Line
         * @classdesc Represents a line in Cartesian coordinates.
         * @param {Vec3} origin The line's origin.
         * @param {Vec3} direction The line's direction.
         * @constructor
         */
        var Line = function (origin, direction) {
            if (!origin) {
                throw new ArgumentError(Logger.logMessage(Logger.LEVEL_SEVERE, "Line", "constructor",
                    "Origin is null or undefined."));
            }

            if (!direction) {
                throw new ArgumentError(Logger.logMessage(Logger.LEVEL_SEVERE, "Line", "constructor",
                    "Direction is null or undefined."));
            }

            /**
             * This line's origin.
             * @type {Vec3}
             */
            this.origin = origin;

            /**
             * This line's direction.
             * @type {Vec3}
             */
            this.direction = direction;
        };

        /**
         * Computes a Cartesian point a specified distance along this line.
         * @param {Number} distance The distance from this line's origin at which to compute the point.
         * @param {Vec3} result A pre-allocated {@Link Vec3} instance in which to return the computed point.
         * @returns {Vec3} The specified result argument containing the computed point.
         */
        Line.prototype.pointAt = function (distance, result) {
            if (!result) {
                throw new ArgumentError(Logger.logMessage(Logger.LEVEL_SEVERE, "Line", "pointAt", "missingResult."));
            }

            result[0] = this.origin[0] + this.direction[0] * distance;
            result[1] = this.origin[1] + this.direction[1] * distance;
            result[2] = this.origin[2] + this.direction[2] * distance;

            return result;
        };

        return Line;
    });