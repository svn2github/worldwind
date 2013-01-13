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

/// @name Attributes

/// The sector this level set covers.
@property(nonatomic, readonly) WWSector* sector;

/// The geographic size of lowest resolution (level 0) tiles in this level set.
@property(nonatomic, readonly) WWLocation* levelZeroDelta;

/// The number of levels in this level set.
@property(nonatomic, readonly) int numLevels;

/// The width in pixels of images associated with tiles in this level set, or the number of sample points in the
// longitudinal direction of elevation tiles associate with this level set. The default width is 256.
@property(nonatomic) int tileWidth;

/// The height in pixels of images associated with tiles in this level set, or the number of sample points in the
// latitudinal direction of elevation tiles associate with this level set. The default height is 256.
@property(nonatomic) int tileHeight;

/// The time at which resources in this level set most recently expired. Resources with dates later than this time
// are valid, but resources with dates prior to this time are not.
@property(nonatomic) NSTimeInterval expiryTime;

/// The number of longitudinal cells in level 0 of this level set.
@property(nonatomic, readonly) int numLevelZeroColumns;

/**
* Returns the level for a specified level number.
*
* @param levelNumber The number of the level to return.
*
* @return The requested level, or nil if the level does not exist.
*/
- (WWLevel*) level:(int)levelNumber;

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
* Indicates the number of longitudinal cells in a specified level.
*
* @param level The level of interest.
*
* @return The number of columns in the specified level.
*/
- (int) numColumnsInLevel:(WWLevel*)level;

/**
* Indicates whether a specified level number indicates the highest resolution level in the level set.
*
* @param levelNumber The level number of interest.
*
* @return YES if the level number indicated the highest resolution level in the level set, otherwise NO.
*/
- (BOOL) isLastLevel:(int)levelNumber;

/// @name Initializing Level Sets

/**
* Initialize a level set.
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

@end