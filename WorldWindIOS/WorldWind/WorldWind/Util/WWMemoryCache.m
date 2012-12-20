/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Util/WWMemoryCache.h"
#import "WorldWind/Util/WWCacheable.h"
#import "WorldWind/WWLog.h"
#import "WWMemoryCacheListener.h"

@implementation WWMemoryCacheEntry

- (WWMemoryCacheEntry*) initWithKey:(id <NSCopying>)key value:(id)value size:(long)size
{
    self = [super init];

    _key = key;
    _value = value;
    _size = size;
    _lastUsed = [NSDate date];

    return self;
}

- (int) compareTo:(id)other
{
    NSComparisonResult result = [_lastUsed compare:[other lastUsed]];

    if (result == NSOrderedAscending)
        return -1;

    if (result == NSOrderedSame)
        return 0;

    return 1;
}
@end

@implementation WWMemoryCache

- (WWMemoryCache*) initWithCapacity:(long)capacity lowWater:(long)lowWater
{
    self = [super init];

    self->entries = [[NSMutableDictionary alloc] init];
    self->listeners = [[NSMutableArray alloc] init];
    self->lock = [[NSObject alloc] init];

    _capacity = capacity;
    _lowWater = lowWater;

    return self;
}

- (id) getValueForKey:(id <NSCopying>)key
{
    if (key == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Key is nil")
    }

    WWMemoryCacheEntry* entry;
    @synchronized (self->lock)
    {
        entry = [self->entries objectForKey:key];

        if (entry != nil)
        {
            [entry setLastUsed:[NSDate date]];
        }
    }

    return entry != nil ? [entry value] : nil;
}

- (void) putValue:(id)value forKey:(id <NSCopying>)key size:(long)size
{
    if (key == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Key is nil")
    }

    if (value == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Value is nil")
    }

    if (size < 1)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Size is less than 1")
    }

    if (size > _capacity)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Size is greater than capacity")
    }

    WWMemoryCacheEntry* entry = [[WWMemoryCacheEntry alloc] initWithKey:key value:value size:size];

    @synchronized (self->lock)
    {
        WWMemoryCacheEntry* existing = [self->entries objectForKey:key];
        if (existing != nil)
        {
            [self removeEntry:existing];
        }

        if (_usedCapacity + size > _capacity)
        {
            [self makeSpace:size];
        }

        _usedCapacity += size;

        [self->entries setObject:entry forKey:key];
    }
}

- (void) putValue:(id <WWCacheable>)value forKey:(id <NSCopying>)key
{
    if (key == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Key is nil")
    }

    if (value == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Value is nil")
    }

    [self putValue:value forKey:key size:[value sizeInBytes]];
}

- (BOOL) containsKey:(id <NSCopying>)key
{
    if (key == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Key is nil")
    }

    @synchronized (self->lock)
    {
        return [self->entries objectForKey:key] != nil;
    }
}

- (void) removeEntryForKey:(id <NSCopying>)key
{
    if (key == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Key is nil")
    }

    @synchronized (self->lock)
    {
        WWMemoryCacheEntry* entry = [self->entries objectForKey:key];
        if (entry != nil)
        {
            [self removeEntry:entry];
        }
    }
}

- (void) clear
{
    @synchronized (self->lock)
    {
        NSArray* values = [self->entries allValues];

        for (NSUInteger i = 0; i < [values count]; i++)
        {
            [self removeEntry:[values objectAtIndex:i]];
        }
    }
}

- (long) freeCapacity
{
    return MAX([self capacity] - [self usedCapacity], 0);
}

- (void) setLowWater:(long)lowWater
{
    if (lowWater < _capacity && lowWater >= 0)
    {
        _lowWater = lowWater;
    }
}

- (void) addCacheListener:(id <WWMemoryCacheListener>)listener
{
    if (listener == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Listener is nil")
    }

    [self->listeners addObject:listener];
}

- (void) removeCacheListener:(id <WWMemoryCacheListener>)listener
{
    if (listener == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Listener is nil")
    }

    [self->listeners removeObject:listener];
}

- (void) removeEntry:(WWMemoryCacheEntry*)entry // MUST BE CALLED WITHIN SYNCHRONIZED
{
    // All removal passes through this method.

    if ([self->entries objectForKey:[entry key]] == nil)
    {
        return;
    }

    [self->entries removeObjectForKey:[entry key]];

    _usedCapacity -= [entry size];

    for (NSUInteger i = 0; i < [self->listeners count]; i++)
    {
        @try
        {
            [[self->listeners objectAtIndex:i] entryRemovedForKey:[entry key] value:[entry value]];
        }
        @catch (NSException* exception)
        {
            [[self->listeners objectAtIndex:i] removalException:exception key:[entry key] value:[entry value]];
        }
    }

}

- (void) makeSpace:(long)spaceRequired // PRIVATE METHOD
{
    if (spaceRequired > _capacity || spaceRequired < 0)
        return;

    NSArray* timeOrderedEntries = [[self->entries allValues] sortedArrayUsingSelector:@selector(compareTo:)];

    NSUInteger i = 0;
    while ([self freeCapacity] < spaceRequired || _usedCapacity > _lowWater)
    {
        if (i < [timeOrderedEntries count])
        {
            [self removeEntry:[timeOrderedEntries objectAtIndex:i++]];
        }
    }
}

@end