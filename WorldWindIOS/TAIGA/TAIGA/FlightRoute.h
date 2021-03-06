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
@class WWShapeAttributes;
@protocol WWExtent;

@interface FlightRoute : NSObject <WWRenderable>
{
@protected
    NSMutableArray* waypoints;
    NSMutableArray* waypointPositions;
    NSMutableArray* waypointShapes;
    NSMutableArray* arrowShapes;
    WWPath* waypointPath;
    WWShapeAttributes* pathAttrs;
    WWShapeAttributes* shapeAttrs;
    WWPosition* currentPosition;
}

+ (NSArray*) flightRouteColors;

/// Indicates this flight route's display name.
@property (nonatomic) NSString* displayName;

/// Indicates whether this flight route should be displayed.
@property (nonatomic) BOOL enabled;

@property (nonatomic) NSUInteger colorIndex;

@property (nonatomic) double defaultAltitude;

/// A field for application-specific use, typically used to associate application data with the shape.
@property (nonatomic) id userObject;

- (id) initWithDisplayName:(NSString*)displayName colorIndex:(NSUInteger)colorIndex defaultAltitude:(double)defaultAltitude;

- (id) initWithPropertyList:(NSDictionary*)propertyList;

- (NSDictionary*) asPropertyList;

- (id<WWExtent>) extentOnGlobe:(WWGlobe*)globe;

- (void) locationForPercent:(double)pct
                   latitude:(CLLocationDegrees*)latitude
                  longitude:(CLLocationDegrees*)longitude
                   altitude:(CLLocationDistance*)altitude
                     course:(CLLocationDirection*)course;

- (NSUInteger) waypointCount;

- (Waypoint*) waypointAtIndex:(NSUInteger)index;

- (NSUInteger) indexOfWaypoint:(Waypoint*)waypoint;

- (void) insertWaypoint:(Waypoint*)waypoint atIndex:(NSUInteger)index;

- (void) removeWaypointAtIndex:(NSUInteger)index;

- (void) replaceWaypointAtIndex:(NSUInteger)index withWaypoint:(Waypoint*)newWaypoint;

- (void) moveWaypointAtIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex;

- (void) reverseWaypoints;

@end