/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports MemoryCache
 * @version $Id$
 */
define([
        'src/error/ArgumentError',
        'src/util/Logger',
        'src/cache/MemoryCacheListener'
    ],
    function (ArgumentError,
              Logger,
              MemoryCacheListener) {
        "use strict";

        /**
         * Constructs a memory cache of a specified size.
         * @alias MemoryCache
         * @constructor
         * @classdesc Provides a fixed-size memory cache of key-value pairs.
         * @param capacity The cache's capacity, in bytes.
         * @param lowWater The number of bytes to clear the cache to when its capacity is exceeded.
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

            /**
             * The maximum number of bytes this cache may hold. This value is intended to be read-only and is specified
             * to the memory cache's constructor.
             * @type {Number}
             */
            this.capacity = capacity;

            /**
             * The number of bytes to clear this cache to when its capacity is exceeded. This value is intended to be
             * read-only and is specified to the memory cache's constructor.
             * @type {Number}
             */
            this.lowWater = lowWater;

            /**
             * The number of bytes currently used by this cache. This property is intended to be read-only.
             * @type {number}
             */
            this.usedCapacity = 0;

            /**
             * The number of bytes currently unused by this cache. This property is intended to be read-only.
             */
            this.freeCapacity = capacity;
        };

        /**
         * Returns the value for a specified key.
         * @param {Object} key The key of the value to return.
         * @returns {Object} The value associated with the specified key, or null if the key is not in the cache.
         */
        MemoryCache.prototype.valueForKey = function (key) {
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