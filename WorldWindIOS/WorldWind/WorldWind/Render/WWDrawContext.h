/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>
#import <OpenGLES/ES2/gl.h>

@class WWGlobe;
@class WWLayerList;
@class WWTerrainTileList;
@class WWSector;
@class WWGpuProgram;
@class WWMatrix;
@class WWSurfaceTileRenderer;

@interface WWDrawContext : NSObject

@property (readonly, nonatomic) NSDate* timestamp;
@property (nonatomic) WWGlobe* globe;
@property (nonatomic) WWLayerList* layers;
@property (nonatomic) WWTerrainTileList* surfaceGeometry;
@property (nonatomic) WWSector* visibleSector;
@property (nonatomic) WWGpuProgram* currentProgram;
@property (nonatomic) WWMatrix* modelviewProjection;
@property (nonatomic) double verticalExaggeration;
@property (readonly, nonatomic) WWSurfaceTileRenderer* surfaceTileRenderer;

- (void) reset;

@end
