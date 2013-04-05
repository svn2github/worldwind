/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "WorldWind/Geometry/WWPosition.h"
#import "WorldWind/WWLog.h"
#import "WWMath.h"

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

    self = [super initWithLocation:position]; // Let the superclass initialize latitude and longitude.

    _altitude = position->_altitude;

    return self;
}

- (WWPosition*) initWithCLPosition:(CLLocation*)location
{
    if (location == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Location is nil")
    }

    self = [super initWithCLLocation:location]; // Let the superclass initialize latitude and longitude.

    _altitude = [location altitude];

    return self;
}

- (WWPosition*) initWithZeroPosition
{
    self = [super initWithZeroLocation]; // Let the superclass initialize latitude and longitude.

    _altitude = 0;

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

- (WWPosition*) setCLPosition:(CLLocation*)location
{
    if (location == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Location is nil")
    }

    [super setCLLocation:location]; // Let the superclass set the latitude and longitude.

    _altitude = [location altitude];

    return self;
}

+ (void) greatCircleInterpolate:(WWPosition*)beginPosition
                    endPosition:(WWPosition*)endPosition
                         amount:(double)amount
                 outputPosition:(WWPosition*)result
{
    if (beginPosition == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Begin position is nil")
    }

    if (endPosition == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"End position is nil")
    }

    if (result == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Output position is nil")
    }

    [WWLocation greatCircleInterpolate:beginPosition endLocation:endPosition amount:amount outputLocation:result];
    result->_altitude = [WWMath interpolateValue1:[beginPosition altitude] value2:[endPosition altitude] amount:amount];
}

+ (void) rhumbInterpolate:(WWPosition*)beginPosition
              endPosition:(WWPosition*)endPosition
                   amount:(double)amount
           outputPosition:(WWPosition*)result
{
    if (beginPosition == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Begin position is nil")
    }

    if (endPosition == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"End position is nil")
    }

    if (result == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Output position is nil")
    }

    [WWLocation rhumbInterpolate:beginPosition endLocation:endPosition amount:amount outputLocation:result];
    result->_altitude = [WWMath interpolateValue1:[beginPosition altitude] value2:[endPosition altitude] amount:amount];
}

+ (void) linearInterpolate:(WWPosition*)beginPosition
               endPosition:(WWPosition*)endPosition
                    amount:(double)amount
            outputPosition:(WWPosition*)result
{
    if (beginPosition == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Begin position is nil")
    }

    if (endPosition == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"End position is nil")
    }

    if (result == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Output position is nil")
    }

    [WWLocation linearInterpolate:beginPosition endLocation:endPosition amount:amount outputLocation:result];
    result->_altitude = [WWMath interpolateValue1:[beginPosition altitude] value2:[endPosition altitude] amount:amount];
}

+ (void) forecastPosition:(CLLocation*)location
                  forDate:(NSDate*)date
                  onGlobe:(WWGlobe*)globe
           outputPosition:(WWPosition*)result
{
    if (location == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Location is nil")
    }

    if (date == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Date is nil")
    }

    if (globe == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Globe is nil")
    }

    if (result == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Output position is nil")
    }

    [WWLocation forecastLocation:location forDate:date onGlobe:globe outputLocation:result];
    result->_altitude = [location altitude];
}

@end