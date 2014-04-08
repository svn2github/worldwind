/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "WorldWind/Render/WWRenderable.h"

@class Waypoint;
@class WWGlobe;
@class WWPath;
@class WWPosition;
@class WWSector;
@class WWShapeAttributes;
@protocol WWExtent;

typedef void (^FlightRouteAnimationBlock)(NSDate* timestamp, BOOL* stop);

@interface FlightRoute : NSObject <WWRenderable>
{
@protected
    NSMutableArray* waypoints;
    NSMutableArray* waypointPositions;
    NSMutableArray* waypointShapes;
    WWPath* waypointPath;
    WWShapeAttributes* shapeAttrs;
    WWPosition* currentPosition;
    NSMutableArray* animations;
}

+ (NSArray*) flightRouteColors;

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

- (id<WWExtent>) extentOnGlobe:(WWGlobe*)globe;

- (void) locationForPercent:(double)pct
                   latitude:(CLLocationDegrees*)latitude
                  longitude:(CLLocationDegrees*)longitude
                   altitude:(CLLocationDistance*)altitude
                     course:(CLLocationDirection*)course;

- (NSUInteger) waypointCount;

- (Waypoint*) waypointAtIndex:(NSUInteger)index;

- (NSUInteger) indexOfWaypoint:(Waypoint*)waypoint;

- (BOOL) containsWaypoint:(Waypoint*)waypoint;

- (void) addWaypoint:(Waypoint*)waypoint;

- (void) insertWaypoint:(Waypoint*)waypoint atIndex:(NSUInteger)index;

- (void) removeWaypoint:(Waypoint*)waypoint;

- (void) removeWaypointAtIndex:(NSUInteger)index;

- (void) replaceWaypointAtIndex:(NSUInteger)index withWaypoint:(Waypoint*)newWaypoint;

- (void) moveWaypointAtIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex;

- (void) updateWaypointAtIndex:(NSUInteger)index;

- (BOOL) isWaypointAtIndexHighlighted:(NSUInteger)index;

- (void) highlightWaypointAtIndex:(NSUInteger)index highlighted:(BOOL)highlighted;

@end