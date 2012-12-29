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
    WWMatrix* texCoordMatrix;
}

/// @name Surface Tile Renderer Attributes

/// The surface tiles intersecting the terrain tile most recently specified to assembleIntersectingTiles.
@property (nonatomic, readonly) NSMutableArray* intersectingTiles;

/// The terrain tiles intersecting the surface tile most recently specified to assembleIntersectingGeometry.
@property (nonatomic, readonly) NSMutableArray* intersectingGeometry;

/**
* Returns the GPU program (WWGpuProgram) used by this surface tile renderer.
*/
- (WWGpuProgram*) gpuProgram:(WWDrawContext*)dc;

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
*
* @exception NSInvalidArgumentException If either the draw context or surface tile are nil.
*/
- (void) renderTile:(WWDrawContext*)dc surfaceTile:(id <WWSurfaceTile>)surfaceTile;

/**
* Draws a collection of surface tiles at their designated locations on the globe.
*
* An OpenGL context must be current when this method is called.
*
* @param dc The current draw context.
* @param surfaceTiles The list of surface tiles to draw.
*
* @exception If either the draw context or surface tile list is nil.
*/
- (void) renderTiles:(WWDrawContext*)dc surfaceTiles:(NSArray*)surfaceTiles;

/// @name Supporting Methods of Interest Only to Subclasses

/**
* Determine the surface tiles that intersect a specified terrain tile.
*
* This method places the set of intersecting surface tiles in this instance's intersectingTiles property.
*
* @param terrainTile The terrain tile to find intersections for.
* @param surfaceTiles The surface tiles to test for intersection.
*/
- (void) assembleIntersectingTiles:(WWTerrainTile*)terrainTile surfaceTiles:(NSArray*)surfaceTiles;

/**
* Determine the terrain tiles that intersect a specified surface tile.
*
* This method places the set of intersecting tiles in this instance's intersectingGeometry property.
*
* @param surfaceTile The surface tile to find intersections for.
* @param terrainTiles The terrain tiles to test for intersection.
*/
- (void) assembleIntersectingGeometry:(id <WWSurfaceTile>)surfaceTile terrainTiles:(WWTerrainTileList*)terrainTiles;


// The following methods are intentionally not documented.

- (void) applyTileState:(WWDrawContext*)dc
            terrainTile:(WWTerrainTile*)terrainTile
            surfaceTile:(id <WWSurfaceTile>)surfaceTile;

- (void) computeTileCoordMatrix:(WWTerrainTile*)terrainTile
                    surfaceTile:(id <WWSurfaceTile>)surfaceTile
                         result:(WWMatrix*)result;

- (void) beginRendering:(WWDrawContext*)dc program:(WWGpuProgram*)program;

- (void) endRendering:(WWDrawContext*)dc;

@end

