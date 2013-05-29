/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "WorldWind/Util/WWLevelSetEnumerator.h"
#import "WorldWind/Geometry/WWLocation.h"
#import "WorldWind/Geometry/WWSector.h"
#import "WorldWind/Util/WWLevel.h"
#import "WorldWind/Util/WWLevelSet.h"
#import "WorldWind/Util/WWTile.h"
#import "WorldWind/Util/WWTileKey.h"
#import "WorldWind/WWLog.h"

@implementation WWLevelSetEnumerator

- (WWLevelSetEnumerator*) initWithLevelSet:(WWLevelSet*)levelSet
                                    sector:(WWSector*)sector
                                firstLevel:(int)firstLevel
                                 lastLevel:(int)lastLevel
{
    if (sector == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Sector is nil")
    }

    if (levelSet == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Level set is nil")
    }

    if (firstLevel < 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"First level is invalid")
    }

    if (lastLevel < firstLevel || lastLevel > [[levelSet lastLevel] levelNumber])
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Last level is invalid")
    }

    self = [super init];

    // Intersect the specified sector with the level set's coverage area. This avoids attempting to enumerate tiles that
    // are outside the coverage area.
    coverageSector = [[WWSector alloc] initWithSector:sector];
    [coverageSector intersection:[levelSet sector]];

    _levelSet = levelSet;
    _sector = sector;
    _firstLevel = firstLevel;
    _lastLevel = lastLevel;

    return self;
}

- (id) nextObject
{
    if (tileKey == nil) // First row/column in the first level.
    {
        [self nextLevel:_firstLevel];
        return (tileKey = [[WWTileKey alloc] initWithLevelNumber:level row:row column:col]);
    }
    else if (col < lastCol) // Increment to the next column.
    {
        col++;
        return [tileKey setLevelNumber:level row:row column:col];
    }
    else if (row < lastRow) // Reached the last column in the row, increment to the next row and reset the column.
    {
        row++;
        col = firstCol;
        return [tileKey setLevelNumber:level row:row column:col];
    }
    else if (level < _lastLevel) // Reached the last row/column in the level; increment to the next level and reset row/column.
    {
        [self nextLevel:level + 1];
        return [tileKey setLevelNumber:level row:row column:col];
    }
    else // Reached the last row/column in the last level.
    {
        _levelSet = nil; // Release the strong reference to the parent level set.
        return nil;
    }
}

- (void) nextLevel:(int)levelNumber
{
    WWLevel* levelObject = [_levelSet level:levelNumber];
    double deltaLat = [[levelObject tileDelta] latitude];
    double deltaLon = [[levelObject tileDelta] longitude];

    firstRow = [WWTile computeRow:deltaLat latitude:[coverageSector minLatitude]];
    lastRow = [WWTile computeRow:deltaLat latitude:[coverageSector maxLatitude]];
    firstCol = [WWTile computeColumn:deltaLon longitude:[coverageSector minLongitude]];
    lastCol = [WWTile computeColumn:deltaLon longitude:[coverageSector maxLongitude]];

    level = levelNumber;
    row = firstRow;
    col = firstCol;
}

@end