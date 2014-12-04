/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports BoundingBox
 * @version $Id$
 */
define([
        '../error/ArgumentError',
        '../geom/Frustum',
        '../globe/Globe',
        '../util/Logger',
        '../geom/Plane',
        '../geom/Sector',
        '../geom/Vec3'
    ],
    function (ArgumentError,
              Frustum,
              GLobe,
              Logger,
              Plane,
              Sector,
              Vec3) {
        "use strict";

        /**
         * Constructs a unit bounding box.
         * The unit box has its R, S and T axes aligned with the X, Y and Z axes, respectively, and has its length,
         * width and height set to 1.
         * @alias BoundingBox
         * @constructor
         * @classdesc Represents a bounding box in Cartesian coordinates. Typically used as a bounding volume.
         */
        var BoundingBox = function () {

            /**
             * The box's center point.
             * @type {Vec3}
             * @default (0, 0, 0)
             */
            this.center = new Vec3(0, 0, 0);

            /**
             * The center point of the box's bottom. (The origin of the R axis.)
             * @type {Vec3}
             * @default (-0.5, 0, 0)
             */
            this.bottomCenter = new Vec3(-0.5, 0, 0);

            /**
             * The center point of the box's top. (The end of the R axis.)
             * @type {Vec3}
             * @default (0.5, 0, 0)
             */
            this.topCenter = new Vec3(0.5, 0, 0);

            /**
             * The box's R axis, its longest axis.
             * @type {Vec3}
             * @default (1, 0, 0)
             */
            this.r = new Vec3(1, 0, 0);

            /**
             * The box's S axis, its mid-length axis.
             * @type {Vec3}
             * @default (0, 1, 0)
             */
            this.s = new Vec3(0, 1, 0);

            /**
             * The box's T axis, its shortest axis.
             * @type {Vec3}
             * @default (0, 0, 1)
             */
            this.t = new Vec3(0, 0, 1);

            /**
             * The box's radius.
             * @type {number}
             * @default sqrt(3)
             */
            this.radius = Math.sqrt(3);
        };

        /**
         * Sets this bounding box such that it minimally encloses a specified list of points.
         * @param {Vec3[]} points to contain.
         * @returns {BoundingBox} This bounding box set to contain the specified points.
         * @throws {ArgumentError} If the specified list of points is null, undefined or empty.
         */
        BoundingBox.prototype.setToPoints = function (points) {
            if (!points || points.length < 1) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "BoundingBox", "setToPoint", "missingArray"));
            }

            // TODO

            return this;
        };

        /**
         * Sets this bounding box such that it contains a specified sector on a specified globe with min and max elevation.
         * <p>
         * - To create a bounding box that contains the sector at mean sea level, specify zero for the minimum and maximum
         * elevations.
         * - To create a bounding box that contains the terrain surface in this sector, specify the actual minimum and maximum
         * elevation values associated with the sector, multiplied by the model's vertical exaggeration.
         * @param {Sector} sector The sector for which to create the bounding box.
         * @param {Globe} globe The globe associated with the sector.
         * @param {Number} minElevation The minimum elevation within the sector.
         * @param {Number} maxElevation The maximum elevation within the sector.
         * @returns {BoundingBox} This bounding box set to contain the specified sector.
         * @throws {ArgumentError} If either the specified sector or globe is null or undefined.
         */
        BoundingBox.prototype.setToSector = function (sector, globe, minElevation, maxElevation) {
            if (!sector) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "BoundingBox", "setToSector", "missingSector"));
            }

            if (!globe) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "BoundingBox", "setToSector", "missingGlobe"));
            }

            // TODO

            return this;
        };

        /**
         * Translates this bounding box be a specified translation vector.
         * @param {Vec3} translation The translation vector.
         * @returns {BoundingBox} This bounding box translated by the specified translation vector.
         * @throws {ArgumentError} If the specified translation vector is null or undefined.
         */
        BoundingBox.prototype.translate = function (translation) {
            if (!translation) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "BoundingBox", "translation", "missingVector"));
            }

            // TODO

            return this;
        };

        /**
         * Computes the approximate distance between this bounding box and a specified point.
         * <p>
         * This calculation treats the bounding box as a sphere with the same radius as the box.
         * @param {Vec3} point The point to compute the distance to.
         * @returns {Number} The distance from the edge of this bounding box to the specified point.
         * @throws {ArgumentError} If the specified point is null or undefined.
         */
        BoundingBox.prototype.distanceTo = function (point) {
            if (!point) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "BoundingBox", "distanceTo", "missingPoint"));
            }

            // TODO

            return 0;
        };

        /**
         * Computes the effective radius of this bounding box relative to a specified plane.
         * @param {Plane} plane The plane of interest.
         * @returns {Number} The effective radius of this bounding box to the specified plane.
         * @throws {ArgumentError} If the specified plane is null or undefined.
         */
        BoundingBox.prototype.effectiveRadius = function (plane) {
            if (!plane) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "BoundingBox", "effectiveRadius", "missingPlane"));
            }

            // TODO

            return 0;
        };

        /**
         * Indicates whether this bounding box intersects a specified frustum.
         * @param {Frustum} frustum The frustum of interest.
         * @returns {boolean} <code>true</code> if the specified frustum intersects this bounding box, otherwise
         * <code>false</code>.
         * @throws {ArgumentError} If the specified frustum is null or undefined.
         */
        BoundingBox.prototype.intersectsFrustum = function (frustum) {
            if (!frustum) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "BoundingBox", "intersectsFrustum", "missingFrustum"));
            }

            // TODO

            return false;
        };

        /**
         * Computes the parametric location at which a specified line intersects a specified plane of this box.
         *
         * This method is used by this box's [intersectsFrustum]{@link BoundingBox#intersectsFrustum} method and is not
         * intended for application use.
         *
         * This method accepts as an argument a line segment along the major axis of this box. Upon return,
         * the line segment is truncated at the point that it intersects the specified plane.
         *
         * @param {Plane} plane The plane to test.
         * @param {Number} effRadius The effective radius of this box relative to the specified plane.
         * @param {Vec3} endPoint1 The first end point of the line of interest. Potentially truncated upon return.
         * @param {Vec3} endPoint2 The second end point of the line of interest. Potentially truncated upon return.
         * @returns {Number} The parametric position along the line at which the line intersects the plane. If less
         * than zero, the end points are more distant from the plane than the effective radius and the line is on the
         * negative side of the plane.
         */
        BoundingBox.prototype.intersectsAt = function (plane, effRadius, endPoint1, endPoint2) {
            // TODO

            return 0;
        };

        return BoundingBox;
    });