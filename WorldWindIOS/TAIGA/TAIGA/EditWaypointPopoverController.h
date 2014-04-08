/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>

@class Waypoint;
@class FlightRoute;
@class MovingMapViewController;

@interface EditWaypointPopoverController : UIPopoverController <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>
{
@protected
    UITableViewController* tableViewController;
    UINavigationController* navigationController;
    NSMutableArray* tableCells;
}

@property (nonatomic, readonly) FlightRoute* flightRoute;

@property (nonatomic, readonly) NSUInteger waypointIndex;

@property (nonatomic, readonly) MovingMapViewController* mapViewController;

- (id) initWithFlightRoute:(FlightRoute*)flightRoute waypointIndex:(NSUInteger)waypointIndex mapViewController:(MovingMapViewController*)mapViewController;

@end