/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports GpuResourceCache
 * @version $Id$
 */
define([
        '../error/ArgumentError',
        '../util/Logger',
        '../cache/MemoryCache'
    ],
    function (ArgumentError,
              Logger,
              MemoryCache) {
        "use strict";

        /**
         * Constructs a GPU resource cache for a specified size and low-water value in bytes.
         * @alias GpuResourceCache
         * @constructor
         * @classdesc Maintains a cache of GPU resources such as textures and GLSL programs. The capacity of the
         * cache has units of bytes. Applications typically do not interact with this class.
         * @param {Number} capacity The cache capacity.
         * @param {Number} lowWater The number of bytes to clear the cache to when it exceeds its capacity.
         * @throws {ArgumentError} If the specified capacity is 0 or negative or the low-water value is negative.
         */
        var GpuResourceCache = function (capacity, lowWater) {
            if (capacity < 1) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "GpuResourceCache", "constructor",
                        "Specified cache capacity is 0 or negative."));
            }

            if (lowWater < 0) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "GpuResourceCache", "constructor",
                        "Specified cache low-water value is negative."));
            }

            this.entries = new MemoryCache(capacity, lowWater);
            this.entries.addCacheListener(this);
        };

        /**
         * Function called when a resource is removed from the underlying memory cache. This function disposes of the
         * associated WebGL resource.
         * @param {String} key The resource's key.
         * @param {Object} entry The memory cache entry removed.
         * @protected
         */
        GpuResourceCache.prototype.entryRemoved = function (key, entry) { // MemoryCacheListener method
            if (typeof entry.resource.dispose === 'function') {
                entry.resource.dispose(entry.gl);
            } else if (entry.resourceType === WorldWind.GPU_BUFFER) {
                entry.gl.deleteBuffer(entry.resource);
            }
        };

        /**
         * Function called when an error occurs while removing a resource from the underlying memory cache.
         * @param {Error} error The error that occurred.
         * @param {String} key The resource's key.
         * @param {Object} entry The memory cache entry removed.
         */
        GpuResourceCache.prototype.removalError = function (error, key, entry) { // MemoryCacheListener method
            Logger.logMessage(Logger.LEVEL_WARNING, "GpuResourceCahce", "removalError", key + "\n" + error.message);
        };

        /**
         * Indicates the capacity of this cache in bytes.
         * @returns {Number} The number of bytes of capacity in this cache.
         */
        GpuResourceCache.prototype.capacity = function () {
            return this.entries.capacity;
        };

        /**
         * Indicates the number of bytes currently used by this cache.
         * @returns {number} The number of bytes currently used by this cache.
         */
        GpuResourceCache.prototype.usedCapacity = function () {
            return this.entries.usedCapacity;
        };

        /**
         * Indicates the number of free bytes in this cache.
         * @returns {Number} The number of unused bytes in this cache.
         */
        GpuResourceCache.prototype.freeCapacity = function () {
            return this.entries.freeCapacity();
        };

        /**
         * Indicates the low-water value for this cache in bytes.
         * @returns {Number} The low-water value for this cache.
         */
        GpuResourceCache.prototype.lowWater = function () {
            return this.entries.lowWater;
        };

        /**
         * Specifies the capacity in bytes of this cache. If the capacity specified is less than this cache's low-water
         * value, the low-water value is set to 80% of the specified capacity. If the specified capacity is less than
         * the currently used capacity, the cache is trimmed to the (potentially new) low-water value.
         * @param {Number} capacity The capacity of this cache in bytes.
         * @throws {ArgumentError} If the specified capacity is less than or equal to 0.
         */
        GpuResourceCache.prototype.setCapacity = function (capacity) {
            if (capacity < 1) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "GpuResourceCache", "setCapacity",
                        "Specified cache capacity is 0 or negative."));
            }

            this.entries.setCapacity(capacity);
        };

        /**
         * Specifies the size in bytes that this cache is cleared to when it exceeds its capacity.
         * @param {number} lowWater The number of bytes to clear this cache to when it exceeds its capacity.
         * @throws {ArgumentError} If the specified low-water value is less than 0.
         */
        GpuResourceCache.prototype.setLowWater = function (lowWater) {
            if (lowWater < 0) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "GpuResourceCache", "setLowWater",
                        "Specified cache low-water value is negative."));
            }

            this.entries.lowWater = lowWater;
        };

        /**
         * Adds a specified resource to this cache. Replaces the existing resource for the specified key if the
         * cache currently contains a resource for that key.
         * @param {WebGLRenderingContext} gl The current WebGL context.
         * @param {String} key The key of the resource to add.
         * @param {Object} resource The resource to add to the cache.
         * @param {String} resourceType The type of resource. Recognized values are
         * [WorldWind.GPU_PROGRAM]{@link WorldWind#GPU_PROGRAM},
         * [WorldWind.GPU_TEXTURE]{@link WorldWind#GPU_TEXTURE}
         * and [WorldWind.GPU_BUFFER]{@link WorldWind#GPU_BUFFER}.
         * @param {Number} size The resource's size in bytes. Must be greater than 0.
         * @throws {ArgumentError} If any of the key, resource or resource-type arguments is null or undefined
         * or the specified size is less than 1.
         */
        GpuResourceCache.prototype.putResource = function (gl, key, resource, resourceType, size) {
            if (!key) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "GpuResourceCache", "putResource", "missingKey."));
            }

            if (!resource) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "GpuResourceCache", "putResource", "missingResource."));
            }

            if (!resourceType) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "GpuResourceCache", "putResource",
                        "The specified resource type is null or undefined."));
            }

            if (size < 1) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "GpuResourceCache", "putResource",
                        "The specified resource size is less than 1."));
            }

            var entry = {
                gl: gl,
                resource: resource,
                resourceType: resourceType
            };

            this.entries.putEntry(key, entry, size);
        };

        /**
         * Returns the resource associated with a specified key.
         * @param {String} key The key of the resource to find.
         * @returns {Object} The resource associated with the specified key, or null if the resource is not in
         * this cache or the specified key is null or undefined.
         */
        GpuResourceCache.prototype.resourceForKey = function (key) {
            var entry = this.entries.entryForKey(key);

            return entry ? entry.resource : null;
        };

        /**
         * Returns the GPU program associated with a specified key.
         * @param {String} key The key of the resource to find.
         * @returns {GpuProgram} The GPU program associated with the specified key, or null if the GPU program is not in
         * this cache, the specified key is null or undefined or the resource for that key is  not a GPU program.
         */
        GpuResourceCache.prototype.programForKey = function (key) {
            var entry = this.entries.entryForKey(key);

            return entry && entry.resourceType === WorldWind.GPU_PROGRAM ? entry.resource : null;
        };

        /**
         * Returns the texture associated with a specified key.
         * @param {String} key The key of the resource to find.
         * @returns {Texture} The texture associated with the specified key, or null if the texture is not in this
         * cache, the specified key is null or undefined or the resource associated with the key is not a texture.
         */
        GpuResourceCache.prototype.textureForKey = function (key) {
            var entry = this.entries.entryForKey(key);

            return entry && entry.resourceType === WorldWind.GPU_TEXTURE ? entry.resource : null;
        };

        /**
         * Indicates whether a specified resource is in this cache.
         * @param {String} key The key of the resource to find.
         * @returns {boolean} <code>true</code> If the resource is in this cache, <code>false</code> if the resource
         * is not in this cache or the specified key is null or undefined.
         */
        GpuResourceCache.prototype.containsResource = function (key) {
            return this.entries.containsKey(key);
        };

        /**
         * Removes the specified resource from this cache. The cache is not modified if the specified key is null or
         * undefined or does not correspond to an entry in the cache.
         * @param {String} key The key of the resource to remove.
         */
        GpuResourceCache.prototype.removeResource = function (key) {
            this.entries.removeEntry(key);
        };

        /**
         * Removes all resources from this cache.
         */
        GpuResourceCache.prototype.clear = function () {
            this.entries.clear();
        };

        return GpuResourceCache;
    });