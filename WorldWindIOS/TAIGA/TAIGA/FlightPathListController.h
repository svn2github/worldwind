/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>

@interface FlightPathListController : UITableViewController <UINavigationControllerDelegate, UIAlertViewDelegate>
{
@protected
    NSMutableArray* flightPaths;
    NSMutableArray* waypointDatabase;
}

- (FlightPathListController*) init;

@end