/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "WorldWind/Terrain/WWZeroElevationModel.h"
#import "WorldWind/Geometry/WWSector.h"
#import "WorldWind/WWLog.h"

@implementation WWZeroElevationModel

- (id) init
{
    self = [super init];

    if (self != nil)
    {
        _timestamp = [NSDate date]; // Zero elevation model never changes. Set the timestamp once in the initializer.
    }

    return self;
}

- (void) dispose
{
    // Intentionally left blank. Zero elevation model has nothing to dispose.
}

- (double) elevationForLatitude:(double)latitude longitude:(double)longitude;
{
    return 0;
}

- (double) elevationsForSector:(WWSector*)sector
                        numLat:(int)numLat
                        numLon:(int)numLon
              targetResolution:(double)targetResolution
          verticalExaggeration:(double)verticalExaggeration
                        result:(double[])result
{
    if (sector == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Sector is nil")
    }

    if (result == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Output array is nil")
    }

    if (numLat <=0 || numLon <= 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"A dimension is <= 0")
    }

    memset(result, 0, (size_t) (numLat * numLon * sizeof(double)));

    return 1;
}

- (void) minAndMaxElevationsForSector:(WWSector*)sector result:(double[])result
{
    if (sector == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Sector is nil")
    }

    if (result == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Output array is nil")
    }

    result[0] = 0;
    result[1] = 0;
}

@end