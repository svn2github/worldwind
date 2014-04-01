/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>

@class Waypoint;
@class MovingMapViewController;

@interface AddWaypointPopoverController : UIPopoverController <UITableViewDataSource, UITableViewDelegate, UINavigationControllerDelegate>
{
@protected
    UITableViewController* addWaypointController;
    UITableViewController* flightRouteChooser;
    UINavigationController* navigationController;
    NSMutableArray* addWaypointTableCells;
    NSMutableArray* flightRouteTableCells;
}

@property (nonatomic, readonly) Waypoint* waypoint;

@property (nonatomic, readonly) MovingMapViewController* mapViewController;

@property (nonatomic) BOOL addWaypointToDatabase;

- (id) initWithWaypoint:(Waypoint*)waypoint mapViewController:(MovingMapViewController*)mapViewController;

@end