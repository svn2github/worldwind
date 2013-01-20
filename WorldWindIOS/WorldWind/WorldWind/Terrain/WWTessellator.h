/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

@class WWGlobe;
@class WWSector;
@class WWTerrainTile;
@class WWTerrainTileList;
@class WWTerrainGeometry;
@class WWTerrainSharedGeometry;
@class WWDrawContext;
@class WWVec4;

@interface WWTessellator : NSObject
{
@protected
    NSMutableArray* topLevelTiles;
}
// The globe property is weak because the globe contains a strong pointer to the tessellator. Making the tessellator's
// pointer to the globe strong would create a cycle and prevent both from being released.
@property(readonly, nonatomic, weak) WWGlobe* globe;
@property(readonly, nonatomic) WWTerrainSharedGeometry* sharedGeometry;

- (WWTessellator*) initWithGlobe:(WWGlobe*)globe;

- (void) createTopLevelTiles;

- (WWTerrainTileList*) tessellate:(WWDrawContext*)dc;

- (BOOL) mustRegenerateGeometry:(WWDrawContext*)dc tile:(WWTerrainTile*)tile;

- (void) regenerateGeometry:(WWDrawContext*)dc tile:(WWTerrainTile*)tile;

- (void) buildSharedGeometry:(WWTerrainTile*)terrainTile;

- (void) beginRendering:(WWDrawContext*)dc;

- (void) endRendering:(WWDrawContext*)dc;

- (void) beginRendering:(WWDrawContext*)dc tile:(WWTerrainTile*)tile;

- (void) endRendering:(WWDrawContext*)dc tile:(WWTerrainTile*)tile;

- (void) render:(WWDrawContext*)dc tile:(WWTerrainTile*)tile;

- (void) renderWireFrame:(WWDrawContext*)dc tile:(WWTerrainTile*)tile;

- (WWVec4*) referenceCenterForTile:(WWDrawContext*)dc tile:(WWTerrainTile*)tile;

- (void) buildTileVertices:(WWDrawContext*)dc tile:(WWTerrainTile*)tile;

- (void) buildTileRowVertices:(WWGlobe*)globe
                    rowSector:(WWSector*)rowSector
               numRowVertices:(int)numRowVertices
                   elevations:(double [])elevations
            constantElevation:(double*)constantElevation
                 minElevation:(double)minElevation
                    refCenter:(WWVec4*)refCenter
                       points:(float [])points;

- (float*) buildTexCoords:(int)tileWidth tileHeight:(int)tileHeight numCoordsOut:(int*)numCoordsOut;

- (short*) buildIndices:(int)tileWidth tileHeight:(int)tileHeight numIndicesOut:(int*)numIndicesOut;

- (short*) buildWireframeIndices:(int)tileWidth tileHeight:(int)tileHeight numIndicesOut:(int*)numIndicesOut;

@end
