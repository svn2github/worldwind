/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>

@class WWLevel;
@class WWLevelSet;
@class WWSector;
@class WWTileKey;

/**
* WWLevelSetEnumerator is a subclass of NSEnumerator that enumerates the tiles in a WWLevelSet.
*
* Level set enumerators are not intended to be used directly, and when possible should be created through the methods
* defined in WWLevelSet. For example, [WWLevelSet tileEnumeratorForSector:] returns an enumerator object that lets the
* caller access each tile in the level set intersecting the specified sector.
*
* The caller sends nextObject repeatedly to a newly created WWLevelSetEnumerator to have it return a WWTileKey
* corresponding to the next tile in the level set. The WWTileKey instances returned by nextObject are mutable and must
* not be retained or modified by the caller. The enumerator traverses the tiles of level that intersect the specified
* sector in row-major order, starting with the specified first level and ending with the specified last level. If the
* first level and last level are the same, the enumerator traverses tiles in the first level. When the level set is
* exhausted, nil is returned. Callers cannot reset an enumerator after it has exhausted the tiles in its level set. To
* enumerate a collection again, create a new enumerator.
*
* Calls to nextObject should be wrapped in a local autorelease pool. Each call to nextObject results in an autoreleased
* object and the overhead of the autorelease information can be substantial when enumerating the tiles of a level set.
*
* This retains the level set during enumeration. When the enumeration is exhausted, the level set is released.
*/
@interface WWLevelSetEnumerator : NSEnumerator
{
@protected
    // Intersection of the level set sector and the requested sector.
    WWSector* coverageSector;
    // Current level, row and column in the level set.
    WWTileKey* tileKey;
    int level;
    int row;
    int col;
    // Row and column limits for the coverage sector in the current level.
    int firstRow;
    int lastRow;
    int firstCol;
    int lastCol;
}

/// The level set to enumerate. This retains the level set during enumeration and releases it when the enumeration is
/// exhausted.
@property (nonatomic, readonly) WWLevelSet* levelSet;

/// The sector to enumerate.
@property (nonatomic, readonly) WWSector* sector;

// The level number indicating the first level to enumerate.
@property (nonatomic, readonly) int firstLevel;

// The level number indicating the last level to enumerate.
@property (nonatomic, readonly) int lastLevel;

/// @name Initializing Level Set Enumerators

/**
* Initializes a level set enumerator with the specified level set, sector and levels.
*
* This retains the level set during enumeration and releases it when the enumeration is exhausted.
*
* @param levelSet The level set to enumerate.
* @param sector The sector to enumerate.
* @param firstLevel The level number indicating the first level to enumerate.
* @param lastLevel The level number indicating the last level to enumerate.
*
* @return This enumerator, initialized to the specified level set, sector and levels.
*/
- (WWLevelSetEnumerator*) initWithLevelSet:(WWLevelSet*)levelSet
                                    sector:(WWSector*)sector
                                firstLevel:(int)firstLevel
                                 lastLevel:(int)lastLevel;

/// @name Methods of Interest Only to Subclasses

/**
* Indicates that this level set enumerator has traversed to the next level in the level set.
*
* This sets the row and column limits to those appropriate for the specified level, sets the current row and column to
* the first row and column within those limits, and sets the current level to the specified level.
*
* @param levelNumber The next level number.
*/
- (void) nextLevel:(int)levelNumber;

@end