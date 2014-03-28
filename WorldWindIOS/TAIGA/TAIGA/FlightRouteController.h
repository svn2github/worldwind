/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>

@class FlightRoute;
@class WaypointFile;
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

@property (nonatomic, readonly) WaypointFile* waypointFile;

- (FlightRouteController*) initWithWorldWindView:(WorldWindView*)wwv flightRouteLayer:(WWRenderableLayer*)flightRouteLayer waypointFile:(WaypointFile*)waypointFile;

- (NSUInteger) flightRouteCount;

- (FlightRoute*) flightRouteAtIndex:(NSUInteger)index;

- (FlightRoute*) presentedFlightRoute;

- (void) presentFlightRouteAtIndex:(NSUInteger)index;

- (void) newFlightRoute:(void (^)(FlightRoute* newFlightRoute))completionBlock;

@end