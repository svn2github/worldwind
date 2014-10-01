/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WorldWind/Render/WWRenderable.h"

@class FlightRoute;
@class WorldWindView;

@interface FlightRouteController : UITableViewController <WWRenderable>
{
@protected
    NSMutableArray* flightRoutes;
    NSUInteger newFlightRouteColorIndex;
    BOOL isSavingState;
}

/// @name Attributes

@property (nonatomic) NSString* displayName;

@property (nonatomic) BOOL enabled;

@property (nonatomic, readonly) WorldWindView* wwv;

/// @name Initializing FlightRouteController

- (FlightRouteController*) initWithWorldWindView:(WorldWindView*)wwv;

/// @name Managing the Flight Route List

- (NSUInteger) flightRouteCount;

- (FlightRoute*) flightRouteAtIndex:(NSUInteger)index;

- (NSUInteger) indexOfFlightRoute:(FlightRoute*)flightRoute;

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

@end