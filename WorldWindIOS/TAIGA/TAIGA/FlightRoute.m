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
#import "WorldWind/Util/WWMath.h"
#import "WorldWind/WorldWindConstants.h"
#import "WorldWind/WWLog.h"
#import "WorldWind/WorldWindView.h"

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
    [path setNumSubsegments:100];
    [path setAttributes:shapeAttrs];
    [path setHighlightAttributes:[[WWShapeAttributes alloc] initWithAttributes:shapeAttrs]];
    [path setPickDelegate:@{@"flightRoute":self}];

    return path;
}

- (id) createShapeForWaypoint:(Waypoint*)waypoint withPosition:(WWPosition*)position
{
    WWSphere* shape = [[WWSphere alloc] initWithPosition:position radiusInPixels:ShapeRadius];
    [shape setAttributes:shapeAttrs];
    [shape setHighlightAttributes:[[WWShapeAttributes alloc] initWithAttributes:shapeAttrs]];

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

    [self updateAnimation]; // does nothing when there's no animation running

    [waypointPath render:dc];

    NSUInteger index = 0;
    for (id shape in waypointShapes)
    {
        double originalRadius = [shape radius];
        if ([dc pickingMode])
        {
            [shape setRadius:ShapePickRadius];
            [shape setPickDelegate:@{@"flightRoute":self, @"waypointIndex":[NSNumber numberWithUnsignedInteger:index]}];
        }

        [shape render:dc];

        if ([dc pickingMode])
        {
            [shape setRadius:originalRadius];
        }

        index++;
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

- (NSUInteger) indexOfWaypoint:(Waypoint*)waypoint
{
    if (waypoint == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Waypoint is nil")
    }

    return [waypoints indexOfObject:waypoint];
}

- (BOOL) containsWaypoint:(Waypoint*)waypoint
{
    if (waypoint == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Waypoint is nil")
    }

    return [waypoints containsObject:waypoint];
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

- (void) replaceWaypointAtIndex:(NSUInteger)index withWaypoint:(Waypoint*)newWaypoint
{
    if (index >= [waypoints count])
    {
        NSString* msg = [[NSString alloc] initWithFormat:@"Index %d is out of range", index];
        WWLOG_AND_THROW(NSInvalidArgumentException, msg)
    }

    if (newWaypoint == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Waypoint is nil")
    }

    Waypoint* waypoint = [waypoints objectAtIndex:index];
    [waypoints replaceObjectAtIndex:index withObject:newWaypoint];
    [self didReplaceWaypoint:waypoint atIndex:index withWaypoint:newWaypoint];
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

- (void) updateWaypointAtIndex:(NSUInteger)index
{
    if (index >= [waypoints count])
    {
        NSString* msg = [[NSString alloc] initWithFormat:@"Index %d is out of range", index];
        WWLOG_AND_THROW(NSInvalidArgumentException, msg)
    }

    Waypoint* waypoint = [waypoints objectAtIndex:index];
    [self didUpdateWaypoint:waypoint atIndex:index];
}

- (BOOL) isWaypointAtIndexHighlighted:(NSUInteger)index
{
    if (index >= [waypoints count])
    {
        NSString* msg = [[NSString alloc] initWithFormat:@"Index %d is out of range", index];
        WWLOG_AND_THROW(NSInvalidArgumentException, msg)
    }

    return [[waypointShapes objectAtIndex:index] isHighlighted];
}

- (void) highlightWaypointAtIndex:(NSUInteger)index highlighted:(BOOL)highlighted
{
    if (index >= [waypoints count])
    {
        NSString* msg = [[NSString alloc] initWithFormat:@"Index %d is out of range", index];
        WWLOG_AND_THROW(NSInvalidArgumentException, msg)
    }

    if (highlighted)
    {
        [self highlightWaypointAtIndex:index];
    }
    else
    {
        [self unhiglightWaypointAtIndex:index];
    }
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

    [[NSNotificationCenter defaultCenter] postNotificationName:TAIGA_FLIGHT_ROUTE_WAYPOINT_INSERTED object:self
                                                      userInfo:@{TAIGA_FLIGHT_ROUTE_WAYPOINT_INDEX : [NSNumber numberWithUnsignedInteger:index]}];
}

- (void) didRemoveWaypoint:(Waypoint*)waypoint atIndex:(NSUInteger)index
{
    [waypointPositions removeObjectAtIndex:index];
    [waypointShapes removeObjectAtIndex:index];
    [waypointPath setPositions:waypointPositions];

    [[NSNotificationCenter defaultCenter] postNotificationName:TAIGA_FLIGHT_ROUTE_WAYPOINT_REMOVED object:self
                                                      userInfo:@{TAIGA_FLIGHT_ROUTE_WAYPOINT_INDEX : [NSNumber numberWithUnsignedInteger:index]}];
}

- (void) didReplaceWaypoint:(Waypoint*)waypoint atIndex:(NSUInteger)index withWaypoint:(Waypoint*)newWaypoint
{
    WWPosition* pos = [waypointPositions objectAtIndex:index];
    [pos setLocation:[newWaypoint location]];
    [waypointPath setPositions:waypointPositions];

    id shape = [waypointShapes objectAtIndex:index];
    [self updateShape:shape withPosition:pos];

    [[NSNotificationCenter defaultCenter] postNotificationName:TAIGA_FLIGHT_ROUTE_WAYPOINT_REPLACED object:self
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

    [[NSNotificationCenter defaultCenter] postNotificationName:TAIGA_FLIGHT_ROUTE_WAYPOINT_MOVED object:self
                                                      userInfo:@{TAIGA_FLIGHT_ROUTE_WAYPOINT_INDEX : [NSNumber numberWithUnsignedInteger:toIndex]}];
}

- (void) didUpdateWaypoint:(Waypoint*)waypoint atIndex:(NSUInteger)index
{
    WWPosition* pos = [waypointPositions objectAtIndex:index];
    [pos setLocation:[waypoint location]];
    [waypointPath setPositions:waypointPositions];

    id shape = [waypointShapes objectAtIndex:index];
    [self updateShape:shape withPosition:pos];

    [[NSNotificationCenter defaultCenter] postNotificationName:TAIGA_FLIGHT_ROUTE_WAYPOINT_UPDATED object:self
                                                      userInfo:@{TAIGA_FLIGHT_ROUTE_WAYPOINT_INDEX : [NSNumber numberWithUnsignedInteger:index]}];
}

- (void) highlightWaypointAtIndex:(NSUInteger)index
{
    id shape = [waypointShapes objectAtIndex:index];
    [shape setHighlighted:YES];

    NSTimeInterval t0 = [NSDate timeIntervalSinceReferenceDate];
    NSTimeInterval t1 = t0 + 0.2;
    NSTimeInterval t2 = t1 + 0.2;

    double r0 = ShapeRadius;
    double r1 = 3 * r0;
    double r2 = 2 * r0;

    WWColor* c0 = [[WWColor alloc] initWithColor:[(WWShapeAttributes*) [shape attributes] interiorColor]];
    WWColor* c1 = [[WWColor alloc] initWithR:1 g:1 b:1 a:1];

    [self beginAnimation:^(NSDate *timestamp, BOOL *stop)
    {
        NSTimeInterval now = [timestamp timeIntervalSinceReferenceDate];
        if (now > t0 && now < t1)
        {
            double pct = [WWMath smoothStepValue:now min:t0 max:t1];
            double radius = [WWMath interpolateValue1:r0 value2:r1 amount:pct];
            [shape setRadius:radius];
            [WWColor interpolateColor1:c0 color2:c1 amount:pct result:[[shape highlightAttributes] interiorColor]];
        }
        else if (now >= t1 && now < t2)
        {
            double pct = [WWMath smoothStepValue:now min:t1 max:t2];
            double radius = [WWMath interpolateValue1:r1 value2:r2 amount:pct];
            [shape setRadius:radius];
            [[[shape highlightAttributes] interiorColor] setToColor:c1];
        }
        else if (now >= t2)
        {
            [shape setRadius:r2];
            [[[shape highlightAttributes] interiorColor] setToColor:c1];
            *stop = YES;
        }
    }];
}

- (void) unhiglightWaypointAtIndex:(NSUInteger)index
{
    id shape = [waypointShapes objectAtIndex:index];

    NSTimeInterval t0 = [NSDate timeIntervalSinceReferenceDate];
    NSTimeInterval t1 = t0 + 0.2;

    double r0 = [shape radius];
    double r1 = ShapeRadius;

    WWColor* c0 = [[WWColor alloc] initWithColor:[[shape highlightAttributes] interiorColor]];
    WWColor* c1 = [[WWColor alloc] initWithColor:[(WWShapeAttributes*) [shape attributes] interiorColor]];

    [self beginAnimation:^(NSDate *timestamp, BOOL *stop)
    {
        NSTimeInterval now = [timestamp timeIntervalSinceReferenceDate];
        if (now > t0 && now < t1)
        {
            double pct = [WWMath smoothStepValue:now min:t0 max:t1];
            double radius = [WWMath interpolateValue1:r0 value2:r1 amount:pct];
            [shape setRadius:radius];
            [WWColor interpolateColor1:c0 color2:c1 amount:pct result:[[shape highlightAttributes] interiorColor]];
        }
        else if (now >= t1)
        {
            [shape setRadius:r1];
            [[[shape highlightAttributes] interiorColor] setToColor:c1];
            [shape setHighlighted:NO];
            *stop = YES;
        }
    }];
}

- (void) beginAnimation:(void (^)(NSDate* timestamp, BOOL* stop))block
{
    if (animating) // the current animation must end or be forced to end before another one can begin
        return;

    animating = YES;
    animationBlock = block;
    [WorldWindView startRedrawing];
}

- (void) endAnimation
{
    if (!animating) // ignore this call when there's no animation running
        return;

    animating = NO;
    animationBlock = NULL;
    [WorldWindView stopRedrawing];
}

- (void) updateAnimation
{
    if (!animating) // ignore this call when there's no animation running
        return;

    NSDate* timestamp = [NSDate date]; // now
    BOOL stop = NO; // stop the animation when the caller's block requests it
    animationBlock(timestamp, &stop);

    if (stop) // the caller's block requested that the animation stop
    {
        [self endAnimation];
    }
}

@end