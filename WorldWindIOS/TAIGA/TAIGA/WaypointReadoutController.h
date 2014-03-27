/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>

@class Waypoint;

@interface WaypointReadoutController : UITableViewController
{
@protected
    NSMutableArray* tableCells;
}

@property (nonatomic) Waypoint* waypoint;

@property (nonatomic) UIPopoverController* presentingPopoverController;

@end