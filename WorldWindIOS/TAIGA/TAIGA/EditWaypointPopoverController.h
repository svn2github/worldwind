/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "DraggablePopoverController.h"

@class FlightRoute;
@class MovingMapViewController;
@class Waypoint;

@interface EditWaypointPopoverController : DraggablePopoverController <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate, UINavigationControllerDelegate>
{
@protected
    UITableViewController* tableViewController;
    UINavigationController* navigationController;
    NSMutableArray* tableCells;
    Waypoint* oldWaypoint;
}

@property (nonatomic, readonly) FlightRoute* flightRoute;

@property (nonatomic, readonly) NSUInteger waypointIndex;

@property (nonatomic, readonly) MovingMapViewController* mapViewController;

- (id) initWithFlightRoute:(FlightRoute*)flightRoute waypointIndex:(NSUInteger)waypointIndex mapViewController:(MovingMapViewController*)mapViewController;

@end