/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports Sector
 * @version $Id$
 */
define([
        'src/util/Logger',
        'src/error/ArgumentError',
        'src/geom/Location',
        'src/geom/Angle'],
    function (Logger,
              ArgumentError,
              Location,
              Angle) {
        "use strict";

        /**
         * Constructs a Sector from specified minimum and maximum latitudes and longitudes in degrees.
         * @alias Sector
         * @constructor
         * @classdesc Represents a rectangular region in geographic coordinates.
         * @param {Number} minLatitude the sector's minimum latitude in degrees.
         * @param {Number} maxLatitude the sector's maximum latitude in degrees.
         * @param {Number} minLongitude the sector's minimum longitude in degrees.
         * @param {Number} maxLongitude the sector's maximum longitude in degrees.
         */
        var Sector = function (minLatitude, maxLatitude, minLongitude, maxLongitude) {
            /**
             * The minimum latitude in degrees.
             * @type {Number}
             */
            this.minLatitude = minLatitude;
            /**
             * The maximum latitude in degrees.
             * @type {Number}
             */
            this.maxlatitude = maxLatitude;
            /**
             * The minimum longitude in degrees.
             * @type {Number}
             */
            this.minLongitude = minLongitude;
            /**
             * The maximum longitude in degrees.
             * @type {Number}
             */
            this.maxLongitude = maxLongitude;
        }

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
         * Creates a new sector from a specified sector.
         * @param {Sector} sector The sector to copy.
         * @returns {Sector} The new sector, initialized to the values of the specified sector.
         * @throws {ArgumentError} If the specified sector is null or undefined.
         */
        Sector.fromSector = function (sector) {
            if (!sector) {
                var msg = "Sector.fromSector: Sector is null or undefined";
                Logger.log(Logger.LEVEL_SEVERE, msg);
                throw new ArgumentError(msg);
            }

            return new Sector(sector.minLatitude, sector.maxlatitude, sector.minLongitude, sector.maxLongitude);
        };

        /**
         * Creates a sector encompassing an array of specified locations.
         * @param {Array} locations An array of locations. The array may be sparse.
         * @returns {Sector} A sector that encompasses all locations in the specified array.
         * @throws {ArgumentError} If the specified array is null, undefined or empty.
         */
        Sector.fromLocations = function (locations) {
            if (!locations || locations.length < 1) {
                var msg = "Sector.fromLocations: Locations are null are undefined";
                Logger.log(Logger.LEVEL_SEVERE, msg);
                throw new ArgumentError(msg);
            }

            var sector = new Sector(
                locations[0].latitude, locations[0].latitude,
                locations[0].longitude, locations[0].longitude);

            for (var i = 1, len = locations.length; i < len; i++) {
                if (!locations[i])
                    continue;

                if (locations[i].latitude < sector.minLatitude)
                    sector.minLatitude = locations[i].latitude;
                if (locations[i].latitude > sector.maxLatitude)
                    sector.maxLatitude = locations[i].latitude;

                if (locations[i].longitude < sector.minLongitude)
                    sector.minLongitude = locations[i].longitude;
                if (locations[i].longitude > sector.maxLongitude)
                    sector.maxLongitude = locations[i].longitude;
            }

            return sector;
        };

        /**
         * Sets the minimum and maximum angles of this sector to those of a specified sector.
         * @param {Sector} sector The sector whose values this sector is to take on.
         * @throws {ArgumentError} if the specified sector is null or undefined.
         */
        Sector.prototype.set = function (sector) {
            if (!sector) {
                var msg = "Sector.set: Sector is null or undefined";
                Logger.log(Logger.LEVEL_SEVERE, msg);
                throw new ArgumentError(msg);
            }

            this.minLatitude = sector.minLatitude;
            this.maxLatitude = sector.maxLatitude;
            this.minLongitude = sector.minLongitude;
            this.maxLongitude = sector.maxLongitude;
        };

        /**
         * Indicates whether this sector was width or height.
         * @returns {boolean} <code>true</code> if this sectors minimum and maximum latitudes or minimum and maximum
         * longitudes differ, otherwise <code>false</code>.
         */
        Sector.prototype.isEmpty = function () {
            return this.minLatitude === this.maxlatitude && this.minLongitude === this.maxLongitude;
        };

        /**
         * Returns the angle between this sector's minimum and maximum latitudes, in degrees.
         * @returns {Number} The difference between this sector's minimum and maximum latitudes, in degrees.
         */
        Sector.prototype.deltaLatitude = function () {
            return this.maxlatitude - this.minLatitude;
        };

        /**
         * Returns the angle between this sector's minimum and maximum longitudes, in degrees.
         * @returns {Number} The difference between this sector's minimum and maximum longitudes, in degrees.
         */
        Sector.prototype.deltaLongitude = function () {
            return this.maxLongitude - this.minLongitude;
        };

        /**
         * Returns the latitude between this sector's minimum and maximum latitudes.
         * @returns {number} The mid-angle of this sector's minimum and maximum latitudes, in degrees.
         */
        Sector.prototype.centroidLatitude = function () {
            return 0.5 * (this.minLatitude + this.maxlatitude);
        };

        /**
         * Returns the longitude between this sector's minimum and maximum longitudes.
         * @returns {number} The mid-angle of this sector's minimum and maximum longitudes, in degrees.
         */
        Sector.prototype.centroidLongitude = function () {
            return 0.5 * (this.minLongitude + this.maxLongitude);
        };

        /**
         * Returns the location of the angular center of this sector, which is the mid-angle of each of this sector's
         * latitude and longitude dimensions.
         * @returns {Location} The location of this sector's angular center.
         */
        Sector.prototype.centroid = function () {
            return new Location(this.centroidLat(), this.centroidLon());
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
        Sector.prototype.maxLatitude = function () {
            return this.maxLatitude * Angle.DEGREES_TO_RADIANS;
        };

        /**
         * Returns this sector's minimum longitude in radians.
         * @returns {number} This sector's minimum longitude in radians.
         */
        Sector.prototype.minLongitude = function () {
            return this.minLongitude * Angle.DEGREES_TO_RADIANS;
        };

        /**
         * Returns this sector's maximum longitude in radians.
         * @returns {number} This sector's maximum longitude in radians.
         */
        Sector.prototype.maxLongitude = function () {
            return this.maxLongitude * Angle.DEGREES_TO_RADIANS;
        };

        /**
         * Indicates whether this sector intersects a specified sector.
         * @param {Sector} sector The sector to test intersection with.
         * @returns {boolean} <code>true</code> if the specifies sector intersections this sector. <code>false</code>
         * if the specified sector does not intersect this sector or the specified sector is null or undefined.
         */
        Sector.prototype.intersects = function (sector) {
            if (!sector)
                return false;

            // Assumes normalized angles: [-90, 90], [-180, 180].
            return this.minLongitude <= sector.maxLongitude
                && this.maxLongitude >= sector.minLongitude
                && this.minLatitude <= sector.maxLatitude
                && this.maxLatitude >= sector.minLatitude;
        };

        /**
         * Indicates whether this sector intersects a specified sector exclusive of the sector boundaries.
         * @param {Sector} sector The sector to test overlap with.
         * @returns {boolean} <code>true</code> if the specifies sector overlaps this sector. <code>false</code>
         * if the specified sector does not overlaps this sector or the specified sector is null or undefined.
         */
        Sector.prototype.overlaps = function (sector) {
            if (!sector)
                return false;

            // Assumes normalized angles: [-90, 90], [-180, 180].
            return this.minLongitude < sector.maxLongitude
                && this.maxLongitude > sector.minLongitude
                && this.minLatitude < sector.maxLatitude
                && this.maxLatitude > sector.minLatitude;
        };

        /**
         * Indicates whether this sector fully contains a specified sector.
         * @param {Sector} sector The sector to test containment with.
         * @returns {boolean} <code>true</code> if the specifies sector contains this sector. <code>false</code>
         * if the specified sector does not contain this sector or the specified sector is null or undefined.
         */
        Sector.prototype.contains = function (sector) {
            if (!sector)
                return false;

            // Assumes normalized angles: [-90, 90], [-180, 180].
            return this.minLatitude <= sector.minLatitude
                && this.maxLatitude >= sector.maxLatitude
                && this.minLongitude <= sector.minLongitude
                && this.maxLongitude >= sector.maxLongitude;
        };

        /**
         * Indicates whether this sector contains a specified location.
         * @param {Number} latitude The location's latitude in degrees.
         * @param {Number} longitude The location's longitude in degrees.
         * @returns {boolean} <code>true</code> if this sector contains the location. <code>false</code> if this
         * sector does not contain the location or the location is null or undefined.
         */
        Sector.prototype.containsLocation = function (latitude, longitude) {
            if (!sector)
                return false;

            // Assumes normalized angles: [-90, 90], [-180, 180].
            return this.minLatitude <= sector.latitude
                && this.maxLatitude >= sector.latitude
                && this.minLongitude <= sector.longitude
                && this.maxLongitude >= sector.longitude;
        };

        /**
         * Sets this sector to the intersection of it and a specified sector.
         * @param {Sector} sector The sector to intersect with this one.
         */
        Sector.prototype.intersection = function (sector) {
            if (!sector)
                return;

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
            // the max begin greater than the min. In this case, set the max to indicate that the sector is empty in
            // that dimension.
            if (this.maxLatitude < this.minLatitude)
                this.maxLatitude = this.minLatitude;
            if (this.maxLongitude < this.minLongitude)
                this.maxLongitude = this.minLongitude;
        };

        /**
         * Sets this sector to the union of it and a specified sector.
         * @param {Sector} sector The sector to union with this one.
         */
        Sector.prototype.union = function (sector) {
            if (!sector)
                return;

            // Assumes normalized angles: [-180, 180], [-90, 90].
            if (this.minLatitude > sector.minLatitude)
                this.minLatitude = sector.minLatitude;
            if (this.maxLatitude < sector.maxLatitude)
                this.maxLatitude = sector.maxLatitude;
            if (this.minLongitude > sector.minLongitude)
                this.minLongitude = sector.minLongitude;
            if (this.maxLongitude < sector.maxLongitude)
                this.maxLongitude = sector.maxLongitude;
        };

        return Sector;
    });