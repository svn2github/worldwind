/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Terrain/WWTerrainTile.h"
#import "WorldWInd/WWLog.h"

@implementation WWTerrainTile

- (WWTerrainTile*) initWithSector:(WWSector *)sector
                            level:(WWLevel *)level
                              row:(int)row
                           column:(int)column
                      tessellator:(WWTessellator *)tessellator
{
    if (sector == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Sector is nil")
    }
    
    if (level == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Level is nil")
    }
    
    if (tessellator == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Tessellator is nil")
    }
    
    if (row < 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Row is less than 0")
    }
    
    if (column < 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Column is less than 0")
    }

    self = [super initWithSector:sector level:level row:row column:column];
    
    _tessellator = tessellator;
    
    return self;
}

@end
