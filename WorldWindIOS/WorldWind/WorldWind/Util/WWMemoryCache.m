/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <pthread.h>
#import "WorldWind/Util/WWMemoryCache.h"
#import "WorldWind/Util/WWMemoryCacheListener.h"
#import "WorldWind/Util/WWCacheable.h"
#import "WorldWind/WWLog.h"

@implementation WWMemoryCacheEntry

- (WWMemoryCacheEntry*) initWithKey:(id <NSCopying>)entryKey value:(id)entryValue size:(long)entrySize
{
    self = [super init];

    key = entryKey;
    value = entryValue;
    size = entrySize;

    return self;
}

- (NSComparisonResult) compareTo:(id)other
{
    uint64_t otherLastUsed = ((WWMemoryCacheEntry*) other)->lastUsed;

    return lastUsed < otherLastUsed ? NSOrderedAscending : (lastUsed > otherLastUsed ? NSOrderedDescending : NSOrderedSame);
}
@end

@implementation WWMemoryCache

- (WWMemoryCache*) initWithCapacity:(long)capacity lowWater:(long)lowWater
{
    self = [super init];

    self->entries = [[NSMutableDictionary alloc] init];
    self->listeners = [[NSMutableArray alloc] init];
    pthread_mutex_init(&mutex, NULL);

    _capacity = capacity;
    _lowWater = lowWater;

    return self;
}

- (void) dealloc
{
    pthread_mutex_destroy(&mutex);
}

- (id) getValueForKey:(id <NSCopying> __unsafe_unretained)key
{
    if (key == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Key is nil")
    }

    WWMemoryCacheEntry* __unsafe_unretained entry;

    pthread_mutex_lock(&mutex);
    @try
    {
        entry = [self->entries objectForKey:key];

        if (entry != nil)
        {
            entry->lastUsed = entryUsedCounter++;
        }
    }
    @finally
    {
        pthread_mutex_unlock(&mutex);
    }

    return entry != nil ? entry->value : nil;
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

    pthread_mutex_lock(&mutex);
    @try
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
        entry->lastUsed = entryUsedCounter++;
    }
    @finally
    {
        pthread_mutex_unlock(&mutex);
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

- (BOOL) containsKey:(id <NSCopying> __unsafe_unretained)key
{
    if (key == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Key is nil")
    }

    BOOL yn;

    pthread_mutex_lock(&mutex);
    @try
    {
        yn = [self->entries objectForKey:key] != nil;
    }
    @finally
    {
        pthread_mutex_unlock(&mutex);
    }

    return yn;
}

- (void) removeEntryForKey:(id <NSCopying>)key
{
    if (key == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Key is nil")
    }

    pthread_mutex_lock(&mutex);
    @try
    {
        WWMemoryCacheEntry* entry = [self->entries objectForKey:key];
        if (entry != nil)
        {
            [self removeEntry:entry];
        }
    }
    @finally
    {
        pthread_mutex_unlock(&mutex);
    }
}

- (void) clear
{
    pthread_mutex_lock(&mutex);
    @try
    {
        NSArray* values = [self->entries allValues];

        for (NSUInteger i = 0; i < [values count]; i++)
        {
            [self removeEntry:[values objectAtIndex:i]];
        }
    }
    @finally
    {
        pthread_mutex_unlock(&mutex);
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

    if ([self->entries objectForKey:entry->key] == nil)
    {
        return;
    }

    [self->entries removeObjectForKey:entry->key];

    _usedCapacity -= entry->size;

    for (NSUInteger i = 0; i < [self->listeners count]; i++)
    {
        @try
        {
            [[self->listeners objectAtIndex:i] entryRemovedForKey:entry->key value:entry->value];
        }
        @catch (NSException* exception)
        {
            [[self->listeners objectAtIndex:i] removalException:exception key:entry->key value:entry->value];
        }
    }

}

- (void) makeSpace:(long)spaceRequired // PRIVATE METHOD
{
    if (spaceRequired > _capacity || spaceRequired < 0)
        return;

    // Sort the entries from least recently used to most recently used, then remove the least recently used entries
    // until the cache capacity either reaches the low water or the cache has enough free capacity for the required
    // space, whichever comes last.
    NSArray* useOrderedEntries = [[self->entries allValues] sortedArrayUsingSelector:@selector(compareTo:)];

    NSUInteger i = 0;
    while ([self freeCapacity] < spaceRequired || _usedCapacity > _lowWater)
    {
        if (i < [useOrderedEntries count])
        {
            [self removeEntry:[useOrderedEntries objectAtIndex:i++]];
        }
    }
}

@end