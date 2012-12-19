/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "WorldWind/Geometry/WWPosition.h"

@implementation WWPosition

- (WWPosition*) initWithDegreesLatitude:(double)latitude longitude:(double)longitude elevation:(double)metersElevation
{
    self = [super initWithDegreesLatitude:latitude longitude:longitude];

    if (self != nil)
    {
        _elevation = metersElevation;
    }

    return self;
}

- (WWPosition*) setDegreesLatitude:(double)latitude longitude:(double)longitude elevation:(double)metersElevation
{
    [super setDegreesLatitude:latitude longitude:longitude]; // Let the superclass set the latitude and longitude.
    _elevation = metersElevation;

    return self;
}

@end
