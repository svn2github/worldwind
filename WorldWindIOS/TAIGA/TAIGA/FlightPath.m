/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "FlightPath.h"
#import "Waypoint.h"
#import "AppConstants.h"
#import "WorldWind/Geometry/WWPosition.h"
#import "WorldWind/Render/WWDrawContext.h"
#import "Worldwind/Shapes/WWPath.h"
#import "WorldWind/Shapes/WWShapeAttributes.h"
#import "WorldWind/Util/WWColor.h"
#import "WorldWind/WorldWindConstants.h"
#import "WorldWind/WWLog.h"

@implementation FlightPath

- (FlightPath*) init
{
    self = [super init];

    _displayName = @"Flight Path";
    _enabled = YES;
    _altitude = 0;
    _colorIndex = 0;

    waypoints = [[NSMutableArray alloc] initWithCapacity:8];
    waypointPositions = [[NSMutableArray alloc] initWithCapacity:8];
    [self initPathWithPositions:waypointPositions];

    return self;
}

- (FlightPath*) initWithWaypoints:(NSArray*)waypointArray
{
    self = [super init];

    _displayName = @"Flight Path";
    _enabled = YES;
    _altitude = 0;
    _colorIndex = 0;

    waypoints = [[NSMutableArray alloc] initWithArray:waypointArray];
    waypointPositions = [[NSMutableArray alloc] initWithCapacity:[waypointArray count]];
    for (Waypoint* waypoint in waypoints)
    {
        WWPosition* pos = [self positionForWaypoint:waypoint];
        [waypointPositions addObject:pos];
    }
    [self initPathWithPositions:waypointPositions];

    return self;
}

- (void) initPathWithPositions:(NSArray*)positions
{
    path = [[WWPath alloc] initWithPositions:positions];
    [path setPathType:WW_RHUMB];

    WWShapeAttributes* attrs = [[WWShapeAttributes alloc] init];
    NSDictionary* colorAttrs = [[FlightPath flightPathColors] firstObject];
    [attrs setOutlineColor:[colorAttrs objectForKey:@"color"]];
    [attrs setOutlineWidth:5.0];
    [path setAttributes:attrs];
}

- (WWPosition*) positionForWaypoint:(Waypoint*)waypoint
{
    return [[WWPosition alloc] initWithLocation:[waypoint location] altitude:_altitude];
}

- (void) setDisplayName:(NSString*)displayName
{
    _displayName = displayName;
    [[NSNotificationCenter defaultCenter] postNotificationName:TAIGA_FLIGHT_ROUTE_CHANGED object:self];
}

- (void) setEnabled:(BOOL)enabled
{
    _enabled = enabled;
    [[NSNotificationCenter defaultCenter] postNotificationName:TAIGA_FLIGHT_ROUTE_CHANGED object:self];
}

- (void) setAltitude:(double)altitude
{
    _altitude = altitude;
    [self didChangeAltitude];
}

- (void) setColorIndex:(NSUInteger)colorIndex
{
    _colorIndex = colorIndex;
    [self didChangeColor];
}

+ (NSArray*) flightPathColors
{
    static NSArray* colors = nil;
    if (colors == nil)
    {
        colors = @[
            @{@"color":[[WWColor alloc] initWithR:1.000 g:0.035 b:0.329 a:1.0], @"displayName":@"Red"},
            @{@"color":[[WWColor alloc] initWithR:1.000 g:0.522 b:0.000 a:1.0], @"displayName":@"Orange"},
            @{@"color":[[WWColor alloc] initWithR:1.000 g:0.776 b:0.000 a:1.0], @"displayName":@"Yellow"},
            @{@"color":[[WWColor alloc] initWithR:0.310 g:0.851 b:0.129 a:1.0], @"displayName":@"Green"},
            @{@"color":[[WWColor alloc] initWithR:0.027 g:0.596 b:0.976 a:1.0], @"displayName":@"Blue"},
            @{@"color":[[WWColor alloc] initWithR:0.757 g:0.325 b:0.863 a:1.0], @"displayName":@"Purple"}
        ];
    }

    return colors;
}

- (void) render:(WWDrawContext*)dc
{
    if (!_enabled)
    {
        return;
    }

    [path render:dc];
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

    NSUInteger index = [waypoints count];
    [waypoints insertObject:waypoint atIndex:index];
    [self didInsertWaypoint:waypoint atIndex:index];
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
    [self didInsertWaypoint:waypoint atIndex:index];
}

- (void) removeWaypoint:(Waypoint*)waypoint
{
    if (waypoint == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Waypoint is nil")
    }

    NSUInteger index = [waypoints indexOfObject:waypoint];
    if (index != NSNotFound)
    {
        [waypoints removeObjectAtIndex:index];
        [self didRemoveWaypoint:waypoint atIndex:index];
    }
}

- (void) removeWaypointAtIndex:(NSUInteger)index
{
    if (index >= [waypoints count])
    {
        NSString* msg = [[NSString alloc] initWithFormat:@"Index %d is out of range", index];
        WWLOG_AND_THROW(NSInvalidArgumentException, msg)
    }

    Waypoint* waypoint = [waypoints objectAtIndex:index];
    [waypoints removeObjectAtIndex:index];
    [self didRemoveWaypoint:waypoint atIndex:index];
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
    [self didMoveWaypoint:waypoint fromIndex:fromIndex toIndex:toIndex];
}

- (void) didChangeAltitude
{
    for (WWPosition* pos in waypointPositions)
    {
        [pos setAltitude:_altitude];
    }
    [path setPositions:waypointPositions];

    [[NSNotificationCenter defaultCenter] postNotificationName:TAIGA_FLIGHT_ROUTE_CHANGED object:self];
}

- (void) didChangeColor
{
    NSDictionary* colorAttrs = [[FlightPath flightPathColors] objectAtIndex:_colorIndex];
    [[path attributes] setOutlineColor:[colorAttrs objectForKey:@"color"]];

    [[NSNotificationCenter defaultCenter] postNotificationName:TAIGA_FLIGHT_ROUTE_CHANGED object:self];
}

- (void) didInsertWaypoint:(Waypoint*)waypoint atIndex:(NSUInteger)index
{
    WWPosition* pos = [self positionForWaypoint:waypoint];
    [waypointPositions insertObject:pos atIndex:index];
    [path setPositions:waypointPositions];

    [[NSNotificationCenter defaultCenter] postNotificationName:TAIGA_FLIGHT_ROUTE_CHANGED object:self];
}

- (void) didRemoveWaypoint:(Waypoint*)waypoint atIndex:(NSUInteger)index
{
    [waypointPositions removeObjectAtIndex:index];
    [path setPositions:waypointPositions];

    [[NSNotificationCenter defaultCenter] postNotificationName:TAIGA_FLIGHT_ROUTE_CHANGED object:self];
}

- (void) didMoveWaypoint:(Waypoint*)waypoint fromIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex
{
    WWPosition* pos = [waypointPositions objectAtIndex:fromIndex];
    [waypointPositions removeObjectAtIndex:fromIndex];
    [waypointPositions insertObject:pos atIndex:toIndex];
    [path setPositions:waypointPositions];

    [[NSNotificationCenter defaultCenter] postNotificationName:TAIGA_FLIGHT_ROUTE_CHANGED object:self];
}

@end