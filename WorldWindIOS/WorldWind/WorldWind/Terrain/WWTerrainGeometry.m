/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "WWTerrainGeometry.h"
#import "WorldWind/Geometry/WWVec4.h"
#import "WorldWind/WWLog.h"
#import "WWMatrix.h"

@implementation WWTerrainGeometry

- init
{
    self = [super init];

    _referenceCenter = [[WWVec4 alloc] initWithZeroVector];
    _vboCacheKey = [[NSObject alloc] init];
    _mustRegenerateVbos = YES;
    _points = 0;

    return self;
}

- (void) dealloc
{
    if (_points)
    {
        free(_points);
    }
}

@end