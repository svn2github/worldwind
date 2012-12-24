/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "WorldWind/Geometry/WWPosition.h"

@implementation WWPosition

- (id) copyWithZone:(NSZone*)zone
{
    return [[[self class] alloc] initWithDegreesLatitude:[self latitude]
                                               longitude:[self longitude]
                                                altitude:_altitude];
}

- (WWPosition*) initWithDegreesLatitude:(double)latitude longitude:(double)longitude altitude:(double)metersElevation
{
    self = [super initWithDegreesLatitude:latitude longitude:longitude];

    if (self != nil)
    {
        _altitude = metersElevation;
    }

    return self;
}

- (WWPosition*) setDegreesLatitude:(double)latitude longitude:(double)longitude altitude:(double)metersAltitude
{
    [super setDegreesLatitude:latitude longitude:longitude]; // Let the superclass set the latitude and longitude.
    _altitude = metersAltitude;

    return self;
}

@end
