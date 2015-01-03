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
         * This constructor does not normalize the components. It assumes that a unit normal vector is provided.
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
             * The normal vector to the plane.
             * @type {Vec3}
             */
            this.normal = new Vec3(x, y, z);

            /**
             * The negative of the plane's distance from the origin.
             * @type {Number}
             */
            this.distance = distance;
        };

        /**
         * Computes the dot product of this plane's normal vector with a specified vector.
         * Since the plane was defined with a unit normal vector, this function returns the distance of the vector from
         * the plane.
         * @param {Vec3} vector The vector to dot with this plane's normal vector.
         * @returns {Number} The computed dot product.
         * @throws {ArgumentError} If the specified vector is null or undefined.
         */
        Plane.prototype.dot = function (vector) {
            if (!vector) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Plane", "dot", "missingVector"));
            }

            return this.normal.dot(vector) + this.distance;
        };

        /**
         * Transforms this plane by a specified matrix.
         * @param {Matrix} matrix The matrix to apply to this plane.
         * @returns {Plane} This plane transformed by the specified matrix.
         * @throws {ArgumentError} If the specified matrix is null or undefined.
         */
        Plane.prototype.transformByMatrix = function (matrix){
            if (!matrix) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Plane", "transformByMatrix", "missingMatrix"));
            }

            var x = matrix[0] * this.normal[0] + matrix[1] * this.normal[1] + matrix[2] * this.normal[2] + matrix[3] * this.distance,
                y = matrix[4] * this.normal[0] + matrix[5] * this.normal[1] + matrix[6] * this.normal[2] + matrix[7] * this.distance,
                z = matrix[8] * this.normal[0] + matrix[9] * this.normal[1] + matrix[10] * this.normal[2] + matrix[11] * this.distance,
                distance = matrix[12] * this.normal[0] + matrix[13] * this.normal[1] + matrix[14] * this.normal[2] + matrix[15] * this.distance;

            this.normal[0] = x;
            this.normal[1] = y;
            this.normal[2] = z;
            this.distance = distance;
            
            return this;
        };

        /**
         * Normalizes the components of this plane.
         * @returns {Plane} This plane with its components normalized.
         */
        Plane.prototype.normalize = function () {
            var magnitude = this.normal.magnitude();

            if (magnitude === 0)
                return this;

            this.normal.divide(magnitude);
            this.distance /= magnitude;

            return this;
        };

        /**
         * Determines whether a specified line segment intersects this plane.
         *
         * @param {Vec3} endPoint1 The first end point of the line segment.
         * @param {Vec3} endPoint2 The second end point of the line segment.
         * @returns {boolean} <code>true</code> If the line segment intersects this plane, otherwise <code>false</code>.
         */
        Plane.prototype.isIntersecting = function(endPoint1, endPoint2) {
            var distance1 = this.dot(endPoint1),
                distance2 = this.dot(endPoint2);

            return distance1 * distance2 <= 0;
        };

        /**
         * Computes the intersection point of this plane with a specified line segment.
         *
         * @param {Vec3} endPoint1 The first end point of the line segment.
         * @param {Vec3} endPoint2 The second end point of the line segment.
         * @param {Vec3} result A variable in which to return the intersection point of the line segment with this plane.
         * @returns {boolean} <code>true</code> If the line segment intersects this plane, otherwise <code>false</code>.
         */
        Plane.prototype.intersectsAt = function (endPoint1, endPoint2, result) {
            // Compute the distance from the end-points.
            var distance1 = this.dot(endPoint1),
                distance2 = this.dot(endPoint2);

            // If both points points lie on the plane, ...
            if (distance1 === 0 && distance2 === 0) {
                // Choose an arbitrary endpoint as the intersection.
                result[0] = endPoint1[0];
                result[1] = endPoint1[1];
                result[2] = endPoint1[2];

                return true;
            }
            else if (distance1 === distance2) {
                // The intersection is undefined.
                return false;
            }

            var weight1 = -distance1 / (distance2 - distance1),
                weight2 = 1 - weight1;

            result[0] = weight1 * endPoint1[0] + weight2 * endPoint2[0];
            result[1] = weight1 * endPoint1[1] + weight2 * endPoint2[1];
            result[2] = weight1 * endPoint1[2] + weight2 * endPoint2[2];

            return distance1 * distance2 <= 0;
        };

        return Plane;
    });