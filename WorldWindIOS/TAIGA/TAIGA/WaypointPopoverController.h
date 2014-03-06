/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>

@class FlightRoute;
@class Waypoint;
@class WWPickedObject;

@interface WaypointPopoverController : UIPopoverController<UITableViewDataSource, UITableViewDelegate>
{
@protected
    NSMutableArray* tableCells;
    WWPickedObject* pickedObject;
}

@property (nonatomic) FlightRoute* activeFlightRoute;

- (void) presentPopoverFromPickedObject:(WWPickedObject*)po inView:(UIView*)view
               permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections animated:(BOOL)animated;

@end