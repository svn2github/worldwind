/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports MemoryCache
 * @version $Id$
 */
define([
        '../error/ArgumentError',
        '../util/Logger',
        '../cache/MemoryCacheListener'
    ],
    function (ArgumentError,
              Logger,
              MemoryCacheListener) {
        "use strict";

        /**
         * Constructs a memory cache of a specified size.
         * @alias MemoryCache
         * @constructor
         * @classdesc Provides a fixed-size memory cache of key-value pairs. The meaning of size depends on usage.
         * Some instances of this class work in bytes while others work in counts. See the documentation for the
         * specific use to determine the size units.
         * @param capacity The cache's capacity.
         * @param lowWater The size to clear the cache to when its capacity is exceeded.
         * @throws {ArgumentError} If either the capacity is zero or negative, the low-water value is greater than
         * or equal to the capacity.
         */
        var MemoryCache = function (capacity, lowWater) {
            if (capacity < 1) {
                throw new ArgumentError(Logger.logMessage(Logger.LEVEL_SEVERE, "MemoryCache", "constructor",
                    "The specified capacity is zero or negative"));
            }

            if (lowWater >= capacity) {
                throw new ArgumentError(Logger.logMessage(Logger.LEVEL_SEVERE, "MemoryCache", "constructor",
                    "The specified low-water value is greater than or equal to the capacity"));
            }

            // Internal. Intentionally not documented.
            this.capacityHidden = capacity;

            /**
             * The size to clear this cache to when its capacity is exceeded. This value is intended to be
             * read-only and is specified to the memory cache's constructor.
             * @type {Number}
             */
            this.lowWater = lowWater;

            /**
             * The size currently used by this cache. This property is intended to be read-only.
             * @type {number}
             */
            this.usedCapacity = 0;

            /**
             * The size currently unused by this cache. This property is intended to be read-only.
             */
            this.freeCapacity = capacity;
        };

        /**
         * Specifies the capacity of this cache.
         * @param {Number} capacity The capacity of this cache. If the specified capacity is less than this cache's
         * low-water value, the low-water value is set to 85% of the specified capacity.
         * @throws {ArgumentError} If the specified capacity is less than or equal to 0.
         */
        MemoryCache.prototype.setCapacity = function (capacity) {
            if (capacity < 1) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "MemoryCache", "setCapacity",
                        "Specified cache capacity is 0 or negative."));
            }

            // TODO: Trim the cache to the new capacity if its less than the old capacity
            this.capacityHidden = capacity;

            if (this.capacityHidden < this.lowWater) {
                this.lowWater = 0.85 * this.capacityHidden;
            }
        };

        /**
         * The maximum size this cache may hold.
         * @returns {Number} This cache's capacity.
         */
        MemoryCache.prototype.capacity = function () {
            return this.capacityHidden;
        };

        /**
         * Returns the entry for a specified key.
         * @param {Object} key The key of the value to return.
         * @returns {Object} The entry associated with the specified key, or null if the key is not in the cache or
         * is null or undefined.
         */
        MemoryCache.prototype.entryForKey = function (key) {
            // TODO

            return null;
        };

        /**
         * Adds a specified key-value pair to this cache.
         * @param {Object} key The entry's key.
         * @param {Object} value The entry's value.
         */
        MemoryCache.prototype.addEntry = function (key, value) {
            // TODO
        };

        /**
         * Remove and entry from this cache.
         * @param {Object} key The key for the entry to remove.
         */
        MemoryCache.prototype.removeEntry = function (key) {
            // TODO
        };

        /**
         * Indicates whether a specified entry is in this cache.
         * @param {Object} key The key for the entry to search for.
         * @returns {boolean} <code>true</code> if the entry exists, otherwise <code>false</code>.
         */
        MemoryCache.prototype.containsKey = function (key) {
            // TODO

            return false;
        };

        /**
         * Adds a cache listener to this cache.
         * @param {MemoryCacheListener} listener The listener to add.
         */
        MemoryCache.prototype.addCacheListener = function (listener) {
            // TODO
        };

        /**
         * Removes a cache listener from this cache.
         * @param {MemoryCacheListener} listener The listener to remove.
         */
        MemoryCache.prototype.removeCacheListener = function (listener) {
            // TODO
        };

        return MemoryCache;
    });