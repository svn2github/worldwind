/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WorldWind/Render/WWRenderable.h"

@class Waypoint;
@class WWDrawContext;

@interface FlightPath : NSObject <WWRenderable>
{
@protected
    NSMutableArray* waypoints;
}

@property (nonatomic, readonly) NSString* stateKey;

/// Indicates this flight path's display name.
@property (nonatomic) NSString* displayName;

/// Indicates whether this flight path should be displayed.
@property (nonatomic) BOOL enabled;

- (FlightPath*) init;

- (FlightPath*) initWithStateKey:(NSString*)stateKey waypointDatabase:(NSArray*)waypointDatabase;

- (void) removeState;

- (void) render:(WWDrawContext*)dc;

- (NSUInteger) waypointCount;

- (Waypoint*) waypointAtIndex:(NSUInteger)index;

- (void) addWaypoint:(Waypoint*)waypoint;

- (void) insertWaypoint:(Waypoint*)waypoint atIndex:(NSUInteger)index;

- (void) removeWaypoint:(Waypoint*)waypoint;

- (void) removeWaypointAtIndex:(NSUInteger)index;

- (void) moveWaypointAtIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex;

@end