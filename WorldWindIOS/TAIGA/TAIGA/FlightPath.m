/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "FlightPath.h"
#import "Waypoint.h"
#import "WorldWind/Render/WWDrawContext.h"
#import "WorldWind/WWLog.h"

#define STATE_KEY(key, propertyName) ([NSString stringWithFormat:@"gov.nasa.worldwind.taiga.flightpath.%@.%@", (key), (propertyName)])
#define PROPERTY_DISPLAY_NAME @"displayName"
#define PROPERTY_ENABLED @"enabled"
#define PROPERTY_WAYPOINT_KEYS @"waypointKeys"

@implementation FlightPath

- (FlightPath*) init
{
    self = [super init];

    _stateKey = [[NSProcessInfo processInfo] globallyUniqueString];
    _displayName = @"Flight Path";
    _enabled = YES;
    waypoints = [[NSMutableArray alloc] init];

    [[NSUserDefaults standardUserDefaults] setObject:_displayName forKey:STATE_KEY(_stateKey, PROPERTY_DISPLAY_NAME)];
    [[NSUserDefaults standardUserDefaults] setBool:_enabled forKey:STATE_KEY(_stateKey, PROPERTY_ENABLED)];
    [[NSUserDefaults standardUserDefaults] synchronize];

    return self;
}

- (FlightPath*) initWithStateKey:(NSString*)stateKey waypointDatabase:(NSArray*)waypointDatabase
{
    if (stateKey == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"State key is nil")
    }

    if (waypointDatabase == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Waypoint database is nil")
    }

    self = [super init];

    _stateKey = stateKey;
    _displayName = [[NSUserDefaults standardUserDefaults] stringForKey:STATE_KEY(_stateKey, PROPERTY_DISPLAY_NAME)];
    _enabled = [[NSUserDefaults standardUserDefaults] boolForKey:STATE_KEY(_stateKey, PROPERTY_ENABLED)];
    waypoints = [[NSMutableArray alloc] init];

    [self restoreWaypoints:waypointDatabase];

    return self;
}

- (void) removeState
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:STATE_KEY(_stateKey, PROPERTY_DISPLAY_NAME)];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:STATE_KEY(_stateKey, PROPERTY_ENABLED)];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:STATE_KEY(_stateKey, PROPERTY_WAYPOINT_KEYS)];
}

- (void) setDisplayName:(NSString*)displayName
{
    _displayName = displayName;
    [[NSUserDefaults standardUserDefaults] setObject:_displayName forKey:STATE_KEY(_stateKey, PROPERTY_DISPLAY_NAME)];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void) setEnabled:(BOOL)enabled
{
    _enabled = enabled;
    [[NSUserDefaults standardUserDefaults] setBool:_enabled forKey:STATE_KEY(_stateKey, PROPERTY_ENABLED)];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void) render:(WWDrawContext*)dc
{
    if (!_enabled)
    {
        return;
    }

    // TODO: Render flight path waypoints.
}

- (NSUInteger) waypointCount
{
    return [waypoints count];
}

- (Waypoint*) waypointAtIndex:(NSUInteger)index
{
    if (index >= [waypoints count])
    {
        NSString* msg = [[NSString alloc] initWithFormat:@"Index %d is out of range", index];
        WWLOG_AND_THROW(NSInvalidArgumentException, msg)
    }

    return [waypoints objectAtIndex:index];
}

- (void) addWaypoint:(Waypoint*)waypoint
{
    if (waypoint == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Waypoint is nil")
    }

    [waypoints addObject:waypoint];
    [self saveWaypoints];
}

- (void) insertWaypoint:(Waypoint*)waypoint atIndex:(NSUInteger)index
{
    if (waypoint == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Waypoint is nil")
    }

    if (index > [waypoints count])
    {
        NSString* msg = [[NSString alloc] initWithFormat:@"Index %d is out of range", index];
        WWLOG_AND_THROW(NSInvalidArgumentException, msg)
    }

    [waypoints insertObject:waypoint atIndex:index];
    [self saveWaypoints];
}

- (void) removeWaypoint:(Waypoint*)waypoint
{
    if (waypoint == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Waypoint is nil")
    }

    [waypoints removeObject:waypoint];
    [self saveWaypoints];
}

- (void) removeWaypointAtIndex:(NSUInteger)index
{
    if (index >= [waypoints count])
    {
        NSString* msg = [[NSString alloc] initWithFormat:@"Index %d is out of range", index];
        WWLOG_AND_THROW(NSInvalidArgumentException, msg)
    }

    [waypoints removeObjectAtIndex:index];
    [self saveWaypoints];
}

- (void) moveWaypointAtIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex
{
    if (fromIndex >= [waypoints count])
    {
        NSString* msg = [[NSString alloc] initWithFormat:@"From index %d is out of range", fromIndex];
        WWLOG_AND_THROW(NSInvalidArgumentException, msg)
    }

    if (toIndex >= [waypoints count])
    {
        NSString* msg = [[NSString alloc] initWithFormat:@"To index %d is out of range", toIndex];
        WWLOG_AND_THROW(NSInvalidArgumentException, msg)
    }

    Waypoint* waypoint = [waypoints objectAtIndex:fromIndex];
    [waypoints removeObjectAtIndex:fromIndex];
    [waypoints insertObject:waypoint atIndex:toIndex];
    [self saveWaypoints];
}

- (void) saveWaypoints
{
    NSMutableArray* waypointKeys = [NSMutableArray arrayWithCapacity:[waypoints count]];

    for (Waypoint* waypoint in waypoints)
    {
        [waypointKeys addObject:[waypoint key]];
    }

    [[NSUserDefaults standardUserDefaults] setObject:waypointKeys forKey:STATE_KEY(_stateKey, PROPERTY_WAYPOINT_KEYS)];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void) restoreWaypoints:(NSArray*)waypointDatabase
{
    NSArray* waypointKeys = [[NSUserDefaults standardUserDefaults] arrayForKey:STATE_KEY(_stateKey, PROPERTY_WAYPOINT_KEYS)];

    for (NSString* key in waypointKeys)
    {
        NSUInteger keyIndex = [waypointDatabase indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL* stop)
        {
            return [key isEqual:[obj key]];
        }];

        if (keyIndex != NSNotFound)
        {
            Waypoint* waypoint = [waypointDatabase objectAtIndex:keyIndex];
            [waypoints addObject:waypoint];
        }
        else
        {
            WWLog(@"Unrecognized waypoint key %@", key);
        }
    }
}

@end