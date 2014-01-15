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

    [self set:sector];

    return self;
}

- (WWSector*) initWithLocations:(NSArray* __unsafe_unretained)locations
{
    if (locations == nil || [locations count] == 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Locations is nil or empty")
    }

    self = [super init];

    [self setToLocations:locations];

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

- (WWSector*) initWithWorldFile:(NSString*)worldFilePath width:(int)width height:(int)height
{
    self = [super init];

    NSError* error = nil;
    NSString* worldString = [[NSString alloc] initWithContentsOfFile:worldFilePath encoding:NSASCIIStringEncoding
                                                             error:&error];
    if (error != nil || worldString == nil)
    {
        WWLog("@Unable to open world file %@ (%@)", worldFilePath, error != nil ? [error description] : @"");
        return nil;
    }

    // Extract the parameters from the world file. This method assumes the world file is in degrees.

    NSScanner* scanner = [[NSScanner alloc] initWithString:worldString];

    double xPixelSize;
    BOOL status = [scanner scanDouble:&xPixelSize];
    if (status != YES)
        return nil;

    double yRotation;
    status = [scanner scanDouble:&yRotation];
    if (status != YES)
        return nil;

    double xRotation;
    status = [scanner scanDouble:&xRotation];
    if (status != YES)
        return nil;

    double yPixelSize;
    status = [scanner scanDouble:&yPixelSize];
    if (status != YES)
        return nil;

    double lonOrigin;
    status = [scanner scanDouble:&lonOrigin];
    if (status != YES)
        return nil;

    double latOrigin;
    status = [scanner scanDouble:&latOrigin];
    if (status != YES)
        return nil;

    // Make y offset negative if it's not already. World file convention is upper left origin.
    // The latitude and longitude dimensions are computed by multiplying the pixel size by the width or height.
    // The pixel size denotes the dimension of a pixel in degrees.
    double latOffset = latOrigin + height * (yPixelSize <= 0 ? yPixelSize : -yPixelSize);
    double lonOffset = lonOrigin + width * xPixelSize;

    double minLon;
    double maxLon;
    if (lonOrigin < lonOffset)
    {
        minLon = lonOrigin;
        maxLon = lonOffset;
    }
    else
    {
        minLon = lonOffset;
        maxLon = lonOrigin;
    }

    double minLat;
    double maxLat;
    if (latOrigin < latOffset)
    {
        minLat = latOrigin;
        maxLat = latOffset;
    }
    else
    {
        minLat = latOffset;
        maxLat = latOrigin;
    }

    _minLatitude = minLat;
    _maxLatitude = maxLat;
    _minLongitude = minLon;
    _maxLongitude = maxLon;

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

- (double) circumscribingRadius
{
    if (_minLatitude == _maxLatitude && _minLongitude == _maxLongitude)
        return 0;

    double centroidLat = [self centroidLat];
    WWLocation* left = [[WWLocation alloc] initWithDegreesLatitude:centroidLat longitude:_minLongitude];
    WWLocation* right = [[WWLocation alloc] initWithDegreesLatitude:centroidLat longitude:_maxLongitude];

    double width_2 = [WWLocation greatCircleDistance:left endLocation:right] / 2;
    double height_2 = (_maxLatitude - _minLatitude) / 2;

    return sqrt(width_2 * width_2 + height_2 * height_2);
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

- (void) setToLocations:(NSArray* __unsafe_unretained)locations
{
    if (locations == nil || [locations count] == 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Locations is nil or empty")
    }

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

- (void) unionWithLocation:(WWLocation* __unsafe_unretained)location
{
    if (location == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Location is nil")
    }

    // Assumes normalized angles: [-180, 180], [-90, 90].
    double lat = [location latitude];
    double lon = [location longitude];
    if (_minLatitude > lat)
        _minLatitude = lat;
    if (_maxLatitude < lat)
        _maxLatitude = lat;
    if (_minLongitude > lon)
        _minLongitude = lon;
    if (_maxLongitude < lon)
        _maxLongitude = lon;
}

@end