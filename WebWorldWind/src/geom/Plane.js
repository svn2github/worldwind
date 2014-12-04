/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports Plane
 * @version $Id$
 */
define([
        '../error/ArgumentError',
        '../util/Logger',
        '../geom/Vec3'
    ],
    function (ArgumentError,
              Logger,
              Vec3) {
        "use strict";

        /**
         * Constructs a plane.
         * This constructor does not normalize the components.
         * @alias Plane
         * @constructor
         * @classdesc Represents a plane in Cartesian coordinates.
         * The plane's X, Y and Z components indicate the plane's normal vector. The distance component
         * indicates the negative of the plane's distance from the origin. The components are expected to be normalized.
         * @param {Number} x The X coordinate of the plane's unit normal vector.
         * @param {Number} y The Y coordinate of the plane's unit normal vector.
         * @param {Number} z The Z coordinate of the plane's unit normal vector.
         * @param {Number} distance The negative of the plane's distance from the origin.
         */
        var Plane = function (x, y, z, distance) {

            /**
             * The X coordinate of the plane's unit normal vector.
             * @type {Number}
             */
            this.x = x;

            /**
             * The Y coordinate of the plane's unit normal vector.
             * @type {Number}
             */
            this.y = y;

            /**
             * The Z coordinate of the plane's unit normal vector.
             * @type {Number}
             */
            this.z = z;

            /**
             * The negative of the plane's distance from the origin.
             * @type {Number}
             */
            this.distance = distance;
        };

        /**
         * Computes the dot product of this plane's normal vector with a specified vector.
         * @param {Vec3} vector The vector to dot with this plane's normal vector.
         * @returns {Number} The computed dot product.
         * @throws {ArgumentError} If the specified vector is null or undefined.
         */
        Plane.prototype.dot = function (vector) {
            if (!vector) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Plane", "dot", "missingVector"));
            }

            return this.x * vector[0] + this.y * vector[1] + this.z * vector[2] + this.distance;
        };

        return Plane;
    });