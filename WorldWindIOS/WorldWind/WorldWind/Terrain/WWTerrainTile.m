/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Terrain/WWTerrainTile.h"
#import "WorldWInd/WWLog.h"

@implementation WWTerrainTile

- (WWTerrainTile*) initWithSector:(WWSector *)sector
                            level:(int)level
                              row:(int)row
                           column:(int)column
                      tessellator:(WWTessellator *)tessellator
{
    if (tessellator == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Tessellator is nil")
    }
    
    self = [super initWithSector:sector level:level row:row column:column];
    
    _tessellator = tessellator;
    
    return self;
}

- (void) beginRendering:(WWDrawContext *)dc
{
    
}

- (void) endRendering:(WWDrawContext *)dc
{
    
}

- (void) render:(WWDrawContext *)dc
{
    
}

@end
