/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>

@class FlightRoute;
@class Waypoint;

@interface UITableViewCell (TAIGAAdditions)

- (void) setToFlightRoute:(FlightRoute*)flightRoute;

- (void) setToWaypoint:(Waypoint*)waypoint;

@end