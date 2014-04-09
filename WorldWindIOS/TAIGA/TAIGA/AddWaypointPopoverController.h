/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "DraggablePopoverController.h"

@class MovingMapViewController;

@interface AddWaypointPopoverController : DraggablePopoverController <UITableViewDataSource, UITableViewDelegate, UINavigationControllerDelegate>
{
@protected
    UITableViewController* addWaypointController;
    UITableViewController* flightRouteChooser;
    UINavigationController* navigationController;
    NSMutableArray* addWaypointTableCells;
    NSMutableArray* flightRouteTableCells;
}

@property (nonatomic, readonly) id waypointSource;

@property (nonatomic, readonly) MovingMapViewController* mapViewController;

- (id) initWithWaypointSource:(id)waypointSource mapViewController:(MovingMapViewController*)mapViewController;

@end