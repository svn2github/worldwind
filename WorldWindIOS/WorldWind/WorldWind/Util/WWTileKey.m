/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "WorldWind/Util/WWTileKey.h"
#import "WorldWind/WWLog.h"

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

    hash = (NSUInteger) _levelNumber;
    hash = 31 * hash + _row;
    hash = 31 * hash + _column;

    return self;
}

- (id) copyWithZone:(NSZone*)zone
{
    return [[[self class] alloc] initWithLevelNumber:_levelNumber row:_row column:_column];
}

- (BOOL) isEqual:(id)anObject
{
    if (anObject == nil)
        return NO;

    if ([self class] != [anObject class])
        return NO;

    WWTileKey* other = (WWTileKey*) anObject;

    return _levelNumber == other->_levelNumber && _row == other->_row && _column == other->_column;
}

- (NSUInteger) hash
{
    return hash;
}

@end