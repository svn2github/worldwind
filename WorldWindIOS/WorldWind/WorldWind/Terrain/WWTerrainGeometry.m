/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "WWTerrainGeometry.h"
#import "WorldWind/Geometry/WWVec4.h"
#import "WWMatrix.h"

@implementation WWTerrainGeometry

- init
{
    self = [super init];

    if (self != nil)
    {
        _referenceCenter = [[WWVec4 alloc] initWithZeroVector];
        _transformationMatrix = [[WWMatrix alloc] initWithIdentity];
        _points = 0;
    }

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