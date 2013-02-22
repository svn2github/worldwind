/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

@class WWLocation;
@protocol WWUrlBuilder;
@class WWLevelSet;
@class WWSector;

/**
* Provides a class representing one level within a WWLevelSet. Applications typically do not interact with this class.
*/
@interface WWLevel : NSObject

/// @name Attributes

/// The WWLevelSet this level is a member of.
@property (nonatomic, readonly, weak) WWLevelSet* parent;

/// The level's ordinal in its parent level set.
@property (nonatomic, readonly) int levelNumber;

/// The geographic size of tiles in this level.
@property (nonatomic, readonly) WWLocation* tileDelta;

/// The size of pixels or elevation cells in this level.
@property (nonatomic, readonly) double texelSize;

/**
* Indicates the width in pixels or cells of the tile's resource.
*
* @return The width of the tile's resource in this level.
*/
- (int) tileWidth;

/**
* Indicates the height in pixels or cells of the tile's resource.
*
* @return The height of the tile's resource in this level.
*/
- (int) tileHeight;

/**
* Indicates the sector spanned by this level.
*
* @return The sector spanned by this level.
*/
- (WWSector*) sector;

/**
* Indicates whether this level is the lowest resolution level (level 0) within its parent level set.
*
* The lowest resolution level always has an ordinal of 0.
*
* @return YES if this level is the lowest resolution level in the level set, otherwise NO.
*/
- (BOOL) isFirstLevel;

/**
* Indicates whether this level is the highest resolution level within its parent level set.
*
* @return YES if this level is the highest resolution level in the level set, otherwise NO.
*/
- (BOOL) isLastLevel;

/// @name Initializing Levels

/**
* Initialize this level.
*
* @param levelNumber The level's ordinal in its parent level set.
* @param tileDelta The geographic size of tiles in this level.
* @param parent The WWLevelSet this level is a member of.
*
* @return This level, initialized.
*
* @exception NSInvalidArgumentException If the tile delta or the parent is nil.
*/
- (WWLevel*) initWithLevelNumber:(int)levelNumber tileDelta:(WWLocation*)tileDelta parent:(WWLevelSet*)parent;

/// @name Operations on Levels

/**
* Returns the level who's ordinal occurs immediately before this level's ordinal in the parent level set, or nil if
* this is the first level.
*
* @return The previous level, or nil if this is the first level.
*/
- (WWLevel*) previousLevel;

/**
* Returns the level who's ordinal occurs immediately after this level's ordinal in the parent level set, or nil if this
* is the last level.
*
* @return The next level, or nil if this is the last level.
*/
- (WWLevel*) nextLevel;

/**
* Returns the result of comparing this level's ordinal with the specified level's ordinal.
*
* - NSOrderedSame - If the two ordinals are equivalent.
* - NSOrderedAscending - If this level's ordinal is less than the specified level's ordinal.
* - NSOrderedDescending - If this level's ordinal is greater than the specified level's ordinal.
*
* @param level The level to compare with this level.
*
* @return The NSComparison result of comparing this level with the specified level.
*
* @exception NSInvalidArgumentException If the level is nil.
*/
- (NSComparisonResult) compare:(WWLevel*)level;

@end