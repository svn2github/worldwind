/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Terrain/WWTerrainTileList.h"
#import "WorldWind/WWLog.h"
#import "WorldWind/Terrain/WWTessellator.h"

@implementation WWTerrainTileList

- (WWTerrainTileList*) initWithTessellator:(WWTessellator*) tessellator
{
    if (tessellator == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Tessellator is nil")
    }

    self = [super init];

    _tessellator = tessellator;
    self->tiles = [[NSMutableArray alloc] init];

    return self;
}

- (void) addTile:(WWTerrainTile*) tile
{
    if (tile == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Terrain tile is nil")
    }

    [self->tiles addObject:tile];
}

- (WWTerrainTile*) objectAtIndex:(NSUInteger) index
{
    return [self->tiles objectAtIndex:index];
}

- (NSUInteger) count
{
    return [self->tiles count];
}

- (void) beginRendering:(WWDrawContext*) dc
{
    if (dc == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Draw context is nil")
    }

    [_tessellator beginRendering:dc];
}

- (void) endRendering:(WWDrawContext*) dc
{
    if (dc == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Draw context is nil")
    }

    [_tessellator endRendering:dc];
}

@end
