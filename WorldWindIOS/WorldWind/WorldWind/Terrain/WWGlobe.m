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

@implementation WWGlobe

- (WWGlobe*) init
{
    self = [super init];

    _equatorialRadius = 1;
    _polarRadius = 1;
    _es = 0.00669437999013;
    _tessellator = [[WWTessellator alloc] initWithGlobe:self];

    return self;
}

- (WWTerrainTileList*) tessellate:(WWDrawContext*)dc
{
    if (dc == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Draw context is nil")
    }

    return [_tessellator tessellate:dc];
}

- (void) computePointFromPosition:(double)latitude longitude:(double)longitude altitude:(double)altitude
                              outputPoint:(WWVec4*)result
{
    double cosLat = cos(RADIANS(latitude));
    double sinLat = sin(RADIANS(latitude));
    double cosLon = cos(RADIANS(longitude));
    double sinLon = sin(RADIANS(longitude));

    double rpm = _equatorialRadius / sqrt(1.0 - _es * sinLat * sinLat);

    result.x = (rpm + altitude) * cosLat * sinLon;
    result.y = (rpm * (1.0 - _es) + altitude) * sinLat;
    result.z = (rpm + altitude) * cosLat * cosLon;
}

- (void) computePointFromPosition:(double)latitude longitude:(double)longitude altitude:(double)altitude
                      outputArray:(float*)result
{
    double cosLat = cos(RADIANS(latitude));
    double sinLat = sin(RADIANS(latitude));
    double cosLon = cos(RADIANS(longitude));
    double sinLon = sin(RADIANS(longitude));

    double rpm = _equatorialRadius / sqrt(1.0 - _es * sinLat * sinLat);

    result[0] = (float) ((rpm + altitude) * cosLat * sinLon);
    result[1] = (float) ((rpm * (1.0 - _es) + altitude) * sinLat);
    result[2] = (float) ((rpm + altitude) * cosLat * cosLon);
}

@end
