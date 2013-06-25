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

/**
* Renders surface tiles that apply imagery to a globe's terrain. During drawing, the draw context (WWDrawContext)
* holds a surface tile renderer. Image based layers and shapes such as WWTiledImageLayer and WWSurfaceImage use the
* surface tile renderer to draw themselves onto the globe. Applications typically do not interact with a surface tile
 * renderer directly, although application-implemented layers might.
*/
@interface WWSurfaceTileRenderer : NSObject
{
@protected
    NSString* programKey;
    WWMatrix* tileCoordMatrix;
    WWMatrix* textureMatrix;
}

/// @name Initialized a Surface Tile Renderer

/**
* Initialize a surface tile renderer.
*
* @return This surface tile renderer initialized.
*/
- (WWSurfaceTileRenderer*) init;

/// @name Causing a Surface Tile Renderer to Draw

/**
* Draws a single tile at its designated location on the current globe.
*
* An OpenGL context must be current when this method is called.
*
* @param dc The current draw context.
* @param surfaceTile The surface tile to draw.
* @param opacity The opacity with which to render the tile.
*
* @exception NSInvalidArgumentException If either the draw context or surface tile are nil.
*/
- (void) renderTile:(WWDrawContext*)dc surfaceTile:(id <WWSurfaceTile>)surfaceTile opacity:(float)opacity;

/**
* Draws a collection of surface tiles at their designated locations on the globe.
*
* An OpenGL context must be current when this method is called.
*
* @param dc The current draw context.
* @param surfaceTiles The list of surface tiles to draw.
* @param opacity The opacity with which to render the tiles.
*
* @exception If either the draw context or surface tile list is nil.
*/
- (void) renderTiles:(WWDrawContext*)dc surfaceTiles:(NSArray*)surfaceTiles opacity:(float)opacity;

/// @name Supporting Methods of Interest Only to Subclasses

// The following methods are intentionally not documented.

- (void) beginRendering:(WWDrawContext*)dc opacity:(float)opacity;

- (void) endRendering:(WWDrawContext*)dc;

- (void) applyTileState:(WWDrawContext*)dc
            terrainTile:(WWTerrainTile*)terrainTile
            surfaceTile:(id <WWSurfaceTile>)surfaceTile;

@end