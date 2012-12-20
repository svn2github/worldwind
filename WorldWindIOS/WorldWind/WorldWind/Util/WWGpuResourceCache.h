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

@interface WWGpuResourceCacheEntry : NSObject <WWCacheable>

@property(readonly) NSString* resourceType;
@property(readonly) id resource;
@property long resourceSize;

- (WWGpuResourceCacheEntry*) initWithResource:(id)resource resourceType:(NSString*)resourceType;

- (WWGpuResourceCacheEntry*) initWithResource:(id)resource resourceType:(NSString*)resourceType size:(long)size;

@end


@interface WWGpuResourceCache : NSObject <WWMemoryCacheListener>
{
@protected
    WWMemoryCache* resources;
}

- (WWGpuResourceCache*) initWithLowWater:(long)lowWater highWater:(long)highWater;

- (NSObject*) getResourceForKey:(id <NSCopying>)key;

- (WWGpuProgram*) getProgramForKey:(id <NSCopying>)key;

- (WWTexture*) getTextureForKey:(id <NSCopying>)key;

- (void) putResource:(id)resource
        resourceType:(NSString*)resourceType
                size:(long)size
              forKey:(id <NSCopying>)key;

- (void) putProgram:(WWGpuProgram*)program forKey:(id <NSCopying>)key;

- (void) putTexture:(WWTexture*)texture forKey:(id <NSCopying>)key;

- (long) computeEntrySize:(WWGpuResourceCacheEntry*)entry;

- (BOOL) containsKey:(id <NSCopying>)key;

- (void) removeResourceForKey:(id <NSCopying>)key;

- (void) clear;

- (void) setCapacity:(long)newCapacity;

- (long) capacity;

- (long) usedCapacity;

- (long) freeCapacity;

- (void) setLowWater:(long)lowWater;

- (long) lowWater;

@end