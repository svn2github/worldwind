/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Util/WWLevelSet.h"
#import "WorldWind/Util/WWTile.h"
#import "WorldWind/Util/WWLevel.h"
#import "WorldWind/Util/WWLevelSetEnumerator.h"
#import "WorldWind/Geometry/WWSector.h"
#import "WorldWind/Geometry/WWLocation.h"
#import "WorldWind/WWLog.h"

#define DEFAULT_TILE_SIZE 256

@implementation WWLevelSet

- (WWLevelSet*) initWithSector:(WWSector*)sector
                levelZeroDelta:(WWLocation*)levelZeroDelta
                     numLevels:(int)numLevels
{
    if (sector == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Sector is nil")
    }

    if (levelZeroDelta == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Level 0 delta is nil")
    }

    if (numLevels < 1)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Number of levels is less than 1")
    }

    return [self initWithSector:sector
                 levelZeroDelta:levelZeroDelta
                      numLevels:numLevels
                      tileWidth:DEFAULT_TILE_SIZE
                     tileHeight:DEFAULT_TILE_SIZE];
}

- (WWLevelSet*) initWithSector:(WWSector*)sector
                levelZeroDelta:(WWLocation*)levelZeroDelta
                     numLevels:(int)numLevels
                     tileWidth:(int)tileWidth
                    tileHeight:(int)tileHeight
{
    if (sector == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Sector is nil")
    }

    if (levelZeroDelta == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Level 0 delta is nil")
    }

    if (numLevels < 1)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Number of levels is less than 1")
    }

    if (tileWidth < 1 || tileHeight < 1)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Tile width or height is less than 1")
    }

    self = [super init];

    if (self != nil)
    {
        _sector = sector;
        _levelZeroDelta = levelZeroDelta;
        _numLevels = numLevels;
        _tileWidth = tileWidth;
        _tileHeight = tileHeight;

        int firstLevelZeroColumn = [WWTile computeColumn:[_levelZeroDelta longitude] longitude:[_sector minLongitude]];
        int lastLevelZeroColumn = [WWTile computeColumn:[_levelZeroDelta longitude] longitude:[_sector maxLongitude]];
        _numLevelZeroColumns = MAX(1, lastLevelZeroColumn - firstLevelZeroColumn + 1);

        self->levels = [[NSMutableArray alloc] init];

        for (int i = 0; i < _numLevels; i++)
        {
            double n = pow(2, i);
            double latDelta = [_levelZeroDelta latitude] / n;
            double lonDelta = [_levelZeroDelta longitude] / n;
            WWLocation* tileDelta = [[WWLocation alloc] initWithDegreesLatitude:latDelta longitude:lonDelta];

            WWLevel* level = [[WWLevel alloc] initWithLevelNumber:i tileDelta:tileDelta parent:self];
            [self->levels addObject:level];
        }
    }

    return self;
}

- (WWLevel*) level:(int)levelNumber
{
    if (levelNumber < 0 || levelNumber >= [self->levels count])
    {
        return nil;
    }

    return [self->levels objectAtIndex:(NSUInteger)levelNumber];
}

- (WWLevel*) firstLevel
{
    return [self->levels objectAtIndex:0];
}

- (WWLevel*) lastLevel
{
    return [self->levels lastObject];
}

- (BOOL) isLastLevel:(int)levelNumber
{
    return levelNumber == [self->levels count] - 1;
}

- (WWLevel*) levelForTexelSize:(double)texelSize;
{
    // TODO: Replace this loop with a computation.
    WWLevel* lastLevel = [levels lastObject];

    if ([lastLevel texelSize] >= texelSize)
    {
        return lastLevel; // Can't do any better than the last level.
    }

    for (WWLevel* level in levels)
    {
        if ([level texelSize] <= texelSize)
        {
            return level;
        }
    }

    return lastLevel;
}

- (NSUInteger) tileCountForSector:(WWSector*)sector
{
    if (sector == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Sector is nil")
    }

    return [self tileCountForSector:sector lastLevel:[levels count] - 1];
}

- (NSUInteger) tileCountForSector:(WWSector*)sector lastLevel:(int)lastLevel
{
    if (sector == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Sector is nil")
    }

    if (lastLevel < 0 || lastLevel >= [levels count])
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Last level is invalid")
    }

    // Intersect the specified sector with the level set's coverage area. This avoids attempting to enumerate tiles that
    // are outside the coverage area.
    WWSector* coverageSector = [[WWSector alloc] initWithSector:sector];
    [coverageSector intersection:_sector];
    if ([coverageSector minLatitude] == [coverageSector maxLatitude]
        || [coverageSector minLongitude] == [coverageSector maxLongitude])
        return 0;

    NSUInteger tileCount = 0;

    for (NSUInteger i = 0; i <= lastLevel; i++)
    {
        WWLevel* level = [levels objectAtIndex:i];
        double deltaLat = [[level tileDelta] latitude];
        double deltaLon = [[level tileDelta] longitude];

        int firstRow = [WWTile computeRow:deltaLat latitude:[coverageSector minLatitude]];
        int lastRow = [WWTile computeRow:deltaLat latitude:[coverageSector maxLatitude]];
        int firstCol = [WWTile computeColumn:deltaLon longitude:[coverageSector minLongitude]];
        int lastCol = [WWTile computeColumn:deltaLon longitude:[coverageSector maxLongitude]];

        tileCount += (lastRow - firstRow + 1) * (lastCol - firstCol + 1);
    }

    return tileCount;
}

- (NSEnumerator*) tileEnumeratorForSector:(WWSector*)sector
{
    if (sector == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Sector is nil")
    }

    return [[WWLevelSetEnumerator alloc] initWithLevelSet:self sector:sector firstLevel:0 lastLevel:[levels count] - 1];
}

- (NSEnumerator*) tileEnumeratorForSector:(WWSector*)sector lastLevel:(int)lastLevel
{
    if (sector == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Sector is nil")
    }

    if (lastLevel < 0 || lastLevel >= [levels count])
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Last level is invalid")
    }

    return [[WWLevelSetEnumerator alloc] initWithLevelSet:self sector:sector firstLevel:0 lastLevel:lastLevel];
}

@end