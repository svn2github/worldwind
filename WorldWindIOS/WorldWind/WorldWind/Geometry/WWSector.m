/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Geometry/WWSector.h"
#import "WorldWind/Geometry/WWLocation.h"
#import "WorldWind/Util/WWMath.h"
#import "WorldWind/WWLog.h"

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

- (WWSector*) initWithSector:(WWSector* __unsafe_unretained)sector
{
    if (sector == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Sector is nil")
    }

    self = [super init];

    _minLatitude = sector->_minLatitude;
    _maxLatitude = sector->_maxLatitude;
    _minLongitude = sector->_minLongitude;
    _maxLongitude = sector->_maxLongitude;

    return self;
}

- (WWSector*) initWithLocations:(NSArray* __unsafe_unretained)locations
{
    if (locations == nil || [locations count] == 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Locations is nil or empty")
    }

    self = [super init];

    _minLatitude = DBL_MAX;
    _maxLatitude = -DBL_MAX;
    _minLongitude = DBL_MAX;
    _maxLongitude = -DBL_MAX;

    for (WWLocation* __unsafe_unretained location in locations) // no need to check for nil; NSArray does not permit nil elements
    {
        double lat = [location latitude];
        if (_minLatitude > lat)
        {
            _minLatitude = lat;
        }
        if (_maxLatitude < lat)
        {
            _maxLatitude = lat;
        }

        double lon = [location longitude];
        if (_minLongitude > lon)
        {
            _minLongitude = lon;
        }
        if (_maxLongitude < lon)
        {
            _maxLongitude = lon;
        }
    }

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

- (id) copyWithZone:(NSZone*)zone
{
    return [[[self class] alloc] initWithDegreesMinLatitude:_minLatitude maxLatitude:_maxLatitude minLongitude:_minLongitude maxLongitude:_maxLongitude];
}

- (double) deltaLat
{
    return _maxLatitude - _minLatitude;
}

- (double) deltaLon
{
    return _maxLongitude - _minLongitude;
}

- (double) centroidLat
{
    return 0.5 * (_minLatitude + _maxLatitude);
}

- (double) centroidLon
{
    return 0.5 * (_minLongitude + _maxLongitude);
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

- (void) set:(WWSector* __unsafe_unretained)sector
{
    if (sector == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Sector is nil")
    }

    _minLatitude = sector->_minLatitude;
    _maxLatitude = sector->_maxLatitude;
    _minLongitude = sector->_minLongitude;
    _maxLongitude = sector->_maxLongitude;
}

- (BOOL) isEmpty
{
    return _minLatitude == _maxLatitude && _minLongitude == _maxLongitude;
}

- (BOOL) intersects:(WWSector* __unsafe_unretained)sector
{
    if (sector == nil)
        return NO;

    // Assumes normalized angles: [-180, 180], [-90, 90].
    return _minLongitude <= sector->_maxLongitude
        && _maxLongitude >= sector->_minLongitude
        && _minLatitude <= sector->_maxLatitude
        && _maxLatitude >= sector->_minLatitude;
}

- (BOOL) contains:(WWSector* __unsafe_unretained)sector
{
    if (sector == nil)
        return NO;

    // Assumes normalized angles: [-180, 180], [-90, 90].
    return _minLatitude <= sector->_minLatitude
        && _maxLatitude >= sector->_maxLatitude
        && _minLongitude <= sector->_minLongitude
        && _maxLongitude >= sector->_maxLongitude;
}

- (BOOL) contains:(double)latitude longitude:(double)longitude
{
    // Assumes normalized angles: [-180, 180], [-90, 90].
    return _minLatitude <= latitude
        && _maxLatitude >= latitude
        && _minLongitude <= longitude
        && _maxLongitude >= longitude;
}

- (void) intersection:(WWSector* __unsafe_unretained)sector
{
    if (sector == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Sector is nil")
    }

    // Assumes normalized angles: [-180, 180], [-90, 90].
    if (_minLatitude < sector->_minLatitude)
        _minLatitude = sector->_minLatitude;
    if (_maxLatitude > sector->_maxLatitude)
        _maxLatitude = sector->_maxLatitude;
    if (_minLongitude < sector->_minLongitude)
        _minLongitude = sector->_minLongitude;
    if (_maxLongitude > sector->_maxLongitude)
        _maxLongitude = sector->_maxLongitude;

    // If the sectors do not overlap in either latitude or longitude, then the result of the above logic results in
    // the max begin greater than the min. In this case, set the max to the to indicate that the sector is empty in
    // that dimension.
    if (_maxLatitude < _minLatitude)
        _maxLatitude = _minLatitude;
    if (_maxLongitude < _minLongitude)
        _maxLongitude = _minLongitude;
}

- (void) union:(WWSector* __unsafe_unretained)sector
{
    if (sector == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Sector is nil")
    }

    // Assumes normalized angles: [-180, 180], [-90, 90].
    if (_minLatitude > sector->_minLatitude)
        _minLatitude = sector->_minLatitude;
    if (_maxLatitude < sector->_maxLatitude)
        _maxLatitude = sector->_maxLatitude;
    if (_minLongitude > sector->_minLongitude)
        _minLongitude = sector->_minLongitude;
    if (_maxLongitude < sector->_maxLongitude)
        _maxLongitude = sector->_maxLongitude;
}

@end