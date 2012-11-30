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
@class WWDrawContext;

@interface WWTessellator : NSObject
{
@protected
    NSMutableArray* topLevelTiles;
}

@property (readonly) WWGlobe* globe;

- (WWTessellator*) initWithGlobe:(WWGlobe*)globe;
- (void) createTopLevelTiles;
- (WWTerrainTileList*) tessellate:(WWDrawContext*)dc;
- (void) beginRendering:(WWDrawContext*)dc;
- (void) endRendering:(WWDrawContext*)dc;
- (void) beginRendering:(WWDrawContext*)dc terrainTile:(WWTerrainTile*)tile;
- (void) endRendering:(WWDrawContext*)dc terrainTile:(WWTerrainTile*)tile;
- (void) render:(WWDrawContext*)dc tile:(WWTerrainTile*)tile;

@end
