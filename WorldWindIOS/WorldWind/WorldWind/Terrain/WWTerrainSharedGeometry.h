/*
Copyright (C) 2013 United States Government as represented by the Administrator of the
National Aeronautics and Space Administration.
All Rights Reserved.
*/



#import <Foundation/Foundation.h>


@interface WWTerrainSharedGeometry : NSObject

@property (nonatomic) float* texCoords;
@property (nonatomic) int numIndices;
@property (nonatomic) short* indices;
@property (nonatomic) short* wireframeIndices;
@property (nonatomic) int numWireframeIndices;
@property (nonatomic) short* outlineIndices;
@property (nonatomic) NSObject* vboCacheKey;

- (WWTerrainSharedGeometry*) init;

@end