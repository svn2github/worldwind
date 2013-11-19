/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WorldWind/Render/WWRenderable.h"

@class Waypoint;
@class WWPath;
@class WWSector;
@class WWShapeAttributes;

@interface FlightRoute : NSObject <WWRenderable>
{
@protected
    NSMutableArray* waypoints;
    NSMutableArray* waypointPositions;
    NSMutableArray* waypointShapes;
    WWPath* waypointPath;
    WWSector* waypointSector;
    WWShapeAttributes* shapeAttrs;
}

/// Indicates this flight route's display name.
@property (nonatomic) NSString* displayName;

/// Indicates whether this flight route should be displayed.
@property (nonatomic) BOOL enabled;

@property (nonatomic) double altitude;

@property (nonatomic) NSUInteger colorIndex;

/// A field for application-specific use, typically used to associate application data with the shape.
@property (nonatomic) id userObject;

- (FlightRoute*) init;

- (FlightRoute*) initWithWaypoints:(NSArray*)waypointArray;

+ (NSArray*) flightRouteColors;

- (WWSector*) waypointSector;

- (NSUInteger) waypointCount;

- (Waypoint*) waypointAtIndex:(NSUInteger)index;

- (void) addWaypoint:(Waypoint*)waypoint;

- (void) insertWaypoint:(Waypoint*)waypoint atIndex:(NSUInteger)index;

- (void) removeWaypoint:(Waypoint*)waypoint;

- (void) removeWaypointAtIndex:(NSUInteger)index;

- (void) moveWaypointAtIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex;

@end