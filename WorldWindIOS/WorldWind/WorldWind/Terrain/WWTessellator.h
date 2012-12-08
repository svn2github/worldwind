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
@class WWTerrainSharedGeometry;
@class WWDrawContext;

@interface WWTessellator : NSObject
{
@protected
    NSMutableArray* topLevelTiles;
}

@property (readonly, nonatomic) WWGlobe* globe;
@property (readonly, nonatomic) WWTerrainSharedGeometry* sharedGeometry;

- (WWTessellator*) initWithGlobe:(WWGlobe*)globe;
- (void) createTopLevelTiles;
- (WWTerrainTileList*) tessellate:(WWDrawContext*)dc;
- (BOOL) mustRegenerateGeometry:(WWDrawContext*)dc tile:(WWTerrainTile*)tile;
- (void) regenerateGeometry:(WWDrawContext*)dc tile:(WWTerrainTile*)tile;
- (void) buildSharedGeometry;
- (void) beginRendering:(WWDrawContext*)dc;
- (void) endRendering:(WWDrawContext*)dc;
- (void) beginRendering:(WWDrawContext*)dc tile:(WWTerrainTile*)tile;
- (void) endRendering:(WWDrawContext*)dc tile:(WWTerrainTile*)tile;
- (void) render:(WWDrawContext*)dc tile:(WWTerrainTile*)tile;
- (void) renderWireFrame:(WWDrawContext*)dc tile:(WWTerrainTile*)tile;

@end
