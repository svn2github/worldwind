/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Terrain/WWGlobe.h"
#import "WorldWind/Terrain/WWTessellator.h"
#import "WorldWind/WWLog.h"
#import "WorldWind/Geometry/WWVec4.h"
#import "WorldWind/Geometry/WWAngle.h"
#import "WorldWind/Geometry/WWSector.h"

@implementation WWGlobe

- (WWGlobe*) init
{
    self = [super init];

    _equatorialRadius = 6378137.0;
    _polarRadius = 6356752.3;
    _es = 0.00669437999013;
    _minElevation = 0;
    _tessellator = [[WWTessellator alloc] initWithGlobe:self];

    return self;
}

- (WWTerrainTileList*) tessellate:(WWDrawContext*)dc
{
    if (dc == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Draw context is nil")
    }

    if (_tessellator == nil)
    {
        WWLOG_AND_THROW(NSInternalInconsistencyException, @"Tessellator is nil")
    }

    return [_tessellator tessellate:dc];
}

- (void) computePointFromPosition:(double)latitude
                        longitude:(double)longitude
                         altitude:(double)altitude
                      outputPoint:(WWVec4*)result
{
    if (result == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Result pointer is nil")
    }

    double cosLat = cos(RADIANS(latitude));
    double sinLat = sin(RADIANS(latitude));
    double cosLon = cos(RADIANS(longitude));
    double sinLon = sin(RADIANS(longitude));

    double rpm = _equatorialRadius / sqrt(1.0 - _es * sinLat * sinLat);

    result.x = (rpm + altitude) * cosLat * sinLon;
    result.y = (rpm * (1.0 - _es) + altitude) * sinLat;
    result.z = (rpm + altitude) * cosLat * cosLon;
}

- (void) computePointFromPosition:(double)latitude
                        longitude:(double)longitude
                         altitude:(double)altitude
                           offset:(WWVec4*)offset // nil value is acceptable
                      outputArray:(float [])result
{
    if (result == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Result pointer is nil")
    }

    double cosLat = cos(RADIANS(latitude));
    double sinLat = sin(RADIANS(latitude));
    double cosLon = cos(RADIANS(longitude));
    double sinLon = sin(RADIANS(longitude));

    double rpm = _equatorialRadius / sqrt(1.0 - _es * sinLat * sinLat);

    result[0] = (float) ((rpm + altitude) * cosLat * sinLon - (offset != nil ? offset.x : 0));
    result[1] = (float) ((rpm * (1.0 - _es) + altitude) * sinLat - (offset != nil ? offset.y : 0));
    result[2] = (float) ((rpm + altitude) * cosLat * cosLon - (offset != nil ? offset.z : 0));
}

- (void) computePointsFromPositions:(WWSector*)sector
                             numLat:(int)numLat
                             numLon:(int)numLon
                    metersElevation:(double [])metersElevation
                  constantElevation:(double*)constantElevation
                             offset:(WWVec4*)offset // nil value is acceptable
                        outputArray:(float [])outputArray
{
    if (sector == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Sector is nil")
    }

    if (outputArray == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Output array is nil")
    }

    if (metersElevation == nil && constantElevation == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Elevations array and constant elevation cannot both be nil")
    }

    if (numLat <=0 || numLon <= 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"A dimension is <= 0")
    }

    double minLat = RADIANS(sector.minLatitude);
    double maxLat = RADIANS(sector.maxLatitude);
    double minLon = RADIANS(sector.minLongitude);
    double maxLon = RADIANS(sector.maxLongitude);

    double deltaLat = (maxLat - minLat) / (numLat > 1 ? numLat - 1 : 1);
    double deltaLon = (maxLon - minLon) / (numLon > 1 ? numLon - 1 : 1);

    double lat = minLat;
    double lon = minLon;

    double offsetX = offset != nil ? offset.x : 0;
    double offsetY = offset != nil ? offset.y : 0;
    double offsetZ = offset != nil ? offset.z : 0;

    int index = 0;

    for (int j = 0; j < numLat; j++)
    {
        // Explicitly set the first and last row to minLat and maxLat, respectively, rather than using the
        // accumulated lat value, in order to ensure that the Cartesian points of adjacent sectors match perfectly.
        if (j == 0)
            lat = minLat;
        else if (j == numLat - 1)
            lat = maxLat;
        else
            lat += deltaLat;

        // Latitude is constant for each row, therefore values depending on only latitude can be computed once per row.
        double cosLat = cos(lat);
        double sinLat = sin(lat);
        double rpm = _equatorialRadius / sqrt(1.0 - _es * sinLat * sinLat);

        for (int i = 0; i < numLon; i++)
        {
            // Explicitly set the first and last row to minLon and maxLon, respectively, rather than using the
            // accumulated lon value, in order to ensure that the Cartesian points of adjacent sectors match perfectly.
            if (i == 0)
                lon = minLon;
            else if (i == numLon - 1)
                lon = maxLon;
            else
                lon += deltaLon;

            double cosLon = cos(lon);
            double sinLon = sin(lon);

            double elevation = metersElevation != nil ? metersElevation[index] : *constantElevation;

            outputArray[index * 3] = (float) ((rpm + elevation) * cosLat * sinLon - offsetX);
            outputArray[index * 3 + 1] = (float) ((rpm * (1.0 - _es) + elevation) * sinLat - offsetY);
            outputArray[index * 3 + 2] = (float) ((rpm + elevation) * cosLat * cosLon - offsetZ);

            ++index;
        }
    }
}

- (void) computeNormal:(double)latitude
             longitude:(double)longitude
           outputPoint:(WWVec4*)result
{
    if (result == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Result pointer is nil")
    }

    double cosLat = cos(RADIANS(latitude));
    double cosLon = cos(RADIANS(longitude));
    double sinLat = sin(RADIANS(latitude));
    double sinLon = sin(RADIANS(longitude));

    double eqSquared = _equatorialRadius * _equatorialRadius;
    double polSquared = _polarRadius * _polarRadius;

    result.x = cosLat * sinLon / eqSquared;
    result.y = (1 - _es) * sinLat / polSquared;
    result.z = cosLat * cosLon / eqSquared;
    [result normalize3];
}

- (void) computeNorthTangent:(double)latitude
                   longitude:(double)longitude
                 outputPoint:(WWVec4*)result
{
    if (result == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Result pointer is nil")
    }

    // The north-pointing tangent is derived by rotating the vector (0, 1, 0) about the Y-axis by longitude degrees,
    // then rotating it about the X-axis by -latitude degrees. The latitude angle must be inverted because latitude
    // is a clockwise rotation about the X-axis, and standard rotation matrices assume counter-clockwise rotation.
    // The combined rotation can be represented by a combining two rotation matrices Rlat, and Rlon, then
    // transforming the vector (0, 1, 0) by the combined transform:
    //
    // NorthTangent = (Rlon * Rlat) * (0, 1, 0)
    //
    // This computation can be simplified and encoded inline by making two observations:
    // - The vector's X and Z coordinates are always 0, and its Y coordinate is always 1.
    // - Inverting the latitude rotation angle is equivalent to inverting sinLat. We know this by the trigonimetric
    //   identities cos(-x) = cos(x), and sin(-x) = -sin(x).

    double cosLat = cos(RADIANS(latitude));
    double cosLon = cos(RADIANS(longitude));
    double sinLat = sin(RADIANS(latitude));
    double sinLon = sin(RADIANS(longitude));

    result.x = -sinLat * sinLon;
    result.y = cosLat;
    result.z = -sinLat * cosLon;
    [result normalize3];
}

- (double) getElevation:(double)latitude longitude:(double)longitude
{
    return 0;
}

- (void) getElevations:(WWSector*)sector
                numLat:(int)numLat
                numLon:(int)numLon
      targetResolution:(double)targetResolution
  verticalExaggeration:(double)verticalExaggeration
           outputArray:(double [])outputArray
{
    if (sector == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Sector is nil")
    }

    if (outputArray == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Output array is nil")
    }

    if (numLat <=0 || numLon <= 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"A dimension is <= 0")
    }

    for (int j = 0; j < numLat; j++)
    {
        for (int i = 0; i < numLon; i++)
        {
            int index = j * numLon + i;
            outputArray[index] = 0;
        }
    }
}

@end
