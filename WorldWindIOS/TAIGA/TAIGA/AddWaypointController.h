/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>

@class MovingMapViewController;
@class Waypoint;

@interface AddWaypointController : UITableViewController

@property (nonatomic, readonly) Waypoint* waypoint;

@property (nonatomic, readonly) MovingMapViewController* mapViewController;

@property (nonatomic) UIPopoverController* presentingPopoverController;

- (id) initWithWaypoint:(Waypoint*)waypoint mapViewController:(MovingMapViewController*)mapViewController;

@end