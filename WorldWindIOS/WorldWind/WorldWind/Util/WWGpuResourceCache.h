/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WorldWind/Util/WWCacheable.h"
#import "WorldWind/Util/WWDisposable.h"
#import "WorldWind/Util/WWMemoryCacheListener.h"

@class WWMemoryCache;
@class WWGpuProgram;
@class WWTexture;

/**
* Provides a cache element for GPU resources. Used internally. Applications typically do not interact with GPU
* resource caches.
*/
@interface WWGpuResourceCacheEntry : NSObject <WWCacheable>

/// The type of GPU resource. One of WW_GPU_PROGRAM, WW_GPU_TEXTURE or WW_GPU_VBO.
@property(readonly) NSString* resourceType;

/// The actual resource.
@property(readonly) id resource;

/// The size of the resource.
@property long resourceSize;

/**
* Initialize the entry with a specified resource.
*
* Note: The resource size must be set separately.
*
* @param resource The resource ID.
* @param resourceType The resource type, one of WW_GPU_PROGRAM, WW_GPU_TEXTURE or WW_GPU_VBO.
*
* @return The initialized resource cache entry.
*/
- (WWGpuResourceCacheEntry*) initWithResource:(id)resource resourceType:(NSString*)resourceType;

/**
* Initialize the entry with a specified resource.
*
* @param resource The resource ID.
* @param resourceType The resource type, one of WW_GPU_PROGRAM, WW_GPU_TEXTURE or WW_GPU_VBO.
* @param size The resource size, in bytes.
*
* @return The initialized resource cache entry.
*/
- (WWGpuResourceCacheEntry*) initWithResource:(id)resource resourceType:(NSString*)resourceType size:(long)size;

@end


/**
* Provides a cache for GPU resources. Used internally. Applications typically do not interact with the GPU resource
* cache, which is associated with the draw context.
*/
@interface WWGpuResourceCache : NSObject <WWMemoryCacheListener>
{
@protected
    WWMemoryCache* resources;
}

/// @name GPU Resource Cache Attributes

/// The cache's capacity, in bytes.
- (long) capacity;

/**
* Specifies the cache's capacity, in bytes.
*
* @param newCapacity The cache's capacity, in bytes.
*/
- (void) setCapacity:(long)newCapacity;

/// The number of bytes currently used by the cache, relative to its capacity.
- (long) usedCapacity;

/// The number of bytes not currently used by the cache, relative to its capacity.
- (long) freeCapacity;

/// Indicates the number of bytes to which to clear the cache when it exceeds its capacity.
- (long) lowWater;

/**
* Specifies the number of bytes to which to clear the cache when it exceeds its capacity.
*
* @param lowWater The number of bytes to which to clear the cache when it exceeds its capacity.
*/
- (void) setLowWater:(long)lowWater;

/**
* Indicates the size of a specified entry.
*
* @param entry The entry in question.
*
* @return The entry's size, or 0 if the size is not known.
*/
- (long) entrySize:(WWGpuResourceCacheEntry*)entry;

/// @name Initializing Caches

/**
* Initialize the cache with a specified capacity and low-water values.
*
* @param lowWater The number of bytes to which to clear the cache when it exceeds its capacity.
* @param capacity The cache's capacity, in bytes.
*
* @return This cache instance, initialized to the specified values.
*/
- (WWGpuResourceCache*) initWithLowWater:(long)lowWater capacity:(long)capacity;

/// @name Adding, Retrieving and Removing Cache Resources

/**
* Add a resource to the cache.
*
* @param resource The resource to add.
* @param resourceType The type of resource being added, one of WW_GPU_PROGRAM, WW_GPU_TEXTURE or WW_GPU_VBO.
* @param size The size of the resource being added.
* @param key The cache key for the resource.
*
* @exception NSInvalidArgumentException If either the resource, resource type or cache key is nil,
* or the size is less than 1.
*/
- (void) putResource:(id)resource
        resourceType:(NSString*)resourceType
                size:(long)size
              forKey:(id <NSCopying>)key;

/**
* Adds a WW_GPU_PROGRAM resource to the cache.
*
* @param program The program to add.
* @param key The program's cache key.
*
* @exception NSInvalidArgumentException If either argument is nil.
*/
- (void) putProgram:(WWGpuProgram*)program forKey:(id <NSCopying>)key;

/**
* Adds a WW_GPU_TEXTURE resource to the cache.
*
* @param texture The texture to add.
* @param key The texture's cache key.
*
* @exception NSInvalidArgumentException If either argument is nil.
*/
- (void) putTexture:(WWTexture*)texture forKey:(id <NSCopying>)key;

/**
* Returns the resource associated with a specified cache key.
*
* @param key The cache key for the resource.
*
* @return The resource associated with the specified cache key, or nil if no resource is associated with that key.
*
* @exception NSInvalidArgumentException If the specified key is nil.
*/
- (NSObject*) resourceForKey:(id <NSCopying>)key;

/**
* Returns the program associated with a specified cache key.
*
* @param key The cache key for the program.
*
* @return The program associated with the specified cache key, or nil if no program is associated with that key.
*
* @exception NSInvalidArgumentException If the specified key is nil.
*/
- (WWGpuProgram*) programForKey:(id <NSCopying>)key;

/**
* Returns the texture associated with a specified cache key.
*
* @param key The cache key for the texture.
*
* @return The texture associated with the specified cache key, or nil if no texture is associated with that key.
*
* @exception NSInvalidArgumentException If the specified key is nil.
*/
- (WWTexture*) textureForKey:(id <NSCopying>)key;

/**
* Indicates whether the cache contains a resource for a specified key.
*
* @param key The resource's cache key.
*
* @return YES if the cache contains the specified resource, otherwise NO.
*
* @exception NSInvalidArgumentException if the specified key is nil.
*/
- (BOOL) containsKey:(id <NSCopying>)key;

/**
* Removes the resource associated with a specified cache key.
*
* @param key The resource's cache key.
*
* @exception NSInvalidArgumentException if the specified key is nil.
*/
- (void) removeResourceForKey:(id <NSCopying>)key;

/**
* Removes all resources from the cache.
*/
- (void) clear;

@end