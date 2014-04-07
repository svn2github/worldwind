/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "MutableWaypoint.h"
#import "TAIGA.h"
#import "UnitsFormatter.h"
#import "WorldWind/Geometry/WWLocation.h"

@implementation MutableWaypoint

- (id) initWithDegreesLatitude:(double)latitude longitude:(double)longitude
{
    self = [super initWithDegreesLatitude:latitude longitude:longitude];

    return self;
}

- (void) setDegreesLatitude:(double)latitude longitude:(double)longitude
{
    [[self location] setDegreesLatitude:latitude longitude:longitude];
    [self setDisplayName:[[TAIGA unitsFormatter] formatDegreesLatitude:latitude longitude:longitude]];
}

@end