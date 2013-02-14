/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Terrain/WWBasicTerrain.h"
#import "WorldWind/Render/WWDrawContext.h"
#import "WorldWind/Terrain/WWGlobe.h"
#import "WorldWind/Geometry/WWVec4.h"
#import "WorldWind/Terrain/WWTerrainTileList.h"
#import "WorldWind/WorldWindConstants.h"
#import "WorldWind/WWLog.h"

@implementation WWBasicTerrain

- (WWBasicTerrain*) initWithDrawContext:(WWDrawContext*)dc
{
    if (dc == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Draw context is nil.")
    }

    self = [super init];

    _dc = dc;

    return self;
}

- (WWGlobe*) globe
{
    return [_dc globe];
}

- (double) verticalExaggeration
{
    return [_dc verticalExaggeration];
}

- (void) surfacePointAtLatitude:(double)latitude
                      longitude:(double)longitude
                         offset:(double)offset
                         result:(WWVec4*)result
{
    if (result == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Result pointer is nil.")
    }

    WWTerrainTileList* surfaceGeometry = [_dc surfaceGeometry];

    if (surfaceGeometry != nil && [surfaceGeometry surfacePoint:latitude longitude:longitude offset:offset result:result])
    {
        // The surface geometry already has vertical exaggeration applied. This has the effect of interpreting
        // offset as height above the terrain after applying vertical exaggeration.
        WWVec4* normal = [[WWVec4 alloc] initWithZeroVector];
        [[_dc globe] computeNormal:latitude longitude:longitude outputPoint:normal];
        [normal multiplyByScalar3:offset];
        [result add3:normal];
    }
    else
    {
        double height = offset + [[_dc globe] elevationForLatitude:latitude longitude:longitude]
                * [_dc verticalExaggeration];
        [[_dc globe] computePointFromPosition:latitude longitude:longitude altitude:height outputPoint:result];
    }
}

- (void) surfacePointAtLatitude:(double)latitude
                      longitude:(double)longitude
                         offset:(double)offset
                   altitudeMode:(NSString*)altitudeMode
                         result:(WWVec4*)result
{
    if (result == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Result pointer is nil.")
    }

    if ([WW_ALTITUDE_MODE_CLAMP_TO_GROUND isEqualToString:altitudeMode])
    {
        [self surfacePointAtLatitude:latitude longitude:longitude offset:0 result:result];
    }
    else if ([WW_ALTITUDE_MODE_RELATIVE_TO_GROUND isEqualToString:altitudeMode])
    {
        [self surfacePointAtLatitude:latitude longitude:longitude offset:offset result:result];
    }
    else // ABSOLUTE
    {
        double height = offset * [_dc verticalExaggeration];
        [[_dc globe] computePointFromPosition:latitude longitude:longitude altitude:height outputPoint:result];
    }
}

@end