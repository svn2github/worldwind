/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

@protocol WWCacheable;
@protocol WWMemoryCacheListener;

@interface WWMemoryCacheEntry : NSObject

@property(readonly) id <NSCopying> key;
@property(readonly) id value;
@property(readonly) long size;
@property (strong) NSDate* lastUsed;

- (WWMemoryCacheEntry*) initWithKey:(id <NSCopying>)key value:(id)value size:(long)size;

- (int) compareTo:(WWMemoryCacheEntry*)other;

@end

@interface WWMemoryCache : NSObject <NSCacheDelegate>
{
@protected
    NSMutableDictionary* entries;
    NSMutableArray* listeners;
    NSObject* lock;
}

@property long capacity;
@property(readonly) long usedCapacity;
@property(nonatomic) long lowWater;

- (WWMemoryCache*) initWithCapacity:(long)capacity lowWater:(long)lowWater;

- (long) freeCapacity;

- (id) getValueForKey:(id <NSCopying>)key;

- (void) putValue:(id)value forKey:(id <NSCopying>)key size:(long)size;

- (void) putValue:(id <WWCacheable>)value forKey:(id <NSCopying>)key;

- (BOOL) containsKey:(id <NSCopying>)key;

- (void) removeEntryForKey:(id <NSCopying>)key;

- (void) clear;

- (void) addCacheListener:(id <WWMemoryCacheListener>)listener;

- (void) removeCacheListener:(id <WWMemoryCacheListener>)listener;

@end