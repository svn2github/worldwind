/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "Waypoint.h"

@interface MutableWaypoint : Waypoint

- (id) initWithDegreesLatitude:(double)latitude longitude:(double)longitude;

- (void) setDegreesLatitude:(double)latitude longitude:(double)longitude;

@end