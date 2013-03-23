/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "WorldWind/Util/WWTileKey.h"
#import "WorldWind/WWLog.h"

#define TILE_HASH(l, r, c) (((0x3FFF & (NSUInteger) (c)) << 18) | ((0x3FFF & (NSUInteger) (r)) << 4) | (0xF & (NSUInteger) (l)))

@implementation WWTileKey

- (WWTileKey*) initWithLevelNumber:(int)levelNumber row:(int)row column:(int)column
{
    if (levelNumber < 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Level number is less than 0")
    }

    if (row < 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Tile row is less than 0")
    }

    if (column < 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Tile column is less than 0")
    }

    self = [super init];

    _levelNumber = levelNumber;
    _row = row;
    _column = column;

    hash = TILE_HASH(_levelNumber, _row, _column);

    return self;
}

- (void) setLevelNumber:(int)levelNumber row:(int)row column:(int)column
{
    _levelNumber = levelNumber;
    _row = row;
    _column = column;

    hash = TILE_HASH(_levelNumber, _row, _column);
}

- (id) copyWithZone:(NSZone*)zone
{
    return [[WWTileKey alloc] initWithLevelNumber:_levelNumber row:_row column:_column];
}

- (BOOL) isEqual:(id __unsafe_unretained)anObject // Suppress unnecessary ARC retain/release calls.
{
    if (anObject == nil || [anObject class] != [WWTileKey class])
    {
        return NO;
    }

    WWTileKey* __unsafe_unretained other = (WWTileKey*) anObject; // Suppress unnecessary ARC retain/release calls.
    return _levelNumber == other->_levelNumber && _row == other->_row && _column == other->_column;
}

- (NSUInteger) hash
{
    return hash;
}

@end