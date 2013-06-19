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

- (WWPosition*) initWithLocation:(WWLocation* __unsafe_unretained)location altitude:(double)metersAltitude
{
    if (location == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Location is nil")
    }

    self = [super initWithLocation:location];

    _altitude = metersAltitude;

    return self;
}

- (WWPosition*) initWithPosition:(WWPosition* __unsafe_unretained)position
{
    if (position == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Position is nil")
    }

    self = [super initWithLocation:position]; // Let the superclass initialize latitude and longitude.

    _altitude = position->_altitude;

    return self;
}

- (WWPosition*) initWithCLLocation:(CLLocation* __unsafe_unretained)location altitude:(double)metersAltitude
{
    if (location == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Location is nil")
    }

    self = [super initWithCLLocation:location]; // Let the superclass initialize latitude and longitude.

    _altitude = metersAltitude;

    return self;
}

- (WWPosition*) initWithCLPosition:(CLLocation* __unsafe_unretained)location
{
    if (location == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Location is nil")
    }

    self = [super initWithCLLocation:location]; // Let the superclass initialize latitude and longitude.

    _altitude = [location altitude];

    return self;
}

- (WWPosition*) initWithCLCoordinate:(CLLocationCoordinate2D)locationCoordinate altitude:(double)metersAltitude
{
    self = [super initWithCLCoordinate:locationCoordinate]; // Let the superclass initialize latitude and longitude.

    _altitude = metersAltitude;

    return self;
}

- (WWPosition*) initWithZeroPosition
{
    self = [super initWithZeroLocation]; // Let the superclass initialize latitude and longitude.

    _altitude = 0;

    return self;
}

- (void) setDegreesLatitude:(double)latitude longitude:(double)longitude altitude:(double)metersAltitude
{
    [super setDegreesLatitude:latitude longitude:longitude];

    _altitude = metersAltitude;
}

- (void) setLocation:(WWLocation* __unsafe_unretained)location altitude:(double)metersAltitude
{
    if (location == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Location is nil")
    }

    [super setLocation:location];

    _altitude = metersAltitude;
}

- (void) setPosition:(WWPosition* __unsafe_unretained)position
{
    if (position == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Position is nil")
    }

    [super setLocation:position]; // Let the superclass set the latitude and longitude.

    _altitude = position->_altitude;
}

- (void) setCLLocation:(CLLocation* __unsafe_unretained)location altitude:(double)metersAltitude
{
    if (location == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Location is nil")
    }

    [super setCLLocation:location]; // Let the superclass set the latitude and longitude.

    _altitude = metersAltitude;
}

- (void) setCLPosition:(CLLocation* __unsafe_unretained)location
{
    if (location == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Location is nil")
    }

    [super setCLLocation:location]; // Let the superclass set the latitude and longitude.

    _altitude = [location altitude];
}

- (void) setCLCoordinate:(CLLocationCoordinate2D)locationCoordinate altitude:(double)metersAltitude
{
    [super setCLCoordinate:locationCoordinate]; // Let the superclass set the latitude and longitude.

    _altitude = metersAltitude;
}

+ (void) greatCircleInterpolate:(WWPosition* __unsafe_unretained)beginPosition
                    endPosition:(WWPosition* __unsafe_unretained)endPosition
                         amount:(double)amount
                 outputPosition:(WWPosition* __unsafe_unretained)result
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
    result->_altitude = [WWMath interpolateValue1:beginPosition->_altitude value2:endPosition->_altitude amount:amount];
}

+ (void) rhumbInterpolate:(WWPosition* __unsafe_unretained)beginPosition
              endPosition:(WWPosition* __unsafe_unretained)endPosition
                   amount:(double)amount
           outputPosition:(WWPosition* __unsafe_unretained)result
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
    result->_altitude = [WWMath interpolateValue1:beginPosition->_altitude value2:endPosition->_altitude amount:amount];
}

+ (void) linearInterpolate:(WWPosition* __unsafe_unretained)beginPosition
               endPosition:(WWPosition* __unsafe_unretained)endPosition
                    amount:(double)amount
            outputPosition:(WWPosition* __unsafe_unretained)result
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
    result->_altitude = [WWMath interpolateValue1:beginPosition->_altitude value2:endPosition->_altitude amount:amount];
}

+ (void) forecastPosition:(CLLocation* __unsafe_unretained)location
                  forDate:(NSDate* __unsafe_unretained)date
                  onGlobe:(WWGlobe* __unsafe_unretained)globe
           outputPosition:(WWPosition* __unsafe_unretained)result
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