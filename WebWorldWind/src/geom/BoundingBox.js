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
        '../error/NotYetImplementedError',
        '../geom/Plane',
        '../geom/Sector',
        '../geom/Vec3',
        '../util/WWMath'
    ],
    function (ArgumentError,
              Frustum,
              GLobe,
              Logger,
              NotYetImplementedError,
              Plane,
              Sector,
              Vec3,
              WWMath) {
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

            /**
             * Working temporary vectors.
             * For internal use only.
             * @type {Vec3}
             */
            this.tmp1 = new Vec3(0, 0, 0);
            this.tmp2 = new Vec3(0, 0, 0);
            this.tmp3 = new Vec3(0, 0, 0);
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
            throw new NotYetImplementedError(
                Logger.logMessage(Logger.LEVEL_SEVERE, "BoundingBox", "setToPoints", "notYetImplemented"));

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

            var minLat = sector.minLatitude,
                maxLat = sector.maxLatitude,
                minLon = sector.minLongitude,
                maxLon = sector.maxLongitude,
                cenLat = sector.centroidLatitude(),
                cenLon = sector.centroidLongitude();

            // Compute the centroid point with the maximum elevation. This point is used to compute the local coordinate axes
            // at the sector's centroid, and to capture the maximum vertical dimension below.
            globe.computePointFromPosition(cenLat, cenLon, maxElevation, this.tmp1);

            // Compute the local coordinate axes. Since we know this box is bounding a geographic sector, we use the local
            // coordinate axes at its centroid as the box axes. Using these axes results in a box that has +-10% the volume of
            // a box with axes derived from a principal component analysis.
            WWMath.localCoordinateAxesAtPoint(this.tmp1, globe, this.r, this.s, this.t);

            // Find the extremes along each axis.
            var rExtremes = [Number.POSITIVE_INFINITY, Number.NEGATIVE_INFINITY],
                sExtremes = [Number.POSITIVE_INFINITY, Number.NEGATIVE_INFINITY],
                tExtremes = [Number.POSITIVE_INFINITY, Number.NEGATIVE_INFINITY];

            // A point at the centroid captures the maximum vertical dimension.
            this.adjustExtremes(this.r, rExtremes, this.s, sExtremes, this.t, tExtremes, this.tmp1);

            // Bottom-left corner with min elevation.
            globe.computePointFromPosition(minLat, minLon, minElevation, this.tmp1);
            this.adjustExtremes(this.r, rExtremes, this.s, sExtremes, this.t, tExtremes, this.tmp1);

            // Bottom-left corner with max elevation.
            globe.computePointFromPosition(minLat, minLon, maxElevation, this.tmp1);
            this.adjustExtremes(this.r, rExtremes, this.s, sExtremes, this.t, tExtremes, this.tmp1);

            // Bottom-right corner with min elevation.
            globe.computePointFromPosition(minLat, maxLon, minElevation, this.tmp1);
            this.adjustExtremes(this.r, rExtremes, this.s, sExtremes, this.t, tExtremes, this.tmp1);

            // Bottom-right corner with max elevation.
            globe.computePointFromPosition(minLat, maxLon, maxElevation, this.tmp1);
            this.adjustExtremes(this.r, rExtremes, this.s, sExtremes, this.t, tExtremes, this.tmp1);

            // Top-right corner with min elevation.
            globe.computePointFromPosition(maxLat, maxLon, minElevation, this.tmp1);
            this.adjustExtremes(this.r, rExtremes, this.s, sExtremes, this.t, tExtremes, this.tmp1);

            // Top-right corner with max elevation.
            globe.computePointFromPosition(maxLat, maxLon, maxElevation, this.tmp1);
            this.adjustExtremes(this.r, rExtremes, this.s, sExtremes, this.t, tExtremes, this.tmp1);

            // Top-left corner with min elevation.
            globe.computePointFromPosition(maxLat, minLon, minElevation, this.tmp1);
            this.adjustExtremes(this.r, rExtremes, this.s, sExtremes, this.t, tExtremes, this.tmp1);

            // Top-left corner with max elevation.
            globe.computePointFromPosition(maxLat, minLon, maxElevation, this.tmp1);
            this.adjustExtremes(this.r, rExtremes, this.s, sExtremes, this.t, tExtremes, this.tmp1);

            if (minLat < 0 && maxLat > 0) {
                // If the sector spans the equator then the curvature of all four edges needs to be considered. The extreme points
                // along the top and bottom edges are located at their mid-points and the extreme points along the left and right
                // edges are on the equator. Add points with the longitude of the sector's centroid but with the sector's min and
                // max latitude, and add points with the sector's min and max longitude but with latitude at the equator. See
                // WWJINT-225.
                globe.computePointFromPosition(minLat, cenLon, maxElevation, this.tmp1);
                this.adjustExtremes(this.r, rExtremes, this.s, sExtremes, this.t, tExtremes, this.tmp1);

                globe.computePointFromPosition(maxLat, cenLon, maxElevation, this.tmp1);
                this.adjustExtremes(this.r, rExtremes, this.s, sExtremes, this.t, tExtremes, this.tmp1);

                globe.computePointFromPosition(0, minLon, maxElevation, this.tmp1);
                this.adjustExtremes(this.r, rExtremes, this.s, sExtremes, this.t, tExtremes, this.tmp1);

                globe.computePointFromPosition(0, maxLon, maxElevation, this.tmp1);
                this.adjustExtremes(this.r, rExtremes, this.s, sExtremes, this.t, tExtremes, this.tmp1);
            }
            else if (minLat < 0) {
                // If the sector is located entirely in the southern hemisphere, then the curvature of its top edge needs to be
                // considered. The extreme point along the top edge is located at its mid-point. Add a point with the longitude
                // of the sector's centroid but with the sector's max latitude. See WWJINT-225.
                globe.computePointFromPosition(maxLat, cenLon, maxElevation, this.tmp1);
                this.adjustExtremes(this.r, rExtremes, this.s, sExtremes, this.t, tExtremes, this.tmp1);
            }
            else {
                // If the sector is located entirely within the northern hemisphere then the curvature of its bottom edge needs to
                // be considered. The extreme point along the bottom edge is located at its mid-point. Add a point with the
                // longitude of the sector's centroid but with the sector's min latitude. See WWJINT-225.
                globe.computePointFromPosition(minLat, cenLon, maxElevation, this.tmp1);
                this.adjustExtremes(this.r, rExtremes, this.s, sExtremes, this.t, tExtremes, this.tmp1);
            }

            if (maxLon - minLon > 180) { // Need to compute more points to ensure the box encompasses the full sector.
                // Centroid latitude, longitude midway between min longitude and centroid longitude.
                var lon = 0.5 * (minLon + cenLon);
                globe.computePointFromPosition(cenLat, lon, maxElevation, this.tmp1);
                this.adjustExtremes(this.r, rExtremes, this.s, sExtremes, this.t, tExtremes, this.tmp1);

                // Centroid latitude, longitude midway between centroid longitude and max longitude.
                lon = 0.5 * (maxLon + cenLon);
                globe.computePointFromPosition(cenLat, lon, maxElevation, this.tmp1);
                this.adjustExtremes(this.r, rExtremes, this.s, sExtremes, this.t, tExtremes, this.tmp1);

                // Centroid latitude, longitude at min longitude.
                globe.computePointFromPosition(cenLat, minLon, maxElevation, this.tmp1);
                this.adjustExtremes(this.r, rExtremes, this.s, sExtremes, this.t, tExtremes, this.tmp1);

                // Centroid latitude, longitude at max longitude.
                globe.computePointFromPosition(cenLat, maxLon, maxElevation, this.tmp1);
                this.adjustExtremes(this.r, rExtremes, this.s, sExtremes, this.t, tExtremes, this.tmp1);
            }

            // Sort the axes from most prominent to least prominent. The frustum intersection methods in WWBoundingBox assume
            // that the axes are defined in this way.
            
            if (rExtremes[1] - rExtremes[0] < sExtremes[1] - sExtremes[0]) {
                this.swapAxes(this.r, rExtremes, this.s, sExtremes);
            }
            if (sExtremes[1] - sExtremes[0] < tExtremes[1] - tExtremes[0]) {
                this.swapAxes(this.s, sExtremes, this.t, tExtremes);
            }
            if (rExtremes[1] - rExtremes[0] < sExtremes[1] - sExtremes[0]) {
                this.swapAxes(this.r, rExtremes, this.s, sExtremes);
            }
            
            // Compute the box properties from its unit axes and the extremes along each axis.
            var rLen = rExtremes[1] - rExtremes[0],
                sLen = sExtremes[1] - sExtremes[0],
                tLen = tExtremes[1] - tExtremes[0],
                rSum = rExtremes[1] + rExtremes[0],
                sSum = sExtremes[1] + sExtremes[0],
                tSum = tExtremes[1] + tExtremes[0],
            
                cx = 0.5 * (this.r[0] * rSum + this.s[0] * sSum + this.t[0] * tSum),
                cy = 0.5 * (this.r[1] * rSum + this.s[1] * sSum + this.t[1] * tSum),
                cz = 0.5 * (this.r[2] * rSum + this.s[2] * sSum + this.t[2] * tSum),
                rx_2 = 0.5 * this.r[0] * rLen,
                ry_2 = 0.5 * this.r[1] * rLen,
                rz_2 = 0.5 * this.r[2] * rLen;

            this.center.set(cx, cy, cz);
            this.topCenter.set(cx + rx_2, cy + ry_2, cz + rz_2);
            this.bottomCenter.set(cx - rx_2, cy - ry_2, cz - rz_2);

            this.r.multiply(rLen);
            this.s.multiply(sLen);
            this.t.multiply(tLen);

            this.radius = 0.5 * Math.sqrt(rLen * rLen + sLen * sLen + tLen * tLen);

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
            throw new NotYetImplementedError(
                Logger.logMessage(Logger.LEVEL_SEVERE, "BoundingBox", "translate", "notYetImplemented"));

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
            throw new NotYetImplementedError(
                Logger.logMessage(Logger.LEVEL_SEVERE, "BoundingBox", "distanceTo", "notYetImplemented"));

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
            throw new NotYetImplementedError(
                Logger.logMessage(Logger.LEVEL_SEVERE, "BoundingBox", "effectiveRadius", "notYetImplemented"));

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

            this.tmp1.copy(this.bottomCenter);
            this.tmp2.copy(this.topCenter);

            if (this.intersectionPoint(frustum.near) < 0) {
                return false;
            }
            /* TODO: investigate - this test fails
            if (this.intersectionPoint(frustum.far) < 0) {
                console.log("outside far");
                return false;
            }
            */
            if (this.intersectionPoint(frustum.left) < 0) {
                return false;
            }
            if (this.intersectionPoint(frustum.right) < 0) {
                return false;
            }
            if (this.intersectionPoint(frustum.top) < 0) {
                return false;
            }
            if (this.intersectionPoint(frustum.bottom) < 0) {
                return false;
            }

            return true;
        };

        BoundingBox.prototype.intersectionPoint = function(plane) {
            var n = plane.normal,
                effectiveRadius = 0.5 * (Math.abs(this.s.dot(n)) + Math.abs(this.t.dot(n))),
                intersection = this.intersectsAt(plane, effectiveRadius, this.tmp1, this.tmp2);

            return intersection;
        };

        BoundingBox.prototype.intersectsAt = function(plane, effRadius, endPoint1, endPoint2) {
            // Test the distance from the first end-point.
            var dq1 = plane.dot(endPoint1);
            var bq1 = dq1 <= -effRadius;

            // Test the distance from the second end-point.
            var dq2 = plane.dot(endPoint2);
            var bq2 = dq2 <= -effRadius;

            if (bq1 && bq2) { // endpoints more distant from plane than effective radius; box is on neg. side of plane
                return -1;
            }

            if (bq1 == bq2) { // endpoints less distant from plane than effective radius; can't draw any conclusions
                return 0;
            }

            // Compute and return the endpoints of the box on the positive side of the plane
            this.tmp3.copy(endPoint1);
            this.tmp3.subtract(endPoint2);
            var t = (effRadius + dq1) / plane.normal.dot(this.tmp3);

            this.tmp3.copy(endPoint2);
            this.tmp3.subtract(endPoint1);
            this.tmp3.multiply(t);
            this.tmp3.add(endPoint1);

            // Truncate the line to only that in the positive halfspace, e.g., inside the frustum.
            if (bq1) {
                endPoint1.copy(this.tmp3);
            }
            else {
                endPoint2.copy(this.tmp3);
            }

            return t;

        };

        BoundingBox.prototype.adjustExtremes = function(r,
                                                        rExtremes, 
                                                        s, 
                                                        sExtremes, 
                                                        t, 
                                                        tExtremes, 
                                                        p) {
            var pdr = p.dot(r);
            if (rExtremes[0] > pdr) {
                rExtremes[0] = pdr;
            }
            if (rExtremes[1] < pdr) {
                rExtremes[1] = pdr;
            }

            var pds = p.dot(s);
            if (sExtremes[0] > pds) {
                sExtremes[0] = pds;
            }
            if (sExtremes[1] < pds) {
                sExtremes[1] = pds;
            }

            var pdt = p.dot(t);
            if (tExtremes[0] > pdt) {
                tExtremes[0] = pdt;
            }
            if (tExtremes[1] < pdt) {
                tExtremes[1] = pdt;
            }
        };

        BoundingBox.prototype.swapAxes = function(a, 
                                                  aExtremes, 
                                                  b, 
                                                  bExtremes) {
            a.swap(b);

            var tmp = aExtremes[0];
            aExtremes[0] = bExtremes[0];
            bExtremes[0] = tmp;
            
            tmp = aExtremes[1];
            aExtremes[1] = bExtremes[1];
            bExtremes[1] = tmp;
        };

        return BoundingBox;
    });