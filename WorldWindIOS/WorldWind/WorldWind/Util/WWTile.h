/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WorldWind/Util/WWCacheable.h"

@class WWBoundingBox;
@class WWDrawContext;
@class WWGlobe;
@class WWLevel;
@class WWMemoryCache;
@class WWSector;
@class WWVec4;
@protocol WWExtent;
@protocol WWTileFactory;

/**
* Provides a base class for texture tiles used by tiled image layers and elevation tiles used by elevation models.
* Applications typically do not interact with this class.
*/
@interface WWTile : NSObject <WWCacheable>
{
@protected
    // Immutable properties inherited from the parent level and stored in the tile for fast access.
    int tileWidth;
    int tileHeight;
    double texelSize;
    // Cache key used to retrieve the tile's children from a memory cache.
    NSString* tileKey;
    // Values used to update the tile's extent and determine when the tile needs to subdivide.
    WWVec4* nearestPoint;
    // Values used to invalidate the tile's extent when the elevations or the vertical exaggeration changes.
    NSTimeInterval extentTimestamp;
    double extentVerticalExaggeration;
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

/// The tile's Cartesian bounding box.
@property(nonatomic, readonly) WWBoundingBox* extent;

/// The tile's local origin point in model coordinates.
///
/// Any model coordinate points associated with the tile should be relative to this point. The local origin point
/// depends on the elevation data currently in memory, and is not guaranteed to have a meaningful result until after
/// [WWTile update:] has been called for a given frame.
@property(nonatomic, readonly) WWVec4* referencePoint;

/// The minimum elevation value in the tile's sector.
///
/// The minimum elevation depends on the elevation data currently in memory, and is not guaranteed to have a meaningful
/// result until after [WWTile update:] has been called for a given frame.
@property(nonatomic, readonly) double minElevation;

/// The maximum elevation value in the tile's sector.
///
/// The maximum elevation depends on the elevation data currently in memory, and is not guaranteed to have a meaningful
/// result until after [WWTile update:] has been called for a given frame.
@property(nonatomic, readonly) double maxElevation;

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
* @return The row number of the specified tile.
*
* @exception NSInvalidArgumentException If the specified delta is less than or equal to 0 or the specified latitude
* is not within the range -90, 90.
*/
+ (int) computeRow:(double)delta latitude:(double)latitude;

/**
* Computes a column number for a tile within a level given its longitude.
*
* @param delta The level's longitudinal tile delta in degrees.
* @param longitude The tile's minimum longitude.
*
* @return The column number of the specified tile.
*
* @exception NSInvalidArgumentException If the specified delta is less than or equal to 0 or the specified longitude
* is not within the range --180, 180.
*/
+ (int) computeColumn:(double)delta longitude:(double)longitude;

/**
* Computes the last row number for a tile within a level given its maximum latitude.
*
* @param delta The level's latitudinal tile delta in degrees.
* @param maxLatitude The tile's maximum latitude.
*
* @return The last row number of the specified tile.
*
* @exception NSInvalidArgumentException If the specified delta is less than or equal to 0 or the specified maxLatitude
* is not within the range -90, 90.
*/
+ (int) computeLastRow:(double)delta maxLatitude:(double)maxLatitude;

/**
* Computes the last column number for a tile within a level given its maximum longitude.
*
* @param delta The level's longitudinal tile delta in degrees.
* @param maxLongitude The tile's maximum longitude.
*
* @return The last column number of the specified tile.
*
* @exception NSInvalidArgumentException If the specified delta is less than or equal to 0 or the specified maxLongitude
* is not within the range --180, 180.
*/
+ (int) computeLastColumn:(double)delta maxLongitude:(double)maxLongitude;

/**
* Computes a sector spanned by a tile with the specified level, row, and column.
*
* @param level The tile's level.
* @param row The row number of the tile within the specified level.
* @param column The column number of the tile within the specified level.
*
* @return The sector the tile spans.
*
* @exception NSInvalidArgumentException If level is nil or the row or column number are less than 0.
*/
+ (WWSector*) computeSector:(WWLevel*)level row:(int)row column:(int)column;

/// @name Initializing Tiles

/**
* Initialize a tile.
*
* @param sector The sector the tile spans.
* @param level The tile's level.
* @param row The row number of the tile within the specified level.
* @param column The column number of the tile within the specified level.
*
* @return The initialized tile.
*
* @exception NSInvalidArgumentException If the sector or level are nil or the row or column number are less than 0.
*/
- (WWTile*) initWithSector:(WWSector*)sector level:(WWLevel*)level row:(int)row column:(int)column;

/// @name Identifying and Comparing Tiles

/**
* Returns a boolean value indicating whether this tile is equivalent to the specified object.
*
* The object is considered equivalent to this tile if it is an instance of WWTile and has the same level number, row,
* and column as this tile. This returns NO if the object is nil.
*
* @param anObject The object to compare to this tile. May be nil, in which case this method returns NO.
*
* @return YES if this tile is equivalent to the specified object, otherwise NO.
*/
- (BOOL) isEqual:(id)anObject;

/**
* Returns an unsigned integer that can be used as a hash table address.
*
* If two tiles are considered equal by isEqual: then they both return the same hash value.
*
* @return An unsigned integer that can be used as a hash table address.
*/
- (NSUInteger) hash;

/// @name Creating Tiles

/**
* Create all the tiles for a specified level.
*
* @param level The level to create tiles for.
* @param tileFactory The tile factory to use for creating tiles. This is typically implemented by the calling class.
* @param tilesOut An array in which to return the created tiles.
*
* @exception NSInvalidArgumentException If the specified level, tile factory or output array are nil.
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
* Updates this tile's frame-dependent properties according to the specified draw context.
*
* The tile's frame-dependent properties include the extent (bounding volume), referencePoint, minElevation and
* maxElevation. These properties are dependent on the tile's sector and the elevation values currently in memory, and
* change when the globe's elevations change or when the scene's vertical exaggeration changes. Therefore updateExtent:
* must be called once per frame before these properties are used. updateExtent: intelligently determines when it is
* necessary to recompute these properties, and does nothing if the elevations or the vertical exaggeration have not
* changed since the last call.
*
* @param dc The draw context used to update this tile's frame-dependent properties.
*/
- (void) update:(WWDrawContext*)dc;

@end