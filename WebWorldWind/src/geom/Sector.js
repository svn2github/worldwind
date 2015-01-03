/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports Sector
 * @version $Id$
 */
define([
        '../geom/Angle',
        '../error/ArgumentError',
        '../geom/Location',
        '../util/Logger'
    ],
    function (Angle,
              ArgumentError,
              Location,
              Logger) {
        "use strict";

        /**
         * Constructs a Sector from specified minimum and maximum latitudes and longitudes in degrees.
         * @alias Sector
         * @constructor
         * @classdesc Represents a rectangular region in geographic coordinates in degrees.
         * @param {Number} minLatitude the sector's minimum latitude in degrees.
         * @param {Number} maxLatitude the sector's maximum latitude in degrees.
         * @param {Number} minLongitude the sector's minimum longitude in degrees.
         * @param {Number} maxLongitude the sector's maximum longitude in degrees.
         */
        var Sector = function (minLatitude, maxLatitude, minLongitude, maxLongitude) {
            /**
             * This sector's minimum latitude in degrees.
             * @type {Number}
             */
            this.minLatitude = minLatitude;
            /**
             * This sector's maximum latitude in degrees.
             * @type {Number}
             */
            this.maxLatitude = maxLatitude;
            /**
             * This sector's minimum longitude in degrees.
             * @type {Number}
             */
            this.minLongitude = minLongitude;
            /**
             * This sector's maximum longitude in degrees.
             * @type {Number}
             */
            this.maxLongitude = maxLongitude;
        };

        /**
         * A sector with minimum and maximum latitudes and minimum and maximum longitudes all zero.
         * @constant
         * @type {Sector}
         */
        Sector.ZERO = new Sector(0, 0, 0, 0);

        /**
         * A sector that encompasses the full range of latitude ([-90, 90]) and longitude ([-180, 180]).
         * @constant
         * @type {Sector}
         */
        Sector.FULL_SPHERE = new Sector(-90, 90, -180, 180);

        /**
         * Sets this sector's latitudes and longitudes to those of a specified sector.
         * @param {Sector} sector The sector to copy.
         * @returns {Sector} This sector, initialized to the values of the specified sector.
         * @throws {ArgumentError} If the specified sector is null or undefined.
         */
        Sector.prototype.copy = function (sector) {
            if (!sector) {
                throw new ArgumentError(Logger.logMessage(Logger.LEVEL_SEVERE, "Sector", "copy", "missingSector"));
            }

            this.minLatitude = sector.minLatitude;
            this.maxLatitude = sector.maxLatitude;
            this.minLongitude = sector.minLongitude;
            this.maxLongitude = sector.maxLongitude;

            return this;
        };

        /**
         * Indicates whether this sector has width or height.
         * @returns {boolean} <code>true</code> if this sector's minimum and maximum latitudes or minimum and maximum
         * longitudes differ, otherwise <code>false</code>.
         */
        Sector.prototype.isEmpty = function () {
            return this.minLatitude === this.maxLatitude && this.minLongitude === this.maxLongitude;
        };

        /**
         * Returns the angle between this sector's minimum and maximum latitudes, in degrees.
         * @returns {Number} The difference between this sector's minimum and maximum latitudes, in degrees.
         */
        Sector.prototype.deltaLatitude = function () {
            return this.maxLatitude - this.minLatitude;
        };

        /**
         * Returns the angle between this sector's minimum and maximum longitudes, in degrees.
         * @returns {Number} The difference between this sector's minimum and maximum longitudes, in degrees.
         */
        Sector.prototype.deltaLongitude = function () {
            return this.maxLongitude - this.minLongitude;
        };

        /**
         * Returns the angle midway between this sector's minimum and maximum latitudes.
         * @returns {number} The mid-angle of this sector's minimum and maximum latitudes, in degrees.
         */
        Sector.prototype.centroidLatitude = function () {
            return 0.5 * (this.minLatitude + this.maxLatitude);
        };

        /**
         * Returns the angle midway between this sector's minimum and maximum longitudes.
         * @returns {number} The mid-angle of this sector's minimum and maximum longitudes, in degrees.
         */
        Sector.prototype.centroidLongitude = function () {
            return 0.5 * (this.minLongitude + this.maxLongitude);
        };

        /**
         * Computes the location of the angular center of this sector, which is the mid-angle of each of this sector's
         * latitude and longitude dimensions.
         * @param {Location} result A pre-allocated {@link Location} in which to return the computed centroid.
         * @returns {Location} The specified result argument containing the computed centroid.
         */
        Sector.prototype.centroid = function (result) {
            if (!result) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Sector", "centroid", "missingResult"));
            }

            result.latitude = this.centroidLatitude();
            result.longitude = this.centroidLongitude();

            return result;
        };

        /**
         * Returns this sector's minimum latitude in radians.
         * @returns {number} This sector's minimum latitude in radians.
         */
        Sector.prototype.minLatitudeRadians = function () {
            return this.minLatitude * Angle.DEGREES_TO_RADIANS;
        };

        /**
         * Returns this sector's maximum latitude in radians.
         * @returns {number} This sector's maximum latitude in radians.
         */
        Sector.prototype.maxLatitudeRadians = function () {
            return this.maxLatitude * Angle.DEGREES_TO_RADIANS;
        };

        /**
         * Returns this sector's minimum longitude in radians.
         * @returns {number} This sector's minimum longitude in radians.
         */
        Sector.prototype.minLongitudeRadians = function () {
            return this.minLongitude * Angle.DEGREES_TO_RADIANS;
        };

        /**
         * Returns this sector's maximum longitude in radians.
         * @returns {number} This sector's maximum longitude in radians.
         */
        Sector.prototype.maxLongitudeRadians = function () {
            return this.maxLongitude * Angle.DEGREES_TO_RADIANS;
        };

        /**
         * Modifies this sector to encompass an array of specified locations.
         * @param {Location[]} locations An array of locations. The array may be sparse.
         * @returns {Sector} This sector, modified to encompass all locations in the specified array.
         * @throws {ArgumentError} If the specified array is null, undefined or empty.
         */
        Sector.prototype.setToBoundingSector = function (locations) {
            if (!locations || locations.length < 1) {
                throw new ArgumentError(Logger.logMessage(Logger.LEVEL_SEVERE, "Sector", "setToBoundingSector",
                    "missingArray"));
            }

            for (var i = 0, len = locations.length; i < len; i++) {
                if (!locations[i])
                    continue;

                if (locations[i].latitude < this.minLatitude)
                    this.minLatitude = locations[i].latitude;
                if (locations[i].latitude > this.maxLatitude)
                    this.maxLatitude = locations[i].latitude;

                if (locations[i].longitude < this.minLongitude)
                    this.minLongitude = locations[i].longitude;
                if (locations[i].longitude > this.maxLongitude)
                    this.maxLongitude = locations[i].longitude;
            }

            return this;
        };

        /**
         * Indicates whether this sector intersects a specified sector.
         * This sector intersects the specified sector when each of sector's boundaries either overlap with the specified
         * sector or are adjacent to the specified sector.
         * @param {Sector} sector The sector to test intersection with. May be null or undefined, in which case this
         * function returns <code>false</code>.
         * @returns {boolean} <code>true</code> if the specifies sector intersections this sector, otherwise
         * <code>false</code>.
         */
        Sector.prototype.intersects = function (sector) {
            // Assumes normalized angles: [-90, 90], [-180, 180].
            return sector
                && this.minLongitude <= sector.maxLongitude
                && this.maxLongitude >= sector.minLongitude
                && this.minLatitude <= sector.maxLatitude
                && this.maxLatitude >= sector.minLatitude;
        };

        /**
         * Indicates whether this sector intersects a specified sector exclusive of the sector boundaries.
         * This sector overlaps the specified sector when the union of the two sectors defines a non-empty sector.
         * @param {Sector} sector The sector to test overlap with. May be null or undefined, in which case this
         * function returns <code>false</code>.
         * @returns {boolean} <code>true</code> if the specified sector overlaps this sector, otherwise
         * <code>false</code>.
         */
        Sector.prototype.overlaps = function (sector) {
            // Assumes normalized angles: [-90, 90], [-180, 180].
            return sector
                && this.minLongitude < sector.maxLongitude
                && this.maxLongitude > sector.minLongitude
                && this.minLatitude < sector.maxLatitude
                && this.maxLatitude > sector.minLatitude;
        };

        /**
         * Indicates whether this sector fully contains a specified sector.
         * This sector contains the specified sector when the specified sector's boundaries are completely contained within this
         * sector's boundaries, or are equal to this sector's boundaries.
         * @param {Sector} sector The sector to test containment with. May be null or undefined, in which case this
         * function returns <code>false</code>.
         * @returns {boolean} <code>true</code> if the specified sector contains this sector, otherwise
         * <code>false</code>.
         */
        Sector.prototype.contains = function (sector) {
            // Assumes normalized angles: [-90, 90], [-180, 180].
            return sector
                && this.minLatitude <= sector.minLatitude
                && this.maxLatitude >= sector.maxLatitude
                && this.minLongitude <= sector.minLongitude
                && this.maxLongitude >= sector.maxLongitude;
        };

        /**
         * Indicates whether this sector contains a specified geographic location.
         * @param {Number} latitude The location's latitude in degrees.
         * @param {Number} longitude The location's longitude in degrees.
         * @returns {boolean} <code>true</code> if this sector contains the location, otherwise <code>false</code>.
         */
        Sector.prototype.containsLocation = function (latitude, longitude) {
            // Assumes normalized angles: [-90, 90], [-180, 180].
            return this.minLatitude <= latitude
                && this.maxLatitude >= latitude
                && this.minLongitude <= longitude
                && this.maxLongitude >= longitude;
        };

        /**
         * Sets this sector to the intersection of itself and a specified sector.
         * @param {Sector} sector The sector to intersect with this one.
         * @returns {Sector} This sector, set to its intersection with the specified sector.
         * @throws {ArgumentError} If the specified sector is null or undefined.
         */
        Sector.prototype.intersection = function (sector) {
            if (!sector instanceof Sector) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Sector", "intersection", "missingSector"));
            }

            // Assumes normalized angles: [-180, 180], [-90, 90].
            if (this.minLatitude < sector.minLatitude)
                this.minLatitude = sector.minLatitude;
            if (this.maxLatitude > sector.maxLatitude)
                this.maxLatitude = sector.maxLatitude;
            if (this.minLongitude < sector.minLongitude)
                this.minLongitude = sector.minLongitude;
            if (this.maxLongitude > sector.maxLongitude)
                this.maxLongitude = sector.maxLongitude;

            // If the sectors do not overlap in either latitude or longitude, then the result of the above logic results in
            // the max being greater than the min. In this case, set the max to indicate that the sector is empty in
            // that dimension.
            if (this.maxLatitude < this.minLatitude)
                this.maxLatitude = this.minLatitude;
            if (this.maxLongitude < this.minLongitude)
                this.maxLongitude = this.minLongitude;

            return this;
        };

        /**
         * Sets this sector to the union of itself and a specified sector.
         * @param {Sector} sector The sector to union with this one.
         * @returns {Sector} This sector, set to its union with the specified sector.
         * @throws {ArgumentError} if the specified sector is null or undefined.
         */
        Sector.prototype.union = function (sector) {
            if (!sector instanceof Sector) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Sector", "union", "missingSector"));
            }

            // Assumes normalized angles: [-180, 180], [-90, 90].
            if (this.minLatitude > sector.minLatitude)
                this.minLatitude = sector.minLatitude;
            if (this.maxLatitude < sector.maxLatitude)
                this.maxLatitude = sector.maxLatitude;
            if (this.minLongitude > sector.minLongitude)
                this.minLongitude = sector.minLongitude;
            if (this.maxLongitude < sector.maxLongitude)
                this.maxLongitude = sector.maxLongitude;

            return this;
        };

        return Sector;
    });