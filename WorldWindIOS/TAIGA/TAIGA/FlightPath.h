/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WorldWind/Render/WWRenderable.h"

@class Waypoint;
@class WWPath;
@class WWShapeAttributes;
@protocol FlightPathDelegate;

@interface FlightPath : NSObject <WWRenderable>
{
@protected
    NSMutableArray* waypoints;
    NSMutableArray* waypointPositions;
    WWPath* path;
}

/// Indicates this flight path's display name.
@property (nonatomic) NSString* displayName;

/// Indicates whether this flight path should be displayed.
@property (nonatomic) BOOL enabled;

@property (nonatomic) id<FlightPathDelegate> delegate;

/// A field for application-specific use, typically used to associate application data with the shape.
@property (nonatomic) id userObject;

- (FlightPath*) init;

- (FlightPath*) initWithWaypoints:(NSArray*)waypointArray;

- (NSUInteger) waypointCount;

- (Waypoint*) waypointAtIndex:(NSUInteger)index;

- (void) addWaypoint:(Waypoint*)waypoint;

- (void) insertWaypoint:(Waypoint*)waypoint atIndex:(NSUInteger)index;

- (void) removeWaypoint:(Waypoint*)waypoint;

- (void) removeWaypointAtIndex:(NSUInteger)index;

- (void) moveWaypointAtIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex;

@end