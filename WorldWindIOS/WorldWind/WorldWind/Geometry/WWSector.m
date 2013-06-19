/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Geometry/WWSector.h"
#import "WorldWind/WWLog.h"
#import "WorldWind/Geometry/WWLocation.h"
#import "WorldWind/Terrain/WWGlobe.h"
#import "WorldWind/Geometry/WWVec4.h"
#import "WorldWind/Geometry/WWBoundingBox.h"
#import "WorldWind/Util/WWMath.h"

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

- (void) centroidLocation:(WWLocation* __unsafe_unretained)result
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

- (BOOL) contains:(double)latitude longitude:(double)longitude
{
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

- (void) computeReferencePoints:(WWGlobe* __unsafe_unretained)globe elevation:(double)elevation result:(NSMutableArray* __unsafe_unretained)result
{
    if (globe == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Globe is nil")
    }

    if (result == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Output array is nil")
    }

    double centerLat = 0.5 * (_minLatitude + _maxLatitude);
    double centerLon = 0.5 * (_minLongitude + _maxLongitude);

    WWVec4* swPoint = [result objectAtIndex:0];
    WWVec4* sePoint = [result objectAtIndex:1];
    WWVec4* nePoint = [result objectAtIndex:2];
    WWVec4* nwPoint = [result objectAtIndex:3];
    WWVec4* centerPoint = [result objectAtIndex:4];

    [globe computePointFromPosition:_minLatitude longitude:_minLongitude altitude:elevation outputPoint:swPoint];
    [globe computePointFromPosition:_minLatitude longitude:_maxLongitude altitude:elevation outputPoint:sePoint];
    [globe computePointFromPosition:_maxLatitude longitude:_maxLongitude altitude:elevation outputPoint:nePoint];
    [globe computePointFromPosition:_maxLatitude longitude:_minLongitude altitude:elevation outputPoint:nwPoint];
    [globe computePointFromPosition:centerLat longitude:centerLon altitude:elevation outputPoint:centerPoint];
}

- (void) computeExtremePoints:(WWGlobe* __unsafe_unretained)globe
                 minElevation:(double)minElevation
                 maxElevation:(double)maxElevation
                       result:(NSMutableArray* __unsafe_unretained)result
{
    if (globe == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Globe is nil")
    }

    if (result == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Output array is nil")
    }

    [result removeAllObjects];

    WWVec4* pt = [[WWVec4 alloc] initWithZeroVector];
    [result addObject:pt];
    [globe computePointFromPosition:_minLatitude longitude:_minLongitude altitude:minElevation outputPoint:pt];

    pt = [[WWVec4 alloc] initWithZeroVector];
    [result addObject:pt];
    [globe computePointFromPosition:_minLatitude longitude:_minLongitude altitude:maxElevation outputPoint:pt];

    pt = [[WWVec4 alloc] initWithZeroVector];
    [result addObject:pt];
    [globe computePointFromPosition:_minLatitude longitude:_maxLongitude altitude:minElevation outputPoint:pt];

    pt = [[WWVec4 alloc] initWithZeroVector];
    [result addObject:pt];
    [globe computePointFromPosition:_minLatitude longitude:_maxLongitude altitude:maxElevation outputPoint:pt];

    pt = [[WWVec4 alloc] initWithZeroVector];
    [result addObject:pt];
    [globe computePointFromPosition:_maxLatitude longitude:_maxLongitude altitude:minElevation outputPoint:pt];

    pt = [[WWVec4 alloc] initWithZeroVector];
    [result addObject:pt];
    [globe computePointFromPosition:_maxLatitude longitude:_maxLongitude altitude:maxElevation outputPoint:pt];

    pt = [[WWVec4 alloc] initWithZeroVector];
    [result addObject:pt];
    [globe computePointFromPosition:_maxLatitude longitude:_minLongitude altitude:minElevation outputPoint:pt];

    pt = [[WWVec4 alloc] initWithZeroVector];
    [result addObject:pt];
    [globe computePointFromPosition:_maxLatitude longitude:_minLongitude altitude:maxElevation outputPoint:pt];

    // A point at the centroid captures the maximum vertical dimension.
    double cLat = 0.5 * (_minLatitude + _maxLatitude);
    double cLon = 0.5 * (_minLongitude + _maxLongitude);
    pt = [[WWVec4 alloc] initWithZeroVector];
    [result addObject:pt];
    [globe computePointFromPosition:cLat longitude:cLon altitude:maxElevation outputPoint:pt];

    // If the sector spans the equator then the curvature of all four edges needs to be considered. The extreme points
    // along the top and bottom edges are located at their mid-points and the extreme points along the left and right
    // edges are on the equator. Add points with the longitude of the sector's centroid but with the sector's min and
    // max latitude, and add points with the sector's min and max longitude but with latitude at the equator. See
    // WWJINT-225.
    if (_minLatitude < 0 && _maxLatitude > 0)
    {
        pt = [[WWVec4 alloc] initWithZeroVector];
        [result addObject:pt];
        [globe computePointFromPosition:_minLatitude longitude:cLon altitude:maxElevation outputPoint:pt];

        pt = [[WWVec4 alloc] initWithZeroVector];
        [result addObject:pt];
        [globe computePointFromPosition:_maxLatitude longitude:cLon altitude:maxElevation outputPoint:pt];

        pt = [[WWVec4 alloc] initWithZeroVector];
        [result addObject:pt];
        [globe computePointFromPosition:0 longitude:_minLongitude altitude:maxElevation outputPoint:pt];

        pt = [[WWVec4 alloc] initWithZeroVector];
        [result addObject:pt];
        [globe computePointFromPosition:0 longitude:_maxLongitude altitude:maxElevation outputPoint:pt];
    }
            // If the sector is located entirely in the southern hemisphere, then the curvature of its top edge needs to be
            // considered. The extreme point along the top edge is located at its mid-point. Add a point with the longitude
            // of the sector's centroid but with the sector's max latitude. See WWJINT-225.
    else if (_minLatitude < 0)
    {
        pt = [[WWVec4 alloc] initWithZeroVector];
        [result addObject:pt];
        [globe computePointFromPosition:_maxLatitude longitude:cLon altitude:maxElevation outputPoint:pt];
    }
            // If the sector is located entirely within the northern hemisphere then the curvature of its bottom edge needs to
            // be considered. The extreme point along the bottom edge is located at its mid-point. Add a point with the
            // longitude of the sector's centroid but with the sector's min latitude. See WWJINT-225.
    else
    {
        pt = [[WWVec4 alloc] initWithZeroVector];
        [result addObject:pt];
        [globe computePointFromPosition:_minLatitude longitude:cLon altitude:maxElevation outputPoint:pt];
    }

    if (_maxLongitude - _minLongitude > 180)
    {
        // Need to compute more points to ensure the box encompasses the full sector.

        // Centroid latitude, longitude midway between min longitude and centroid longitude.
        double lon = 0.5 * (_minLongitude + cLon);
        pt = [[WWVec4 alloc] initWithZeroVector];
        [result addObject:pt];
        [globe computePointFromPosition:cLat longitude:lon altitude:maxElevation outputPoint:pt];

        // Centroid latitude, longitude midway between centroid longitude and max longitude.
        lon = 0.5 * (_maxLongitude + cLon);
        pt = [[WWVec4 alloc] initWithZeroVector];
        [result addObject:pt];
        [globe computePointFromPosition:cLat longitude:lon altitude:maxElevation outputPoint:pt];

        // centroid latitude, longitude at min longitude and max longitude.
        pt = [[WWVec4 alloc] initWithZeroVector];
        [result addObject:pt];
        [globe computePointFromPosition:cLat longitude:_minLongitude altitude:maxElevation outputPoint:pt];

        pt = [[WWVec4 alloc] initWithZeroVector];
        [result addObject:pt];
        [globe computePointFromPosition:cLat longitude:_maxLongitude altitude:maxElevation outputPoint:pt];
    }
}

- (WWBoundingBox*) computeBoundingBox:(WWGlobe* __unsafe_unretained)globe
                         minElevation:(double)minElevation
                         maxElevation:(double)maxElevation
{
    NSMutableArray* extremePoints = [[NSMutableArray alloc] init];
    [self computeExtremePoints:globe minElevation:minElevation maxElevation:maxElevation result:extremePoints];

    return [[WWBoundingBox alloc] initWithPoints:extremePoints];
}

@end
