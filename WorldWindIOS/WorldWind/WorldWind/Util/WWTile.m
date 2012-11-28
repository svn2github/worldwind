/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Util/WWTile.h"
#import "WorldWind/Util/WWLevel.h"
#import "WorldWind/WWLog.h"

@implementation WWTile

- (WWTile*) initWithSector:(WWSector *)sector level:(WWLevel*)level row:(int)row column:(int)column
{
    if (sector == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Tile sector is nil")
    }
    
    if (level == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Tile level is nil")
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

    _sector = sector;
    _level = level;
    _row = row;
    _column = column;
    
    return self;
}

@end
