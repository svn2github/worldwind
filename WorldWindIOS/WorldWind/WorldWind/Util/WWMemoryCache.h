/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

@protocol WWCacheable;
@protocol WWMemoryCacheListener;

/**
* Provides a class for memory cache entries. Used internally only by WWMemoryCache.
*/
@interface WWMemoryCacheEntry : NSObject
{
@public
    // The entry's cache key.
    id <NSCopying> key;
    // The entry's value.
    id value;
    // The entry's size in bytes.
    long size;
    // The cache counter value when this entry was last used.
    uint64_t lastUsed;
}

/**
* Initializes the memory cache entry.
*
* @param entryKey The entry's cache key.
* @param entryValue The entry's value.
* @param entrySize The size of the entry's value.
*
* @return The initialized entry.
*/
- (WWMemoryCacheEntry*) initWithKey:(id <NSCopying>)entryKey value:(id)entryValue size:(long)entrySize;

- (NSComparisonResult) compareTo:(WWMemoryCacheEntry*)other;

@end

/**
* Provides a general purpose memory cache.
*/
@interface WWMemoryCache : NSObject <NSCacheDelegate>
{
@protected
    // Dictionary of cache entries. Each entry's lastUsed ivar is used to indicate the least recently used entry.
    NSMutableDictionary* entries;
    // List of cache listeners notified when a cache entry is removed.
    NSMutableArray* listeners;
    // POSIX mutex lock for synchronizing critical sections of cache methods. Faster than NSLock and @synchronized.
    pthread_mutex_t mutex;
    // Cache counter used to indicate the least recently used entry. Incremented each time an entry is accessed and
    // assigned to the associated entry's lastUsed ivar. Overflows after 500,000 years when the cache is accessed
    // 1,000,000 times per second.
    uint64_t entryUsedCounter;
}

/// @name Memory Cache Attributes

/// The maximum number of bytes the cache is to hold.
@property long capacity;

/// The number of bytes currently used by the cache.
@property(readonly) long usedCapacity;

/// The number of bytes to clear the cache to when its capacity is exceeded.
@property(nonatomic) long lowWater;

/// The number of unused bytes in the cache.
- (long) freeCapacity;

/// @name Initializing Memory Caches

/**
* Initializes this memory cache to a specified capacity and low water value.
*
* @param capacity The cache's capacity, in bytes.
* @param lowWater The number of bytes to clear the cache to when its capacity is exceeded.
*
* @return The initialized cache.
*/
- (WWMemoryCache*) initWithCapacity:(long)capacity lowWater:(long)lowWater;

/// @name Operations on Memory Caches

/**
* Returns the value associated with a specified key.
*
* @param key The value's cache key.
*
* @return The value associated with the key, or nil if the key is not in the cache.
*
* @exception NSInvalidArgumentException If the specified key is nil.
*/
- (id) getValueForKey:(id <NSCopying>)key;

/**
* Adds a specified value to the cache, replacing any existing value for the specified key.
*
* @param value The value to add.
* @param key The key to associate with the value.
* @param size The value's size in bytes.
*
* @exception NSInvalidArgumentException If the specified value or key are nil or the size is less than 1 or greater
* than the cache's capacity.
*/
- (void) putValue:(id)value forKey:(id <NSCopying>)key size:(long)size;

/**
* Adds a specified WWCacheable value to the cache, replacing any existing value for the specified key.
*
* @param value The value to add.
* @param key The key to associate with the value.
*
* @exception NSInvalidArgumentException If the specified value or key are nil or the cachable's size is less than 1
* or greater than the cache's capacity.
*/
- (void) putValue:(id <WWCacheable>)value forKey:(id <NSCopying>)key;

/**
* Indicates whether the cache contains a specified key.
*
* @param key The cache key to test.
*
* @return YES if a cache entry exists for the key, otherwise NO.
*
* @exception NSInvalidArgumentException If the specified key is nil.
*/
- (BOOL) containsKey:(id <NSCopying>)key;

/**
* Removes a specified entry from the cache.
*
* @param key The cache key of the entry to remove.
*
* @exception NSInvalidArgumentException If the specified key is nil.
*/
- (void) removeEntryForKey:(id <NSCopying>)key;

/**
* Removes all entries from the cache.
*/
- (void) clear;

/**
* Adds a specified cache listener that is called when an entry is removed from the cache.
*
* @param listener The memory cache listener to add.
*
* @exception NSInvalidArgumentException If the specified listener is nil.
*/
- (void) addCacheListener:(id <WWMemoryCacheListener>)listener;

/**
* Removes a specified cache listener.
*
* @param listener The cache listener to remove.
*
* @exception NSInvalidArgumentException If the specified listener is nil.
*/
- (void) removeCacheListener:(id <WWMemoryCacheListener>)listener;

@end