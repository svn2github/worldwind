/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Util/WWLevelSet.h"
#import "WorldWind/Util/WWTile.h"
#import "WorldWind/Util/WWLevel.h"
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
    if (levelNumber >= [self->levels count])
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

- (int) numColumnsInLevel:(WWLevel*)level
{
    int levelDelta = [level levelNumber] - [[self firstLevel] levelNumber];
    double twoToTheN = pow(2, levelDelta);

    return (int) twoToTheN * _numLevelZeroColumns;
}

@end