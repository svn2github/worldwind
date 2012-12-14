/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

@class WWGpuProgram;
@class WWDrawContext;
@class WWTerrainTile;
@class WWTerrainTileList;
@class WWMatrix;
@protocol WWSurfaceTile;

@interface WWSurfaceTileRenderer : NSObject
{
@protected
    WWGpuProgram* rendererProgram;
    WWMatrix* tileCoordMatrix;
    WWMatrix* texCoordMatrix;
    NSMutableArray* intersectingTiles;
    NSMutableArray* intersectingGeometry;
}

- (WWSurfaceTileRenderer*) init;

- (WWGpuProgram*) gpuProgram;

- (void) assembleIntersectingTiles:(WWTerrainTile*)terrainTile surfaceTiles:(NSArray*)surfaceTiles;

- (void) assembleIntersectingGeometry:(id <WWSurfaceTile>)surfaceTile terrainTiles:(WWTerrainTileList*)terrainTiles;

- (void) applyTileState:(WWDrawContext*)dc
            terrainTile:(WWTerrainTile*)terrainTile
            surfaceTile:(id <WWSurfaceTile>)surfaceTile;

- (void) computeTileCoordMatrix:(WWTerrainTile*)terrainTile
                    surfaceTile:(id <WWSurfaceTile>)surfaceTile
                         result:(WWMatrix*)result;

- (void) beginRendering:(WWDrawContext*)dc program:(WWGpuProgram*)program;

- (void) endRendering:(WWDrawContext*)dc;

- (void) renderTile:(WWDrawContext*)dc surfaceTile:(id <WWSurfaceTile>)surfaceTile;

- (void) renderTiles:(WWDrawContext*)dc surfaceTiles:(NSArray*)surfaceTiles;

@end