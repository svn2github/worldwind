/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Terrain/WWTerrainTile.h"
#import "WorldWind/Terrain/WWTessellator.h"
#import "WorldWind/WWLog.h"

@implementation WWTerrainTile

- (WWTerrainTile*) initWithSector:(WWSector*) sector
                            level:(WWLevel*) level
                              row:(int) row
                           column:(int) column
                      tessellator:(WWTessellator*) tessellator
{
    // superclass checks sector, level, row and column arguments.

    if (tessellator == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Tessellator is nil")
    }

    self = [super initWithSector:sector level:level row:row column:column];

    _tessellator = tessellator;

    _numLonCells = 5;
    _numLatCells = 5;

    //TODO: set the resolution (if that property is still necessary).

    return self;
}

- (void) beginRendering:(WWDrawContext*) dc
{
    [_tessellator beginRendering:dc tile:self];
}

- (void) endRendering:(WWDrawContext*) dc
{
    [_tessellator endRendering:dc tile:self];
}

- (void) render:(WWDrawContext*) dc
{
    [_tessellator render:dc tile:self];
}

- (void) renderWireframe:(WWDrawContext*) dc
{
    [_tessellator renderWireFrame:dc tile:self];
}
@end
