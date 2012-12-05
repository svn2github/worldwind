/*
Copyright (C) 2013 United States Government as represented by the Administrator of the
National Aeronautics and Space Administration.
All Rights Reserved.
*/



#import "WWTerrainSharedGeometry.h"


@implementation WWTerrainSharedGeometry

- (WWTerrainSharedGeometry*) init
{
    self = [super init];

    _vboCacheKey = [[NSObject alloc] init];
    _texCoords = 0;
    _indices = 0;
    _wireframeIndices = 0;
    _outlineIndices = 0;

    return self;
}

- (void) dealloc
{
    if (_texCoords)
    {
        free(_texCoords);
    }

    if (_indices)
    {
        free(_indices);
    }

    if (_wireframeIndices)
    {
        free(_wireframeIndices);
    }

    if (_outlineIndices)
    {
        free(_outlineIndices);
    }
}

@end