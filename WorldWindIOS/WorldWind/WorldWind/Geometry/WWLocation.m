/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <CoreLocation/CoreLocation.h>
#import "WorldWind/Geometry/WWLocation.h"
#import "WorldWind/Geometry/WWAngle.h"
#import "WorldWind/Terrain/WWGlobe.h"
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

- (WWLocation*) initWithCLCoordinate:(CLLocationCoordinate2D)locationCoordinate
{
    self = [super init];

    _latitude = locationCoordinate.latitude;
    _longitude = locationCoordinate.longitude;

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

- (WWLocation*) setCLCoordinate:(CLLocationCoordinate2D)locationCoordinate
{
    _latitude = locationCoordinate.latitude;
    _longitude = locationCoordinate.longitude;

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

+ (double) greatCircleAzimuth:(WWLocation*)beginLocation endLocation:(WWLocation*)endLocation
{
    if (beginLocation == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Begin location is nil")
    }

    if (endLocation == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"End location is nil")
    }

    // Taken from "Map Projections - A Working Manual", page 30, equation 5-4b.
    // The atan2() function is used in place of the traditional atan(y/x) to simplify the case when x==0.

    double lat1 = RADIANS(beginLocation->_latitude);
    double lon1 = RADIANS(beginLocation->_longitude);
    double lat2 = RADIANS(endLocation->_latitude);
    double lon2 = RADIANS(endLocation->_longitude);

    if (lat1 == lat2 && lon1 == lon2)
    {
        return 0;
    }

    if (lon1 == lon2)
    {
        return lat1 > lat2 ? 180 : 0;
    }

    double y = cos(lat2) * sin(lon2 - lon1);
    double x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(lon2 - lon1);
    double azimuthRadians = atan2(y, x);

    return isnan(azimuthRadians) ? 0 : DEGREES(azimuthRadians);
}

+ (double) greatCircleDistance:(WWLocation*)beginLocation endLocation:(WWLocation*)endLocation
{
    if (beginLocation == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Begin location is nil")
    }

    if (endLocation == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"End location is nil")
    }

    // "Haversine formula," taken from http://en.wikipedia.org/wiki/Great-circle_distance#Formul.C3.A6

    double lat1 = RADIANS(beginLocation->_latitude);
    double lon1 = RADIANS(beginLocation->_longitude);
    double lat2 = RADIANS(endLocation->_latitude);
    double lon2 = RADIANS(endLocation->_longitude);

    if (lat1 == lat2 && lon1 == lon2)
    {
        return 0;
    }

    double a = sin((lat2 - lat1) / 2.0);
    double b = sin((lon2 - lon1) / 2.0);
    double c = a * a + cos(lat1) * cos(lat2) * b * b;
    double distanceRadians = 2.0 * asin(sqrt(c));

    return isnan(distanceRadians) ? 0 : DEGREES(distanceRadians);
}

+ (void) greatCircleLocation:(WWLocation*)beginLocation
                     azimuth:(double)azimuth
                    distance:(double)distance
              outputLocation:(WWLocation*)result
{
    if (beginLocation == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Begin location is nil")
    }

    if (result == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Output location is nil")
    }

    // Taken from "Map Projections - A Working Manual", page 31, equation 5-5 and 5-6.

    double latitude = beginLocation->_latitude;
    double longitude = beginLocation->_longitude;

    if (distance != 0)
    {
        double lat1 = RADIANS(latitude);
        double lon1 = RADIANS(longitude);
        double a = RADIANS(azimuth);
        double d = RADIANS(distance);

        double lat2 = asin(sin(lat1) * cos(d) + cos(lat1) * sin(d) * cos(a));
        double lon2 = lon1 + atan2(sin(d) * sin(a), cos(lat1) * cos(d) - sin(lat1) * sin(d) * cos(a));

        if (!isnan(lat2) && !isnan(lon2))
        {
            latitude = NormalizedDegreesLatitude(DEGREES(lat2));
            longitude = NormalizedDegreesLongitude(DEGREES(lon2));
        }
    }

    result->_latitude = latitude;
    result->_longitude = longitude;
}

+ (void) greatCircleInterpolate:(WWLocation*)beginLocation
                    endLocation:(WWLocation*)endLocation
                         amount:(double)amount
                 outputLocation:(WWLocation*)result
{
    if (beginLocation == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Begin location is nil")
    }

    if (endLocation == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"End location is nil")
    }

    if (result == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Output location is nil")
    }

    double azimuth = [WWLocation greatCircleAzimuth:beginLocation endLocation:endLocation];
    double distance = [WWLocation greatCircleDistance:beginLocation endLocation:endLocation];
    double fractionalDistance = amount * distance;

    [WWLocation greatCircleLocation:beginLocation azimuth:azimuth distance:fractionalDistance outputLocation:result];
}

+ (double) rhumbAzimuth:(WWLocation*)beginLocation endLocation:(WWLocation*)endLocation
{
    if (beginLocation == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Begin location is nil")
    }

    if (endLocation == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"End location is nil")
    }

    // Taken from http://www.movable-type.co.uk/scripts/latlong.html

    double lat1 = RADIANS(beginLocation->_latitude);
    double lon1 = RADIANS(beginLocation->_longitude);
    double lat2 = RADIANS(endLocation->_latitude);
    double lon2 = RADIANS(endLocation->_longitude);

    if (lat1 == lat2 && lon1 == lon2)
    {
        return 0;
    }

    double dLon = lon2 - lon1;
    double dPhi = log(tan(lat2 / 2.0 + M_PI_4) / tan(lat1 / 2.0 + M_PI_4));

    // If lonChange over 180 take shorter rhumb across 180 meridian.
    if (fabs(dLon) > M_PI)
    {
        dLon = dLon > 0 ? -(2 * M_PI - dLon) : (2 * M_PI + dLon);
    }

    double azimuthRadians = atan2(dLon, dPhi);

    return isnan(azimuthRadians) ? 0 : DEGREES(azimuthRadians);
}

+ (double) rhumbDistance:(WWLocation*)beginLocation endLocation:(WWLocation*)endLocation
{
    if (beginLocation == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Begin location is nil")
    }

    if (endLocation == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"End location is nil")
    }

    // Taken from http://www.movable-type.co.uk/scripts/latlong.html

    double lat1 = RADIANS(beginLocation->_latitude);
    double lon1 = RADIANS(beginLocation->_longitude);
    double lat2 = RADIANS(endLocation->_latitude);
    double lon2 = RADIANS(endLocation->_longitude);

    if (lat1 == lat2 && lon1 == lon2)
    {
        return 0;
    }

    double dLat = lat2 - lat1;
    double dLon = lon2 - lon1;
    double dPhi = log(tan(lat2 / 2.0 + M_PI_4) / tan(lat1 / 2.0 + M_PI_4));
    double q = dLat / dPhi;

    if (isnan(dPhi) || isnan(q))
    {
        q = cos(lat1);
    }

    // If lonChange over 180 take shorter rhumb across 180 meridian.
    if (fabs(dLon) > M_PI)
    {
        dLon = dLon > 0 ? -(2 * M_PI - dLon) : (2 * M_PI + dLon);
    }

    double distanceRadians = sqrt(dLat * dLat + q * q * dLon * dLon);

    return isnan(distanceRadians) ? 0 : DEGREES(distanceRadians);
}

+ (void) rhumbLocation:(WWLocation*)beginLocation
               azimuth:(double)azimuth
              distance:(double)distance outputLocation:(WWLocation*)result;
{
    if (beginLocation == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Begin location is nil")
    }

    if (result == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Output location is nil")
    }

    // Taken from http://www.movable-type.co.uk/scripts/latlong.html

    double latitude = beginLocation->_latitude;
    double longitude = beginLocation->_longitude;

    if (distance != 0)
    {
        double lat1 = RADIANS(latitude);
        double lon1 = RADIANS(longitude);
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
            latitude = NormalizedDegreesLatitude(DEGREES(lat2));
            longitude = NormalizedDegreesLongitude(DEGREES(lon2));
        }
    }

    result->_latitude = latitude;
    result->_longitude = longitude;
}

+ (void) rhumbInterpolate:(WWLocation*)beginLocation
              endLocation:(WWLocation*)endLocation
                   amount:(double)amount
           outputLocation:(WWLocation*)result
{
    if (beginLocation == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Begin location is nil")
    }

    if (result == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Output location is nil")
    }

    double azimuth = [WWLocation rhumbAzimuth:beginLocation endLocation:endLocation];
    double distance = [WWLocation rhumbDistance:beginLocation endLocation:endLocation];
    double fractionalDistance = amount * distance;

    [WWLocation rhumbLocation:beginLocation azimuth:azimuth distance:fractionalDistance outputLocation:result];
}

+ (void) forecastLocation:(CLLocation*)location
                  forDate:(NSDate*)date
                 withGobe:(WWGlobe*)globe
           outputLocation:(WWLocation*)result
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
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Output location is nil")
    }

    double course = [location course];
    double speed = [location speed];

    if (course >= 0 && speed >= 0)
    {
        // Compute the distance in meters that the location will have travelled between the specified date and the
        // location's timestamp, assuming a constant speed. If the specified time is earlier than the location's
        // timestamp, this results in a negative distance.
        NSTimeInterval elapsedTime = [date timeIntervalSinceDate:[location timestamp]];
        double distanceMeters = speed * elapsedTime;

        // Convert the distance from meters to arc degrees. The globe's radius provides the necessary context to perform
        // this conversion.
        double radius = MAX([globe equatorialRadius], [globe polarRadius]);
        double distanceDegrees = DEGREES(distanceMeters / radius);

        // Forecast the location at the specified date using the location's course and distance travelled in arc
        // degrees. The forecast location starts at the last known location and travels along a great circle arc with
        // the location's last known course.
        [result setCLLocation:location];
        [WWLocation greatCircleLocation:result azimuth:course distance:distanceDegrees outputLocation:result];
    }
    else
    {
        // A negative course or speed indicates that either property is invalid. Either the current value is unknown or
        // these values are not available on the device. In either case, do not attempt to forecast the location.
        [result setCLLocation:location];
    }
}

@end