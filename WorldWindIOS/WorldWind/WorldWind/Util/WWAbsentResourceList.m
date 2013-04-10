/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <UIKit/UIKit.h>
#import "WorldWind/Util/WWAbsentResourceList.h"
#import "WorldWind/WWLog.h"

@implementation WWAbsentResourceEntry
- (WWAbsentResourceEntry*) init
{
    self = [super init];

    _timeOfLastMark = [NSDate timeIntervalSinceReferenceDate];

    return self;
}

- (WWAbsentResourceEntry*) initWithTimeOfLastMark:(NSTimeInterval)timeOfLastMark numTries:(int)numTries
{
    self = [super init];

    _timeOfLastMark = timeOfLastMark;
    _numTries = numTries;

    return self;
}

- (id) copyWithZone:(NSZone*)zone
{
    return [[[self class] alloc] initWithTimeOfLastMark:_timeOfLastMark numTries:_numTries];
}
@end

@implementation WWAbsentResourceList

- (WWAbsentResourceList*) initWithMaxTries:(int)maxTries minCheckInterval:(NSTimeInterval)minCheckInterval
{
    self = [super init];

    _maxTries = maxTries;
    _minCheckInterval = minCheckInterval;
    _tryAgainInterval = 60; // seconds

    synchronizationLock = [[NSLock alloc] init];
    possiblyAbsent = [[NSMutableDictionary alloc] init];

    return self;
}

- (BOOL) isResourceAbsent:(NSString*)resourceID
{
    if (resourceID == nil || [resourceID length] == 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Resource ID is nil or empty")
    }

    @synchronized (synchronizationLock)
    {
        WWAbsentResourceEntry* entry = (WWAbsentResourceEntry*) [possiblyAbsent objectForKey:resourceID];
        if (entry == nil)
        {
            return NO;
        }

        NSTimeInterval timeSinceLastMark = [NSDate timeIntervalSinceReferenceDate] - [entry timeOfLastMark];

        if (timeSinceLastMark > _tryAgainInterval)
        {
            [possiblyAbsent removeObjectForKey:resourceID];
            return NO;
        }

        return timeSinceLastMark < _minCheckInterval || [entry numTries] > _maxTries;
    }
}

- (void) markResourceAbsent:(NSString*)resourceID
{
    if (resourceID == nil || [resourceID length] == 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Resource ID is nil or empty")
    }

    @synchronized (synchronizationLock)
    {
        WWAbsentResourceEntry* entry = (WWAbsentResourceEntry*) [possiblyAbsent objectForKey:resourceID];
        if (entry == nil)
        {
            entry = [[WWAbsentResourceEntry alloc] init];
            [possiblyAbsent setObject:resourceID forKey:entry];
        }

        [entry setNumTries:[entry numTries] + 1];
        [entry setTimeOfLastMark:[NSDate timeIntervalSinceReferenceDate]];
    }
}

- (void) unmarkResourceAbsent:(NSString*)resourceID
{
    if (resourceID == nil || [resourceID length] == 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Resource ID is nil or empty")
    }

    @synchronized (synchronizationLock)
    {
        [possiblyAbsent removeObjectForKey:resourceID];
    }
}

@end