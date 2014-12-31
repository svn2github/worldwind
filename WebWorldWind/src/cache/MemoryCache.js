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
        '../util/Logger'
    ],
    function (ArgumentError,
              Logger) {
        "use strict";

        /**
         * Constructs a memory cache of a specified size.
         * @alias MemoryCache
         * @constructor
         * @classdesc Provides a limited-size memory cache of key-value pairs. The meaning of size depends on usage.
         * Some instances of this class work in bytes while others work in counts. See the documentation for the
         * specific use to determine the size units.
         * @param {number} capacity The cache's capacity.
         * @param {number} lowWater The size to clear the cache to when its capacity is exceeded.
         * @throws {ArgumentError} If either the capacity is zero or negative or the low-water value is greater than
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
             * The maximum size this cache may hold. Use [setCapacity]{@link MemoryCache#setCapacity} to set the
             * capacity for this memory cache.
             * @type {number}
             * @readonly
             */
            this.capacity = capacity;

            /**
             * The size to clear this cache to when its capacity is exceeded. This value is initially specified to this
             * memory cache's constructor.
             * @type {Number}
             */
            this.lowWater = lowWater;

            /**
             * The size currently used by this cache.
             * @type {number}
             * @readonly
             */
            this.usedCapacity = 0;

            /**
             * The size currently unused by this cache.
             * @type {number}
             * @readonly
             */
            this.freeCapacity = capacity;

            // Internal. Intentionally not documented.
            // The cache entries.
            /**
             *  This cache's cache entries. Applications must not modify this object.
             * @type {{}}
             * @protected
             */
            this.entries = {};

            /**
             * The cache listeners associated with this memory cache. Applications must not modify this object.
             * @type {Array}
             * @protected
             */
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
         * @see [capacity]{@link MemoryCache#capacity}
         */
        MemoryCache.prototype.setCapacity = function (capacity) {
            if (capacity < 1) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "MemoryCache", "setCapacity",
                        "Specified cache capacity is 0 or negative."));
            }

            var oldCapacity = this.capacity;

            this.capacity = capacity;

            if (this.capacity <= this.lowWater) {
                this.lowWater = 0.85 * this.capacity;
            }

            // Trim the cache to the low-water mark if it's less than the old capacity
            if (this.capacity < oldCapacity) {
                this.makeSpace(0);
            }
        };

        /**
         * Returns the entry for a specified key.
         * @param {String} key The key of the entry to return.
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
         * @param {String} key The entry's key.
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

            if (this.usedCapacity + size > this.capacity) {
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
         * @param {String} key The key of the entry to remove. If null or undefined, this cache is not modified.
         */
        MemoryCache.prototype.removeEntry = function (key) {
            if (!key)
                return;

            var cacheEntry = this.entries[key];
            if (cacheEntry) {
                this.removeCacheEntry(cacheEntry);
            }
        };

        /**
         * Internal method to remove a cache entry. Applications should use [removeEntry]{@link MemoryCache#removeEntry}
         * to remove entries from this cache.
         * @param {Object} cacheEntry The entry to remove.
         * @protected
         * @see [removeEntry]{@link MemoryCache#removeEntry}
         */
        MemoryCache.prototype.removeCacheEntry = function (cacheEntry) {
            // All removal passes through this function.

            delete this.entries[cacheEntry.key];

            this.usedCapacity -= cacheEntry.size;
            this.freeCapacity = this.capacity - this.usedCapacity;

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
         * @param {String} key The key of the entry to search for.
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
         * @throws {ArgumentError} If the specified listener is null or undefined.
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

        /**
         * Clears this memory cache to that necessary to contain a specified amount of free space. This cache's used
         * capacity is reduced to its low-water value or to that necessary to hold the specified amount of space. This
         * cache's used capacity is reduced to zero if the specified required space is greater than this cache's
         * capacity.
         * @param {Number} spaceRequired The free space required.
         * @protected
         */
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