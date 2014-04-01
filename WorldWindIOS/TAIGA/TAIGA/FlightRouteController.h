/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WorldWind/Render/WWRenderable.h"

@class FlightRoute;
@class WaypointDatabase;
@class WorldWindView;

@interface FlightRouteController : UITableViewController <UINavigationControllerDelegate, UIAlertViewDelegate, WWRenderable>
{
@protected
    NSMutableArray* flightRoutes;
    NSUInteger newFlightRouteColorIndex;
    void (^newFlightRouteCompletionBlock)(FlightRoute* newFlightRoute);
}

/// @name Attributes

@property (nonatomic) NSString* displayName;

@property (nonatomic) BOOL enabled;

@property (nonatomic, readonly) WorldWindView* wwv;

@property (nonatomic, readonly) WaypointDatabase* waypointDatabase;

/// @name Initializing FlightRouteController

- (FlightRouteController*) initWithWorldWindView:(WorldWindView*)wwv waypointDatabase:(WaypointDatabase*)waypointDatabase;

/// @name Managing the Flight Route List

- (NSUInteger) flightRouteCount;

- (FlightRoute*) flightRouteAtIndex:(NSUInteger)index;

- (BOOL) containsFlightRoute:(FlightRoute*)flightRoute;

- (void) addFlightRoute:(FlightRoute*)flightRoute;

- (void) insertFlightRoute:(FlightRoute*)flightRoute atIndex:(NSUInteger)index;

- (void) removeFlightRoute:(FlightRoute*)flightRoute;

- (void) removeFlightRouteAtIndex:(NSUInteger)index;

- (void) moveFlightRouteAtIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex;

/// @name Creating and Presenting Flight Routes

- (void) newFlightRoute:(void (^)(FlightRoute* newFlightRoute))completionBlock;

- (FlightRoute*) presentedFlightRoute;

- (void) presentFlightRouteAtIndex:(NSUInteger)index editing:(BOOL)editing;

/// @name Saving and Restoring Flight Route State

- (void) restoreFlightRouteState;

@end