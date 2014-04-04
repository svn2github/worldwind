/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>

@class Waypoint;
@class FlightRoute;
@class MovingMapViewController;

@interface EditWaypointPopoverController : UIPopoverController <UITableViewDataSource, UITableViewDelegate>
{
@protected
    UITableViewController* tableViewController;
    UINavigationController* navigationController;
    NSMutableArray* tableCells;
}

@property (nonatomic, readonly) Waypoint* waypoint;

@property (nonatomic, readonly) FlightRoute* flightRoute;

@property (nonatomic, readonly) MovingMapViewController* mapViewController;

- (id) initWithWaypoint:(Waypoint*)waypoint flightRoute:(FlightRoute*)flightRoute mapViewController:(MovingMapViewController*)mapViewController;

@end