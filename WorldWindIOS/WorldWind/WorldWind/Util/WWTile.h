/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WorldWind/Util/WWCacheable.h"

@class WWSector;
@class WWLevel;
@class WWDrawContext;
@protocol WWTileFactory;
@class WWGlobe;
@protocol WWExtent;
@class WWBoundingBox;
@class WWMemoryCache;

/**
* Provides a base class for texture tiles used by tiled image layers and elevation tiles used by elevation models.
* Applications typically do not interact with this class.
*/
@interface WWTile : NSObject <WWCacheable>
{
@protected
    NSString* tileKey;
}

/// @name Attributes

/// The sector this tile spans.
@property(nonatomic, readonly) WWSector* sector;

/// The level this tile is associated with.
@property(nonatomic, readonly) WWLevel* level;

/// The tile's row in the associated level.
@property(nonatomic, readonly) int row;

/// The tile's column in the associated level.
@property(nonatomic, readonly) int column;

/// Cartesian coordinates of the tile's corners, center and potentially other key locations on the tile.
@property(nonatomic, readonly) NSMutableArray* referencePoints;

/// The tile's Cartesian bounding box.
@property(nonatomic, readonly) WWBoundingBox* extent;

/**
* Indicates the width in pixels or cells of this tile's resource.
*
* @return The requested width.
*/
- (int) tileWidth;

/**
* Indicates the height in pixels of cells of this tile's resource.
*
* @return The requested height.
*/
- (int) tileHeight;

/**
 * Indicates the size of pixels or elevation cells of this tile's resource, in radians per pixel.
 *
 * @return The requested size.
 */
- (double) texelSize;

/**
* Computes a row number for a tile within a level given its latitude.
*
* @param delta The level's latitudinal tile delta in degrees.
* @param latitude The tile's minimum latitude.
*
* @return the row number of the specified tile.
*
* @exception NSInvalidArgumentException if the specified delta is less than or equal to 0 or the specified latitude
* is not within the range -90, 90.
*/
+ (int) computeRow:(double)delta latitude:(double)latitude;

/**
* Computes a column number for a tile within a level given its longitude.
*
* @param delta The level's longitudinal tile delta in degrees.
* @param longitude The tile's minimum longitude.
*
* @return the column number of the specified tile.
*
* @exception NSInvalidArgumentException if the specified delta is less than or equal to 0 or the specified longitude
* is not within the range --180, 180.
*/
+ (int) computeColumn:(double)delta longitude:(double)longitude;

/// @name Initializing Tiles

/**
* Initialize a tile.
*
* @param sector The sector the tile spans.
* @param level The tile's level.
* @param row The row number of the tile within the specified level.
* @param column The column number of the tile withing the specified level.
*
* @return The initialized tile.
*
* @exception NSInvalidArgumentException If the sector or level are nil or the row or column number are less than 0.
*/
- (WWTile*) initWithSector:(WWSector*)sector level:(WWLevel*)level row:(int)row column:(int)column;

/// @name Creating Tiles

/**
* Create all the tiles for a specified level.
*
* @param level The level to create tiles for.
* @param tileFactory The tile factory to use for creating tiles. This is typically implemented by the calling class.
* @param tilesOut An array in which to return the created tiles.
*
* @exception NSInvalidArgumentException if the specified level, tile factory or output array are nil.
*/
+ (void) createTilesForLevel:(WWLevel*)level
                 tileFactory:(id <WWTileFactory>)tileFactory
                    tilesOut:(NSMutableArray*)tilesOut;

/**
* Returns the four children formed by subdividing this tile.
*
* @param nextLevel The level of the children.
* @param tileFactory The tile factory to use to create the children.
*
* @return An array of four child tiles.
*
* @exception NSInvalidArgumentException If either the nextLevel or tileFactory parameters are nil.
*/
- (NSArray*) subdivide:(WWLevel*)nextLevel tileFactory:(id <WWTileFactory>)tileFactory;

/**
* Returns the four children formed by subdividing this tile, drawing from and adding to a specified cache.
*
* @param nextLevel The level of the children.
* @param cache The cache to use for the tiles.
* @param tileFactory The tile factory to use to create the children.
*
* @return An array of four child tiles.
*
* @exception NSInvalidArgumentException If either the nextLevel or tileFactory parameters are nil.
*/
- (NSArray*) subdivide:(WWLevel*)nextLevel cache:(WWMemoryCache*)cache tileFactory:(id <WWTileFactory>)tileFactory;

/**
* Determines whether the tile should be subdivided based on the current navigation state and a specified detail factor.
*
* This method assumes that the tile's reference points are current relative to the current globe and vertical
* exaggeration.
*
* @param dc The current draw context.
* @param detailFactor The detail factor to consider.
*
* @return YES if the tile should be subdivided, otherwise NO.
*/
- (BOOL) mustSubdivide:(WWDrawContext*)dc detailFactor:(double)detailFactor;

/// @name Operations on Tiles

/**
* Updates the tile's reference points to reflect current state.
*
* The tile's reference points are the Cartesian points corresponding to the tile's corner and center points. These
* must be up-to-date for certain operations such as computing the tile's extent or whether it should be subdivided.
*
* @param globe The globe the tile's associated with.
* @param verticalExaggeration The current vertical exaggeration.
*
* @exception NSInvalidArgumentException If the globe is nil.
*/
- (void) updateReferencePoints:(WWGlobe*)globe verticalExaggeration:(double)verticalExaggeration;

/**
* Updates this tile's extent (bounding volume).
*
* @param globe The globe to use to compute this tile's extent.
* @param verticalExaggeration The vertical exaggeration to use when computing the extent.
*/
- (void) updateExtent:(WWGlobe*)globe verticalExaggeration:(double)verticalExaggeration;

@end