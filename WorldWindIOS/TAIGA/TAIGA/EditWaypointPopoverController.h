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

@interface EditWaypointPopoverController : DraggablePopoverController <UITableViewDataSource, UITableViewDelegate, UIPopoverControllerDelegate, UIAlertViewDelegate>
{
@protected
    UITableViewController* tableViewController;
    UINavigationController* navigationController;
    UIBarButtonItem* cancelButtonItem;
    NSMutableArray* tableCells;
    Waypoint* oldWaypoint;
    Waypoint* newWaypoint;
}

@property (nonatomic, readonly) FlightRoute* flightRoute;

@property (nonatomic, readonly) NSUInteger waypointIndex;

@property (nonatomic, readonly) MovingMapViewController* mapViewController;

- (id) initWithFlightRoute:(FlightRoute*)flightRoute waypointIndex:(NSUInteger)waypointIndex mapViewController:(MovingMapViewController*)mapViewController;

@end