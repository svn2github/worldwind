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
             * The size currently used by this cache. This property is intended to be read-only and is computed
             * internally.
             * @type {number}
             */
            this.usedCapacity = 0;

            /**
             * The size currently unused by this cache. This property is intended to be read-only and is computed
             * internally.
             */
            this.freeCapacity = capacity;

            // Internal. Intentionally not documented.
            // The cache entries.
            this.entries = {};

            // Internal. Intentionally not documented.
            // The cache listeners.
            this.listeners = [];

            // Internal. Intentionally not documented.
            // Cache counter used to indicate the least recently used entry. Incremented each time an entry is accessed and
            // assigned to the associated entry's lastUsed ivar.
            this.entryUsedCounter = 0;
        };

        /**
         * Sets the capacity of this cache to a specified value.
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

            var oldCapacity = this.capacityHidden;

            this.capacityHidden = capacity;

            if (this.capacityHidden <= this.lowWater) {
                this.lowWater = 0.85 * this.capacityHidden;
            }

            // Trim the cache to the low-water mark if it's less than the old capacity
            if (this.capacityHidden < oldCapacity) {
                this.makeSpace(0);
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
         * @param {Object} key The key of the entry to return.
         * @returns {Object} The entry associated with the specified key, or null if the key is not in the cache or
         * is null or undefined.
         */
        MemoryCache.prototype.entryForKey = function (key) {
            if (!key)
                return null;

            var cacheEntry = this.entries[key];
            if (!cacheEntry)
                return null;

            cacheEntry.lastUsed = this.entryUsedCounter++;

            return cacheEntry.entry;
        };

        /**
         * Adds a specified entry to this cache.
         * @param {Object} key The entry's key.
         * @param {Object} entry The entry.
         * @param {Number} size The entry's size.
         * @throws {ArgumentError} If the specified key or entry is null or undefined or the specified size is less
         * than 1.
         */
        MemoryCache.prototype.putEntry = function (key, entry, size) {
            if (!key) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "MemoryCache", "putEntry", "missingKey."));
            }

            if (!entry) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "MemoryCache", "putEntry", "missingEntry."));
            }

            if (size < 1) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "MemoryCache", "putEntry",
                        "The specified entry size is less than 1."));
            }

            var existing = this.entries[key],
                cacheEntry;

            if (existing) {
                this.removeEntry(key);
            }

            if (this.usedCapacity + size > this.capacityHidden) {
                this.makeSpace(size);
            }

            this.usedCapacity += size;

            cacheEntry = {
                key: key,
                entry: entry,
                size: size,
                lastUsed: this.entryUsedCounter++
            };

            this.entries[key] = cacheEntry;
        };

        /**
         * Remove an entry from this cache.
         * @param {Object} key The key of the entry to remove.
         */
        MemoryCache.prototype.removeEntry = function (key) {
            if (!key)
                return null;

            var cacheEntry = this.entries[key];
            if (cacheEntry) {
                this.removeCacheEntry(cacheEntry);
            }
        };

        MemoryCache.prototype.removeCacheEntry = function (cacheEntry) {
            // All removal passes through this function.

            delete this.entries[cacheEntry.key];

            this.usedCapacity -= cacheEntry.size;
            this.freeCapacity = this.capacityHidden - this.usedCapacity;

            for (var i = 0, len = this.listeners.length; i < len; i++) {
                try {
                    this.listeners[i].entryRemoved(cacheEntry.key, cacheEntry.entry);
                } catch (e) {
                    this.listeners[i].removalError(e, cacheEntry.key, cacheEntry.entry);
                }
            }
        };

        /**
         * Indicates whether a specified entry is in this cache.
         * @param {Object} key The key of the entry to search for.
         * @returns {boolean} <code>true</code> if the entry exists, otherwise <code>false</code>.
         */
        MemoryCache.prototype.containsKey = function (key) {
            return key && this.entries[key];
        };

        /**
         * Adds a cache listener to this cache.
         * @param {MemoryCacheListener} listener The listener to add.
         * @throws {ArgumentError} If the specified listener is null or undefined or does not implement both the
         * entryRemoved and removalError functions.
         */
        MemoryCache.prototype.addCacheListener = function (listener) {
            if (!listener) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "MemoryCache", "addCacheListener",
                        "The specified listener is null or undefined."));
            }

            if (typeof listener.entryRemoved != "function" || typeof listener.removalError != "function") {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "MemoryCache", "addCacheListener",
                        "The specified listener does not implement the required functions."));
            }

            this.listeners.push(listener);
        };

        /**
         * Removes a cache listener from this cache.
         * @param {MemoryCacheListener} listener The listener to remove.
         */
        MemoryCache.prototype.removeCacheListener = function (listener) {
            if (!listener) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "MemoryCache", "removeCacheListener",
                        "The specified listener is null or undefined."));
            }

            var index = this.listeners.indexOf(listener);
            if (index > -1) {
                this.listeners.splice(index, 1);
            }
        };

        MemoryCache.prototype.makeSpace = function (spaceRequired) {
            var sortedEntries = [];

            // Sort the entries from least recently used to most recently used, then remove the least recently used entries
            // until the cache capacity reaches the low water and the cache has enough free capacity for the required
            // space.

            for (var entry in this.entries) {
                if (entry.hasOwnProperty('lastUsedTime')) {
                    sortedEntries.push(entry);
                }
            }

            sortedEntries.sort(function (a, b) {
                return a.lastUsed - b.lastUsed;
            });

            for (var i = 0, len = sortedEntries.length; i < len; i++) {
                if (this.usedCapacity > this.lowWater || this.freeCapacity < spaceRequired) {
                    this.removeCacheEntry(sortedEntries[i]);
                } else {
                    break;
                }
            }
        };

        return MemoryCache;
    });