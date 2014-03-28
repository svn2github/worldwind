/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <UIKit/UIKit.h>

@class WorldWindView;
@class FlightRoute;

@interface MovingMapViewController : UIViewController <UIGestureRecognizerDelegate, UINavigationControllerDelegate>

@property (nonatomic, readonly) WorldWindView* wwv;

- (MovingMapViewController*) initWithFrame:(CGRect)frame;

- (NSUInteger) flightRouteCount;

- (FlightRoute*) flightRouteAtIndex:(NSUInteger)index;

- (FlightRoute*) presentedFlightRoute;

- (void) presentFlightRouteAtIndex:(NSUInteger)index;

- (void) newFlightRoute:(void (^)(FlightRoute* newFlightRoute))completionBlock;

@end
