/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WorldWind/Util/WWTileFactory.h"

@class WWDrawContext;
@class WWGlobe;
@class WWLevelSet;
@class WWMatrix;
@class WWMemoryCache;
@class WWPickedObject;
@class WWSector;
@class WWTerrainSharedGeometry;
@class WWTerrainTile;
@class WWTerrainTileList;
@class WWVec4;

/**
* Provides tessellation of a globe. Applications typically do not interact with a tessellator. Tessellators are
* created by globe instances and invoked by scene controller.
*/
@interface WWTessellator : NSObject <WWTileFactory>
{
    WWLevelSet* levels;
    NSMutableArray* topLevelTiles;
    WWTerrainTileList* currentTiles;
    WWSector* currentCoverage;
    double detailHintOrigin;

    WWMemoryCache* tileCache;
    NSTimeInterval elevationTimestamp;
    double* tileElevations;
    WWMatrix* lastMVP;

    int vertexPointLocation;
    int vertexTexCoordLocation;
    int vertexElevationLocation;
    int mvpMatrixLocation;
}

/// @name Tessellator Attributes

// The globe property is weak because the globe contains a strong pointer to the tessellator. Making the tessellator's
// pointer to the globe strong would create a cycle and prevent both from being released.
/// The globe associated with the tessellator.
@property(readonly, nonatomic, weak) WWGlobe* globe;

/// Geometry shared by all terrain tiles. Applications typically do not interact with this property.
@property(readonly, nonatomic) WWTerrainSharedGeometry* sharedGeometry;

/// The current detail hint.
@property(nonatomic) double detailHint; // TODO: Document this per setDetailHint in the desktop/android version

/// Indicates whether the tessellator passes elevations to the shader program.
@property(nonatomic) BOOL elevationShadingEnabled;

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

/// @name Rendering Tessellator Tiles

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
- (void) renderWireframe:(WWDrawContext*)dc tile:(WWTerrainTile*)tile;

/**
* Draws an outline representation of a specified tile.
*
* @param dc The current draw context.
* @param tile The tile to draw.
*/
- (void) renderOutline:(WWDrawContext*)dc tile:(WWTerrainTile*)tile;

/**
* Performs a pick on the currently visible terrain.
*
* @param dc The current draw context.
*/
- (void) pick:(WWDrawContext*)dc;

/// @name Creating Tessellator Tiles

/**
* Creates an tessellator tile corresponding to a specified sector and level. Implements the method of WWTileFactory.
*
* This method is typically not overridden by subclasses.
*
* @param sector The sector over which the tile spans.
* @param level The tile's level.
* @param row The tile's row.
* @param column The tile's column.
*
* @return The new tile, initialized.
*/
- (WWTile*) createTile:(WWSector*)sector level:(WWLevel*)level row:(int)row column:(int)column;

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
* Indicates whether a specified tile is visible in the current view.
*
* @param dc The current draw context.
* @param tile The tile to consider.
*
* @return YES if the tile is at least partially visible in the current frame, otherwise NO.
*/
- (BOOL) isTileVisible:(WWDrawContext*)dc tile:(WWTerrainTile*)tile;

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
* Indicates whether the terrain geometry for a specified tile must be re-created.
*
* A tile's terrain geometry must be re-created if it has no geometry, or of the elevations on which the geometry is
* based have changed since the geometry was created.
*
* @param dc The current draw context.
* @param tile The tile to test.
*
* @return YES if the tile's geometry must be re-created, otherwise NO.
*/
- (BOOL) mustRegenerateTileGeometry:(WWDrawContext*)dc tile:(WWTerrainTile*)tile;

/**
* Create the terrain geometry for a specified tile.
*
* @param dc The current draw context.
* @param tile The tile to create geometry for.
*/
- (void) regenerateTileGeometry:(WWDrawContext*)dc tile:(WWTerrainTile*)tile;

/**
* Creates the Cartesian vertices for a specified tile.
*
* @param dc The current draw context.
* @param tile The tile whose vertices to compute.
*/
- (void) buildTileVertices:(WWDrawContext*)dc tile:(WWTerrainTile*)tile;

// The following methods are intentionally not documented.

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

@end