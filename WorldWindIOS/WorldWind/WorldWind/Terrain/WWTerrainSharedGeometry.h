/*
Copyright (C) 2013 United States Government as represented by the Administrator of the
National Aeronautics and Space Administration.
All Rights Reserved.
*/



#import <Foundation/Foundation.h>


@interface WWTerrainSharedGeometry : NSObject

@property float* texCoords;
@property short* indices;
@property short* wireframeIndices;
@property short* outlineIndices;
@property NSObject* vboCacheKey;

- (WWTerrainSharedGeometry*) init;

@end