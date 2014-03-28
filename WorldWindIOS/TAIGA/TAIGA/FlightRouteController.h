/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>

@class FlightRoute;
@class WaypointDatabase;
@class WorldWindView;
@class WWRenderableLayer;

@interface FlightRouteController : UITableViewController <UINavigationControllerDelegate, UIAlertViewDelegate>
{
@protected
    NSUInteger flightRouteColorIndex;
    void (^newFlightRouteCompletionBlock)(FlightRoute* newFlightRoute);
}

@property (nonatomic, readonly) WorldWindView* wwv;

@property (nonatomic, readonly) WWRenderableLayer* flightRouteLayer;

@property (nonatomic, readonly) WaypointDatabase* waypointDatabase;

- (FlightRouteController*) initWithWorldWindView:(WorldWindView*)wwv flightRouteLayer:(WWRenderableLayer*)flightRouteLayer waypointDatabase:(WaypointDatabase*)waypointDatabase;

- (NSUInteger) flightRouteCount;

- (FlightRoute*) flightRouteAtIndex:(NSUInteger)index;

- (FlightRoute*) presentedFlightRoute;

- (void) presentFlightRouteAtIndex:(NSUInteger)index;

- (void) newFlightRoute:(void (^)(FlightRoute* newFlightRoute))completionBlock;

@end