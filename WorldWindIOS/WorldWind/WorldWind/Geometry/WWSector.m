/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Geometry/WWSector.h"
#import "WorldWind/WWLog.h"
#import "WorldWind/Geometry/WWLocation.h"
#import "WorldWind/Geometry/WWAngle.h"

@implementation WWSector

- (WWSector*) initWithDegreesMinLatitude:(double)minLatitude
                             maxLatitude:(double)maxLatitude
                            minLongitude:(double)minLongitude
                            maxLongitude:(double)maxLongitude
{
    self = [super init];
    
    _minLatitude = minLatitude;
    _maxLatitude = maxLatitude;
    _minLongitude = minLongitude;
    _maxLongitude = maxLongitude;
    
    return self;
}

- (WWSector*) initWithFullSphere
{
    self = [super init];

    _minLatitude = -90;
    _maxLatitude = 90;
    _minLongitude = -180;
    _maxLongitude = 180;

    return self;
}

- (id) copyWithZone:(NSZone *)zone
{
    return [[[self class] alloc] initWithDegreesMinLatitude:_minLatitude maxLatitude:_maxLatitude minLongitude:_minLongitude maxLongitude:_maxLongitude];
}

- (void) centroidLocation:(WWLocation*)result
{
    if (result == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Result is nil")
    }

    result.latitude = 0.5 * (_minLatitude + _maxLatitude);
    result.longitude = 0.5 * (_minLongitude + _maxLongitude);
}

- (double) deltaLat
{
    return _maxLatitude - _minLatitude;
}

- (double) deltaLon
{
    return _maxLongitude - _minLongitude;
}

- (double) minLatitudeRadians
{
    return RADIANS(_minLatitude);
}

- (double) maxLatitudeRadians
{
    return RADIANS(_maxLatitude);
}

- (double) minLongitudeRadians
{
    return RADIANS(_minLongitude);
}

- (double) maxLongitudeRadians
{
    return RADIANS(_maxLongitude);
}

- (BOOL) intersects:(WWSector*)other
{
    if (other == nil)
        return NO;

    // Assumes normalized angles: [-180, 180], [-90, 90].
    if ([other maxLongitude] < _minLongitude)
        return NO;
    if ([other minLongitude] > _maxLongitude)
        return NO;
    if ([other maxLatitude] < _minLatitude)
        return NO;
    if ([other minLatitude] > _maxLatitude)
        return NO;

    return YES;
}

@end
