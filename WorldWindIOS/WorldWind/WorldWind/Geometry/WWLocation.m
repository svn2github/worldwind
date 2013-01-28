/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <CoreLocation/CoreLocation.h>
#import "WorldWind/Geometry/WWLocation.h"
#import "WorldWind/Geometry/WWAngle.h"
#import "WorldWind/WWLog.h"

#define LONGITUDE_FOR_TIMEZONE(tz) 180.0 * [tz secondsFromGMT] / 43200.0

@implementation WWLocation

- (WWLocation*) initWithDegreesLatitude:(double)latitude longitude:(double)longitude
{
    self = [super init];
    
    _latitude = latitude;
    _longitude = longitude;
    
    return self;
}

- (WWLocation*) initWithDegreesLatitude:(double) latitude timeZoneForLongitude:(NSTimeZone*)timeZone
{
    if (timeZone == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Time zone is nil")
    }

    self = [super init];

    _latitude = latitude;
    _longitude = LONGITUDE_FOR_TIMEZONE(timeZone);

    return self;
}

- (WWLocation*) initWithLocation:(WWLocation*)location
{
    self = [super init];

    if (location == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Location is nil")
    }

    _latitude = location->_latitude;
    _longitude = location->_longitude;

    return self;
}

- (WWLocation*) initWithCLLocation:(CLLocation*)location
{
    self = [super init];

    if (location == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Location is nil")
    }

    CLLocationCoordinate2D coord = [location coordinate];
    _latitude = coord.latitude;
    _longitude = coord.longitude;

    return self;
}

- (id) copyWithZone:(NSZone *)zone
{
    return [[[self class] alloc] initWithDegreesLatitude:_latitude longitude:_longitude];
}

- (WWLocation*) setDegreesLatitude:(double)latitude longitude:(double)longitude
{
    _latitude = latitude;
    _longitude = longitude;

    return self;
}

- (WWLocation*) setDegreesLatitude:(double)latitude timeZoneForLongitude:(NSTimeZone*)timeZone
{
    if (timeZone == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Time zone is nil")
    }

    _latitude = latitude;
    _longitude = LONGITUDE_FOR_TIMEZONE(timeZone);

    return self;
}

- (WWLocation*) setLocation:(WWLocation*)location
{
    if (location == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Location is nil")
    }

    _latitude = location->_latitude;
    _longitude = location->_longitude;

    return self;
}

- (WWLocation*) setCLLocation:(CLLocation*)location
{
    if (location == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Location is nil")
    }

    CLLocationCoordinate2D coord = [location coordinate];
    _latitude = coord.latitude;
    _longitude = coord.longitude;

    return self;
}

- (WWLocation*) setGreatCircleEndLocation:(WWLocation*)startLocation azimuth:(double)azimuth distance:(double) distance
{
    if (startLocation == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Location is nil")
    }

    // Taken from "Map Projections - A Working Manual", page 31, equation 5-5 and 5-6.

    _latitude = startLocation->_latitude;
    _longitude = startLocation->_longitude;

    if (distance != 0)
    {
        double lat1 = RADIANS(_latitude);
        double lon1 = RADIANS(_longitude);
        double a = RADIANS(azimuth);
        double d = RADIANS(distance);

        double lat2 = asin(sin(lat1) * cos(d) + cos(lat1) * sin(d) * cos(a));
        double lon2 = lon1 + atan2(sin(d) * sin(a), cos(lat1) * cos(d) - sin(lat1) * sin(d) * cos(a));

        if (!isnan(lat2) && !isnan(lon2))
        {
            _latitude = NormalizedDegreesLatitude(DEGREES(lat2));
            _longitude = NormalizedDegreesLongitude(DEGREES(lon2));
        }
    }

    return self;
}

- (WWLocation*) setRhumbEndLocation:(WWLocation*)startLocation azimuth:(double)azimuth distance:(double)distance
{
    if (startLocation == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Location is nil")
    }

    // Taken from http://www.movable-type.co.uk/scripts/latlong.html

    _latitude = startLocation->_latitude;
    _longitude = startLocation->_longitude;

    if (distance != 0)
    {
        double lat1 = RADIANS(_latitude);
        double lon1 = RADIANS(_longitude);
        double a = RADIANS(azimuth);
        double d = RADIANS(distance);

        double lat2 = lat1 + d * cos(a);
        double dPhi = log(tan(lat2 / 2 + M_PI_4) / tan(lat1 / 2 + M_PI_4));
        double q = (lat2 - lat1) / dPhi;

        if (isnan(dPhi) || isnan(q) || isinf(q))
        {
            q = cos(lat1);
        }

        double dLon = d * sin(a) / q;

        // Handle latitude passing over either pole.
        if (fabs(lat2) > M_PI_2)
        {
            lat2 = lat2 > 0 ? M_PI - lat2 : -M_PI - lat2;
        }

        double lon2 = fmod(lon1 + dLon + M_PI, 2 * M_PI) - M_PI;

        if (!isnan(lat2) && !isnan(lon2))
        {
            _latitude = NormalizedDegreesLatitude(DEGREES(lat2));
            _longitude = NormalizedDegreesLongitude(DEGREES(lon2));
        }
    }

    return self;
}

-(WWLocation*) addLocation:(WWLocation *)location
{
    if (location == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Location is nil")
    }

    _latitude += location.latitude;
    _longitude += location.longitude;
    
    return self;
}

-(WWLocation*) subtractLocation:(WWLocation *)location
{
    if (location == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Location is nil")
    }
    
    _latitude -= location.latitude;
    _longitude -= location.longitude;
    
    return self;
}

@end
