/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WorldWind/Util/WWTileFactory.h"

@class WWGlobe;
@class WWSector;
@class WWTerrainTile;
@class WWTerrainTileList;
@class WWTerrainGeometry;
@class WWTerrainSharedGeometry;
@class WWDrawContext;
@class WWVec4;
@class WWLevelSet;
@class WWMemoryCache;

/**
* Provides tessellation of a globe. Applications typically do not interact with a tessellator. Tessellators are
* created by globe instances and invoked by scene controller.
*/
@interface WWTessellator : NSObject <WWTileFactory>

/// @name Tessellator Attributes

// The globe property is weak because the globe contains a strong pointer to the tessellator. Making the tessellator's
// pointer to the globe strong would create a cycle and prevent both from being released.
/// The globe associated with the tessellator.
@property(readonly, nonatomic, weak) WWGlobe* globe;

/// Geometry shared by all terrain tiles. Applications typically do not interact with this property.
@property(readonly, nonatomic) WWTerrainSharedGeometry* sharedGeometry;

/// The current detail hint.
@property(nonatomic) double detailHint; // TODO: Document this per setDetailHint in the desktop/android version

/// @name Initializing Tessellators

- (WWTessellator*) initWithGlobe:(WWGlobe*)globe;

/// @name Tessellating a Globe

/**
* Tessellate this tessellator's associated globe.
*
* Application's typically do not call this method. It is called by the scene controller during rendering.
*
* @param dc The current draw context.
*
* @exception NSInvalidArgumentException If the draw context is nil.
*/
- (WWTerrainTileList*) tessellate:(WWDrawContext*)dc;

/// @name Methods of Interest Only to Subclasses

/**
* Create this tessellator's top-level tiles.
*/
- (void) createTopLevelTiles;

/**
* Adds a specified tile or its descendants -- depending on the necessary resolution -- to the list of tiles
* for the current frame.
*
* @param dc The current draw context.
* @param tile The tile to consider.
*/
- (void) addTileOrDescendants:(WWDrawContext*)dc tile:(WWTerrainTile*)tile;

/**
* Adds a specified tile to the list of tiles for the current frame.
*
* @param dc The current draw context.
* @param tile The tile to add.
*/
- (void) addTile:(WWDrawContext*)dc tile:(WWTerrainTile*)tile;

/**
* Indicates whether a specified tile meets the criteria to be included in the current frame.
*
* @param dc The current draw context.
* @param tile The tile to consider.
*
* @return YES if the tile meets the criteria, otherwise NO.
*/
- (BOOL) tileMeetsRenderCriteria:(WWDrawContext*)dc tile:(WWTerrainTile*)tile;

/**
* Indicates whether a specified tile is visible in the current view.
*
* @param dc The current draw context.
* @param tile The tile to consider.
*
* @return YES if the tile is at least partially visible in the current frame, otherwise NO.
*/
- (BOOL) isTileVisible:(WWDrawContext*)dc tile:(WWTerrainTile*)tile;

/**
* Create geometry for a specified tile.
*
* @param dc The current draw context.
* @param tile The tile to create geometry for.
*/
- (void) regenerateTileGeometry:(WWDrawContext*)dc tile:(WWTerrainTile*)tile;

/**
* Computes the Cartesian reference center point for a specified tile.
*
* @param dc The current draw context.
* @param tile The tile whose reference center to compute.
*
* @return The computed reference center.
*/
- (WWVec4*) referenceCenterForTile:(WWDrawContext*)dc tile:(WWTerrainTile*)tile;

/**
* Creates the Cartesian vertices for a specified tile.
*
* @param dc The current draw context.
* @param tile The tile whose vertices to compute.
*/
- (void) buildTileVertices:(WWDrawContext*)dc tile:(WWTerrainTile*)tile;

// The following methods are intentionally not documented.

- (void) buildTileRowVertices:(WWGlobe*)globe
                    rowSector:(WWSector*)rowSector
               numRowVertices:(int)numRowVertices
                   elevations:(double [])elevations
            constantElevation:(double*)constantElevation
                 minElevation:(double)minElevation
                    refCenter:(WWVec4*)refCenter
                       points:(float [])points;

/**
* Creates geometry and other information shared by all tiles.
*
* @param terrainTile A template tile indicating the shared tile parameters.
*/
- (void) buildSharedGeometry:(WWTerrainTile*)terrainTile;

- (float*) buildTexCoords:(int)tileWidth tileHeight:(int)tileHeight numCoordsOut:(int*)numCoordsOut;

- (short*) buildIndices:(int)tileWidth tileHeight:(int)tileHeight numIndicesOut:(int*)numIndicesOut;

- (short*) buildWireframeIndices:(int)tileWidth tileHeight:(int)tileHeight numIndicesOut:(int*)numIndicesOut;

- (short*) buildOutlineIndices:(int)tileWidth tileHeight:(int)tileHeight numIndicesOut:(int*)numIndicesOut;

/**
* Establishes OpenGL state used while drawing tiles of this tessellator.
*
* @param dc The current draw context.
*/
- (void) beginRendering:(WWDrawContext*)dc;

/**
* Resets OpenGL state established during beginRendering.
*
* @param dc The current draw context.
*/
- (void) endRendering:(WWDrawContext*)dc;

/**
* Establishes OpenGL state used while drawing a specified tile.
*
* @param dc The current draw context.
* @param tile The tile to establish state for.
*/
- (void) beginRendering:(WWDrawContext*)dc tile:(WWTerrainTile*)tile;

/**
* Resets OpenGL state used while drawing a tile.
*
* @param dc The current draw context.
* @param tile The tile to reset state for.
*/
- (void) endRendering:(WWDrawContext*)dc tile:(WWTerrainTile*)tile;

/**
* Draws a specified tile.
*
* @param dc The current draw context.
* @param tile The tile to draw.
*/
- (void) render:(WWDrawContext*)dc tile:(WWTerrainTile*)tile;

/**
* Draws a wireframe representation of a specified tile.
*
* @param dc The current draw context.
* @param tile The tile to draw.
*/
- (void) renderWireFrame:(WWDrawContext*)dc tile:(WWTerrainTile*)tile;

/**
* Draws an outline representation of a specified tile.
*
* @param dc The current draw context.
* @param tile The tile to draw.
*/
- (void) renderOutline:(WWDrawContext*)dc tile:(WWTerrainTile*)tile;

@end