/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <CoreLocation/CoreLocation.h>
#import "FlightRoute.h"
#import "Waypoint.h"
#import "AppConstants.h"
#import "WorldWind/Geometry/WWBoundingSphere.h"
#import "WorldWind/Geometry/WWPosition.h"
#import "WorldWind/Geometry/WWVec4.h"
#import "WorldWind/Layer/WWLayer.h"
#import "WorldWind/Render/WWDrawContext.h"
#import "Worldwind/Shapes/WWPath.h"
#import "WorldWind/Shapes/WWShapeAttributes.h"
#import "WorldWind/Shapes/WWSphere.h"
#import "WorldWind/Terrain/WWGlobe.h"
#import "WorldWind/Util/WWColor.h"
#import "WorldWind/WorldWindConstants.h"
#import "WorldWind/WWLog.h"

const float PathWidth = 4.0;
const float ShapeRadius = 6.0;
const float ShapePickRadius = 22.0;

@implementation FlightRoute

+ (NSArray*) flightRouteColors
{
    static NSArray* colors = nil;
    if (colors == nil)
    {
        colors = @[
                @{@"color" : [[WWColor alloc] initWithR:1.000 g:0.035 b:0.329 a:1.0], @"displayName" : @"Red"},
                @{@"color" : [[WWColor alloc] initWithR:1.000 g:0.522 b:0.000 a:1.0], @"displayName" : @"Orange"},
                @{@"color" : [[WWColor alloc] initWithR:1.000 g:0.776 b:0.000 a:1.0], @"displayName" : @"Yellow"},
                @{@"color" : [[WWColor alloc] initWithR:0.310 g:0.851 b:0.129 a:1.0], @"displayName" : @"Green"},
                @{@"color" : [[WWColor alloc] initWithR:0.027 g:0.596 b:0.976 a:1.0], @"displayName" : @"Blue"},
                @{@"color" : [[WWColor alloc] initWithR:0.757 g:0.325 b:0.863 a:1.0], @"displayName" : @"Purple"}
        ];
    }

    return colors;
}

- (FlightRoute*) init
{
    self = [super init];

    _displayName = @"Flight Route";
    _enabled = YES;
    _altitude = 0;
    _colorIndex = 0;

    waypoints = [[NSMutableArray alloc] initWithCapacity:8];
    currentPosition = [[WWPosition alloc] initWithZeroPosition];
    [self initShapes];

    return self;
}

- (FlightRoute*) initWithWaypoints:(NSArray*)waypointArray
{
    self = [super init];

    _displayName = @"Flight Route";
    _enabled = YES;
    _altitude = 0;
    _colorIndex = 0;

    waypoints = [[NSMutableArray alloc] initWithArray:waypointArray];
    currentPosition = [[WWPosition alloc] initWithZeroPosition];
    [self initShapes];

    return self;
}

- (void) initShapes
{
    NSDictionary* colorAttrs = [[FlightRoute flightRouteColors] objectAtIndex:_colorIndex];
    WWColor* color = [colorAttrs objectForKey:@"color"];
    shapeAttrs = [[WWShapeAttributes alloc] init];
    [shapeAttrs setInteriorColor:color];
    [shapeAttrs setOutlineColor:color];
    [shapeAttrs setOutlineWidth:PathWidth];

    waypointPositions = [[NSMutableArray alloc] initWithCapacity:[waypoints count]];
    waypointShapes = [[NSMutableArray alloc] initWithCapacity:[waypoints count]];

    for (Waypoint* waypoint in waypoints)
    {
        WWPosition* pos = [[WWPosition alloc] initWithLocation:[waypoint location] altitude:_altitude];
        [waypointPositions addObject:pos];

        id shape = [self createShapeForWaypoint:waypoint withPosition:pos];
        [waypointShapes addObject:shape];
    }

    waypointPath = [self createPathForRoute:waypointPositions];
}

- (WWPath*) createPathForRoute:(NSArray*)positions
{
    WWPath* path = [[WWPath alloc] initWithPositions:positions];
    [path setPathType:WW_RHUMB];
    [path setAttributes:shapeAttrs];
    [path setPickDelegate:self];

    return path;
}

- (id) createShapeForWaypoint:(Waypoint*)waypoint withPosition:(WWPosition*)position
{
    WWSphere* shape = [[WWSphere alloc] initWithPosition:position radiusInPixels:1.0]; // radius specified in doRender:
    [shape setAttributes:shapeAttrs];
    [shape setPickDelegate:self];

    return shape;
}

- (void) updateShape:(id)shape withPosition:(WWPosition*)position
{
    [(WWSphere*) shape setPosition:position];
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

- (void) render:(WWDrawContext*)dc
{
    if (!_enabled)
    {
        return;
    }

    [waypointPath render:dc];

    for (id shape in waypointShapes)
    {
        double radius = [dc pickingMode] ? ShapePickRadius : ShapeRadius;
        [shape setRadius:radius];
        [shape render:dc];
    }
}

- (id <WWExtent>) extentOnGlobe:(WWGlobe*)globe;
{
    if (globe == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Globe is nil")
    }

    if ([waypoints count] == 0)
        return nil;

    NSMutableArray* waypointPoints = [[NSMutableArray alloc] initWithCapacity:[waypoints count]];
    for (Waypoint* waypoint in waypoints)
    {
        WWLocation* location = [waypoint location];
        WWVec4* point = [[WWVec4 alloc] initWithZeroVector];
        [globe computePointFromPosition:[location latitude] longitude:[location longitude] altitude:_altitude outputPoint:point];
        [waypointPoints addObject:point];
    }

    return [[WWBoundingSphere alloc] initWithPoints:waypointPoints];
}

- (void) locationForPercent:(double)pct
                   latitude:(CLLocationDegrees*)latitude
                  longitude:(CLLocationDegrees*)longitude
                   altitude:(CLLocationDistance*)altitude
                     course:(CLLocationDirection*)course
{
    if (pct < 0 || pct > 1)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Percent is invalid")
    }

    NSUInteger waypointCount = [waypointPositions count];
    if (waypointCount == 1)
    {
        WWPosition* pos = [waypointPositions firstObject];
        *latitude = [pos latitude];
        *longitude = [pos longitude];
        *altitude = [pos altitude];
        *course = 0;
    }
    else // if (waypointCount > 1)
    {
        double legDistance[waypointCount - 1];
        double routeDistance = 0;

        NSUInteger i;
        for (i = 0; i < waypointCount - 1; i++)
        {
            WWPosition* begin = [waypointPositions objectAtIndex:i];
            WWPosition* end = [waypointPositions objectAtIndex:i + 1];
            legDistance[i] = [WWLocation rhumbDistance:begin endLocation:end];
            routeDistance += legDistance[i];
        }

        double pctDistance = pct * routeDistance;
        double remainingDistance = pctDistance;

        for (i = 0; i < waypointCount - 1; i++)
        {
            if (remainingDistance < legDistance[i]) // location is within this non-zero length leg
            {
                double legPct = remainingDistance / legDistance[i];
                WWPosition* begin = [waypointPositions objectAtIndex:i];
                WWPosition* end = [waypointPositions objectAtIndex:i + 1];
                [WWPosition rhumbInterpolate:begin endPosition:end amount:legPct outputPosition:currentPosition];
                *latitude = [currentPosition latitude];
                *longitude = [currentPosition longitude];
                *altitude = [currentPosition altitude];
                *course = [WWPosition rhumbAzimuth:begin endLocation:end];
                return;
            }

            remainingDistance -= legDistance[i];
        }

        // location is at the last waypoint
        WWPosition* begin = [waypointPositions objectAtIndex:i - 1];
        WWPosition* end = [waypointPositions objectAtIndex:i];
        *latitude = [end latitude];
        *longitude = [end longitude];
        *altitude = [end altitude];
        *course = [WWPosition rhumbAzimuth:begin endLocation:end];
    }
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
    for (NSUInteger i = 0; i < [waypointPositions count]; i++)
    {
        WWPosition* pos = [waypointPositions objectAtIndex:i];
        [pos setAltitude:_altitude];

        id shape = [waypointShapes objectAtIndex:i];
        [self updateShape:shape withPosition:pos];
    }

    [waypointPath setPositions:waypointPositions];

    [[NSNotificationCenter defaultCenter] postNotificationName:TAIGA_FLIGHT_ROUTE_CHANGED object:self];
}

- (void) didChangeColor
{
    NSDictionary* colorAttrs = [[FlightRoute flightRouteColors] objectAtIndex:_colorIndex];
    WWColor* color = [colorAttrs objectForKey:@"color"];
    [shapeAttrs setInteriorColor:color];
    [shapeAttrs setOutlineColor:color];

    [[NSNotificationCenter defaultCenter] postNotificationName:TAIGA_FLIGHT_ROUTE_CHANGED object:self];
}

- (void) didInsertWaypoint:(Waypoint*)waypoint atIndex:(NSUInteger)index
{
    WWPosition* pos = [[WWPosition alloc] initWithLocation:[waypoint location] altitude:_altitude];
    [waypointPositions insertObject:pos atIndex:index];
    [waypointPath setPositions:waypointPositions];

    id shape = [self createShapeForWaypoint:waypoint withPosition:pos];
    [waypointShapes insertObject:shape atIndex:index];

    [[NSNotificationCenter defaultCenter] postNotificationName:TAIGA_FLIGHT_ROUTE_CHANGED object:self
                                                      userInfo:@{TAIGA_FLIGHT_ROUTE_WAYPOINT_INDEX : [NSNumber numberWithUnsignedInteger:index]}];
}

- (void) didRemoveWaypoint:(Waypoint*)waypoint atIndex:(NSUInteger)index
{
    [waypointPositions removeObjectAtIndex:index];
    [waypointShapes removeObjectAtIndex:index];
    [waypointPath setPositions:waypointPositions];

    [[NSNotificationCenter defaultCenter] postNotificationName:TAIGA_FLIGHT_ROUTE_CHANGED object:self
                                                      userInfo:@{TAIGA_FLIGHT_ROUTE_WAYPOINT_INDEX : [NSNumber numberWithUnsignedInteger:index]}];
}

- (void) didMoveWaypoint:(Waypoint*)waypoint fromIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex
{
    id pos = [waypointPositions objectAtIndex:fromIndex];
    [waypointPositions removeObjectAtIndex:fromIndex];
    [waypointPositions insertObject:pos atIndex:toIndex];
    [waypointPath setPositions:waypointPositions];

    id shape = [waypointShapes objectAtIndex:fromIndex];
    [waypointShapes removeObjectAtIndex:fromIndex];
    [waypointShapes insertObject:shape atIndex:toIndex];

    [[NSNotificationCenter defaultCenter] postNotificationName:TAIGA_FLIGHT_ROUTE_CHANGED object:self
                                                      userInfo:@{TAIGA_FLIGHT_ROUTE_WAYPOINT_INDEX : [NSNumber numberWithUnsignedInteger:toIndex]}];
}

@end