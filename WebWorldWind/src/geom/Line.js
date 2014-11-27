/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports Line
 * @version $Id$
 */
define([
        'src/error/ArgumentError',
        'src/util/Logger',
        'src/geom/Vec3'],
    function (ArgumentError,
              Logger,
              Vec3) {
        "use strict";

        /**
         * Constructs a line from an origin and direction.
         * @alias Line
         * @classdesc Represents a Cartesian line.
         * @param origin The line's origin.
         * @param direction The line's direction.
         * @constructor
         */
        var Line = function (origin, direction) {
            if (!(origin instanceof Vec3)) {
                throw new ArgumentError(Logger.logMessage(Logger.LEVEL_SEVERE, "Line", "constructor",
                    "Origin is null, undefined or not a Vec3 type."));
            }

            if (!(direction instanceof Vec3)) {
                throw new ArgumentError(Logger.logMessage(Logger.LEVEL_SEVERE, "Line", "constructor",
                    "Direction is null, undefined or not a Vec3 type."));
            }

            /**
             * The line's origin.
             * @type {Vec3}
             */
            this.origin = origin;

            /**
             * The line's direction.
             * @type {Vec3}
             */
            this.direction = direction;
        };

        /**
         * Computes a Cartesian point a specified distance along this line.
         * @param {Number} distance The distance at which to compute the point.
         * @param {Vec3} result A pre-allocated{@Link Vec3} instance in which to return the computed point.
         */
        Line.prototype.pointAt = function (distance, result) {
            if (!(result instanceof Vec3)) {
                throw new ArgumentError(Logger.logMessage(Logger.LEVEL_SEVERE, "Line", "pointAt", "missingResult."));
            }

            result[0] = this.origin[0] + this.direction[0] * distance;
            result[1] = this.origin[1] + this.direction[1] * distance;
            result[2] = this.origin[2] + this.direction[2] * distance;

            return result;
        };

        return Line;
    });