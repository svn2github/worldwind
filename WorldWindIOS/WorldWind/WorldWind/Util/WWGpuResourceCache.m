/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Util/WWGpuResourceCache.h"
#import "WorldWind/Util/WWMemoryCache.h"
#import "WorldWind/WWLog.h"
#import "WorldWind/Render/WWGpuProgram.h"
#import "WorldWind/Render/WWTexture.h"
#import "WorldWind/WorldWindConstants.h"

@implementation WWGpuResourceCacheEntry

- (WWGpuResourceCacheEntry*) initWithResource:(id)object resourceType:(NSString*)type;
{
    self = [super init];

    resource = object;
    resourceType = type;

    return self;
}

- (WWGpuResourceCacheEntry*) initWithResource:(id)object resourceType:(NSString*)type size:(long)size;
{
    self = [super init];

    resource = object;
    resourceType = type;
    resourceSize = size;

    return self;
}

- (long) sizeInBytes // WWCacheable protocol
{
    return resourceSize;
}
@end

@implementation WWGpuResourceCache

- (WWGpuResourceCache*) initWithLowWater:(long)lowWater capacity:(long)capacity
{
    self = [super init];

    self->resources = [[WWMemoryCache alloc] initWithCapacity:capacity lowWater:lowWater];
    [self->resources addCacheListener:self]; // install entry-removed and removal-exception handler

    return self;
}

- (void) entryRemovedForKey:(id <NSCopying>)key value:(id)value // memory cache listener
{
    WWGpuResourceCacheEntry* entry = (WWGpuResourceCacheEntry*) value;

    if ([entry->resource respondsToSelector:@selector(dispose)])
    {
        [self performSelectorOnMainThread:@selector(disposeTexture:) withObject:entry waitUntilDone:NO];
    }
    else if ([entry->resourceType isEqualToString:WW_GPU_VBO])
    {
        [self performSelectorOnMainThread:@selector(disposeVBO:) withObject:entry waitUntilDone:NO];
    }
}

- (void) disposeTexture:(id)entry
{
    [((WWGpuResourceCacheEntry*) entry)->resource dispose];
}

- (void) disposeVBO:(id)entry
{
    GLuint bufferId = (GLuint) [((NSNumber*) ((WWGpuResourceCacheEntry*) entry)->resource) intValue];
    glDeleteBuffers(1, &bufferId);
}

- (void) removalException:(NSException*)exception key:(id <NSCopying>)key value:(id)value // memory cache listener
{
    WWLogE(@"removing GPU resource", exception);
}

- (NSObject*) resourceForKey:(id <NSCopying> __unsafe_unretained)key
{
    if (key == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Key is nil")
    }

    WWGpuResourceCacheEntry* __unsafe_unretained entry = (WWGpuResourceCacheEntry*) [resources getValueForKey:key];

    return entry != nil ? entry->resource : nil;
}

- (WWGpuProgram*) programForKey:(id <NSCopying> __unsafe_unretained)key
{
    if (key == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Key is nil")
    }

    WWGpuResourceCacheEntry* __unsafe_unretained entry = (WWGpuResourceCacheEntry*) [resources getValueForKey:key];

    return entry != nil && [entry->resourceType isEqual:WW_GPU_PROGRAM] ? (WWGpuProgram*) entry->resource : nil;
}

- (WWTexture*) textureForKey:(id <NSCopying>__unsafe_unretained)key
{
    if (key == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Key is nil")
    }

    WWGpuResourceCacheEntry* __unsafe_unretained entry = (WWGpuResourceCacheEntry*) [resources getValueForKey:key];

    return entry != nil && [entry->resourceType isEqual:WW_GPU_TEXTURE] ? (WWTexture*) entry->resource : nil;
}

- (void) putResource:(id)resource resourceType:(NSString*)resourceType size:(long)size forKey:(id <NSCopying>)key
{
    if (key == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Key is nil")
    }

    if (resource == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Resource is nil")
    }

    if (resourceType == nil || [resourceType length] == 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Resource type is nil or zero length")
    }

    if (size < 1)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Size is less than one")
    }

    if (size > [self->resources capacity])
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Size is greater than capacity")
    }

    WWGpuResourceCacheEntry* entry = [[WWGpuResourceCacheEntry alloc] initWithResource:resource
                                                                          resourceType:resourceType
                                                                                  size:size];
    [self->resources putValue:entry forKey:key];
}

- (void) putProgram:(WWGpuProgram*)program forKey:(id <NSCopying>)key
{
    if (key == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Key is nil")
    }

    if (program == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Program is nil")
    }

    WWGpuResourceCacheEntry* entry = [[WWGpuResourceCacheEntry alloc] initWithResource:program
                                                                          resourceType:WW_GPU_PROGRAM];
    entry->resourceSize = [self entrySize:entry];

    [self->resources putValue:entry forKey:key];
}

- (void) putTexture:(WWTexture*)texture forKey:(id <NSCopying>)key
{
    if (key == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Key is nil")
    }

    if (texture == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Texture is nil")
    }

    WWGpuResourceCacheEntry* entry = [[WWGpuResourceCacheEntry alloc] initWithResource:texture
                                                                          resourceType:WW_GPU_TEXTURE];
    entry->resourceSize = [self entrySize:entry];

    [self->resources putValue:entry forKey:key];
}

- (long) entrySize:(WWGpuResourceCacheEntry*)entry
{
    if ([entry->resource respondsToSelector:@selector(sizeInBytes)])
    {
        return [entry->resource sizeInBytes];
    }

    return 0;
}

- (BOOL) containsKey:(id <NSCopying>)key
{
    if (key == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Key is nil")
    }

    return [self->resources containsKey:key];
}

- (void) removeResourceForKey:(id <NSCopying>)key
{
    if (key == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Key is nil")
    }

    [self->resources removeEntryForKey:key];
}

- (void) clear
{
    [self->resources clear];
}

- (void) setCapacity:(long)newCapacity
{
    if (newCapacity <= 0)
    {
        NSString* msg = [NSString stringWithFormat:@"Capacity of %ld is invalid", newCapacity];
        WWLOG_AND_THROW(NSInvalidArgumentException, msg)
    }

    [self->resources setCapacity:newCapacity];
}

- (long) capacity
{
    return [self->resources capacity];
}

- (long) usedCapacity
{
    return [self->resources usedCapacity];
}

- (long) freeCapacity
{
    return [self->resources freeCapacity];
}

- (void) setLowWater:(long)lowWater
{
    if (lowWater <= 0)
    {
        NSString* msg = [NSString stringWithFormat:@"Low water of %ld is invalid", lowWater];
        WWLOG_AND_THROW(NSInvalidArgumentException, msg)
    }

    [self->resources setLowWater:lowWater];
}

- (long) lowWater
{
    return [self->resources lowWater];
}

@end