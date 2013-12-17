/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "AircraftPosition.h"


@implementation AircraftPosition

- (AircraftPosition*) initWithPosition:(WWPosition*)position heading:(double)heading
{
    self = [super initWithDegreesLatitude:[position latitude] longitude:[position longitude] altitude:[position altitude]];

    _heading = heading;

    return self;
}

@end