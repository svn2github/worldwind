/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

@class WWSector;
@class WWLocation;
@class WWTile;
@class WWLevel;
@protocol WWUrlBuilder;

/**
* Represents a multi-resolution, hierarchical collection of tiles. Applications typically to not interact with this
* class.
*
* This class provides a quad tree for image tiles (see WWTiledImageLayer) and elevation tiles.
*/
@interface WWLevelSet : NSObject
{
@protected
    NSMutableArray* levels;
}

/// @name Level Set Attributes

/// The sector this level set covers.
@property(nonatomic, readonly) WWSector* sector;

/// The geographic size of lowest resolution (level 0) tiles in this level set.
@property(nonatomic, readonly) WWLocation* levelZeroDelta;

/// The number of levels in this level set.
@property(nonatomic, readonly) int numLevels;

/// The width in pixels of images associated with tiles in this level set, or the number of sample points in the
// longitudinal direction of elevation tiles associate with this level set. The default width is 256.
@property(nonatomic, readonly) int tileWidth;

/// The height in pixels of images associated with tiles in this level set, or the number of sample points in the
// latitudinal direction of elevation tiles associate with this level set. The default height is 256.
@property(nonatomic, readonly) int tileHeight;

/// The number of longitudinal cells in level 0 of this level set.
@property(nonatomic, readonly) int numLevelZeroColumns;

/// The time at which resources in this level set most recently expired. Resources with dates later than this time
// are valid, but resources with dates prior to this time are not.
@property(nonatomic) NSTimeInterval expiryTime;

/// @name Initializing Level Sets

/**
* Initialize a level set with the default tile width and tile height of 256.
*
* @param sector The sector spanned by this level set.
* @param levelZeroDelta The geographic size of tiles in the lowest resolution level of this level set.
* @param numLevels The number of levels in the level set.
*
* @return The level set, initialized.
*
* @exception NSInvalidArgumentException If the specified sector or level zero tile delta are nil,
* or the number of levels is less than 1.
*/
- (WWLevelSet*) initWithSector:(WWSector*)sector
                levelZeroDelta:(WWLocation*)levelZeroDelta
                     numLevels:(int)numLevels;

/**
* Initialize a level set with a specified tile width and tile height.
*
* @param sector The sector spanned by this level set.
* @param levelZeroDelta The geographic size of tiles in the lowest resolution level of this level set.
* @param numLevels The number of levels in the level set.
* @param tileWidth The height in pixels of images associated with tiles in this level set, or the number of sample
* points in the longitudinal direction of elevation tiles associate with this level set.
* @param tileHeight The height in pixels of images associated with tiles in this level set, or the number of sample
* points in the latitudinal direction of elevation tiles associate with this level set.
*
* @return The level set, initialized.
*
* @exception NSInvalidArgumentException If the specified sector or level zero tile delta are nil, the number of levels
* is less than 1, or either tile size is less than 1.
*/
- (WWLevelSet*) initWithSector:(WWSector*)sector
                levelZeroDelta:(WWLocation*)levelZeroDelta
                     numLevels:(int)numLevels
                     tileWidth:(int)tileWidth
                    tileHeight:(int)tileHeight;

/// @name Accessing Levels

/**
* Returns the level for a specified level number.
*
* @param levelNumber The number of the level to return.
*
* @return The requested level, or nil if the level does not exist.
*/
- (WWLevel*) level:(int)levelNumber;

/**
* Returns the level with a specified texel size.
*
* This returns the first level if the specified texel size is greater than the first level's texel size, and returns the
* last level if the delta is less than the last level's texel size.
*
* @param texelSize The size of pixels or elevation cells in the level, in radians per pixel or cell.
*
* @return The requested level.
*/
- (WWLevel*) levelForTexelSize:(double)texelSize;

/**
* Returns the level with a specified geographic tile size.
*
* This returns the first level if the specified delta is greater than the level zero delta, and returns the last level
* if the delta is less than the last level's delta.
*
* @param deltaLatDegrees The geographic size of the level's tiles, in degrees latitude.
*
* @return The requested level.
*/
- (WWLevel*) levelForTileDelta:(double)deltaLatDegrees;

/**
* Returns The first (lowest resolution) level, level 0, of this level set.
*
* @return level 0 of this level set.
*/
- (WWLevel*) firstLevel;

/**
* Returns the last (highest resolution) level in this level set.
*
* @return The highest resolution level in this level set.
*/
- (WWLevel*) lastLevel;

/**
* Indicates whether a specified level number indicates the highest resolution level in the level set.
*
* @param levelNumber The level number of interest.
*
* @return YES if the level number indicated the highest resolution level in the level set, otherwise NO.
*/
- (BOOL) isLastLevel:(int)levelNumber;

/// @name Enumerating Level Sets

/**
* Returns the number of tiles in this level set that intersect the specified sector.
*
* This counts the number of tiles between the first level and the last level that intersect the specified sector, and
* returns the result.
*
* @param sector The sector to determine a tile count for.
*
* @return The tile count for the specified sector.
*
* @exception NSInvalidArgumentException If the sector is nil.
*/
- (NSUInteger) tileCountForSector:(WWSector*)sector;

/**
* Returns the number of tiles in this level set that intersect the specified sector, up to and including the specified
* last level.
*
* This counts the number of tiles between the first level and the specified last level that intersect the specified
* sector, and returns the result. If lastLevel is zero this counts tiles in the first level.
*
* @param sector The sector to determine a tile count for.
* @param lastLevel The level number indicating the last level to include in the tile count.
*
* @return The tile count for the specified sector.
*
* @exception NSInvalidArgumentException If the sector is nil, or if lastLevel indicates a level that does not exist.
*/
- (NSUInteger) tileCountForSector:(WWSector*)sector lastLevel:(int)lastLevel;

/**
* Returns an enumerator object that lets the caller access each tile in the level set intersecting the specified sector.
*
* The enumerator traverses the tiles of level that intersect the sector in row-major order, starting with the first
* level and ending with the last level.
*
* The enumerator's nextObject method returns instances of WWTileKey corresponding to the current level row and column.
* These instances are mutable and must not be retained or modified by the caller. Calls to nextObject should be wrapped
* in a local autorelease pool. Each call to nextObject results in an autoreleased object and the overhead of the
* autorelease information can be substantial when enumerating the tiles of a level set.
*
* @param sector The sector to enumerate.
*
* @return An enumerator that lets the caller access each tile in the level set.
*
* @exception NSInvalidArgumentException If the sector is nil.
*/
- (NSEnumerator*) tileEnumeratorForSector:(WWSector*)sector;

/**
* Returns an enumerator object that lets the caller access each tile in the level set intersecting the specified sector,
* up to and including the specified last level.
*
* The enumerator traverses the tiles of level that intersect the sector in row-major order, starting with the first
* level and ending with the specified last level. If lastLevel is zero the enumerator traverses tiles in the first
* level.
*
* The enumerator's nextObject method returns instances of WWTileKey corresponding to the current level row and column.
* These instances are mutable and must not be retained or modified by the caller. Calls to nextObject should be wrapped
* in a local autorelease pool. Each call to nextObject results in an autoreleased object and the overhead of the
* autorelease information can be substantial when enumerating the tiles of a level set.
*
* @param sector The sector to enumerate.
* @param lastLevel The level number indicating the last level to include in the enumerator.
*
* @return An enumerator that lets the caller access each tile in the level set.
*
* @exception NSInvalidArgumentException If the sector is nil, or if lastLevel indicates a level that does not exist.
*/
- (NSEnumerator*) tileEnumeratorForSector:(WWSector*)sector lastLevel:(int)lastLevel;

@end