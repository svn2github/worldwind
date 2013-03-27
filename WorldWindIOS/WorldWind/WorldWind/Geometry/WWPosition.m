/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "WorldWind/Geometry/WWPosition.h"
#import "WorldWind/WWLog.h"

@implementation WWPosition

- (id) copyWithZone:(NSZone*)zone
{
    return [[[self class] alloc] initWithDegreesLatitude:[self latitude]
                                               longitude:[self longitude]
                                                altitude:_altitude];
}

- (WWPosition*) initWithDegreesLatitude:(double)latitude longitude:(double)longitude altitude:(double)metersAltitude
{
    self = [super initWithDegreesLatitude:latitude longitude:longitude];

    _altitude = metersAltitude;

    return self;
}

- (WWPosition*) initWithLocation:(WWLocation*)location altitude:(double)metersAltitude
{
    if (location == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Location is nil")
    }

    self = [super initWithLocation:location];

    _altitude = metersAltitude;

    return self;
}

- (WWPosition*) initWithPosition:(WWPosition*)position
{
    if (position == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Position is nil")
    }

    self = [super initWithLocation:position]; // Let the superclass set the latitude and longitude.

    _altitude = position->_altitude;

    return self;
}

- (WWPosition*) setDegreesLatitude:(double)latitude longitude:(double)longitude altitude:(double)metersAltitude
{
    [super setDegreesLatitude:latitude longitude:longitude];

    _altitude = metersAltitude;

    return self;
}

- (WWPosition*) setLocation:(WWLocation*)location altitude:(double)metersAltitude
{
    if (location == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Location is nil")
    }

    [super setLocation:location];

    _altitude = metersAltitude;

    return self;
}

- (WWPosition*) setPosition:(WWPosition*)position
{
    if (position == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Position is nil")
    }

    [super setLocation:position]; // Let the superclass set the latitude and longitude.

    _altitude = position->_altitude;

    return self;
}

@end