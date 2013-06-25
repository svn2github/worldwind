/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Terrain/WWTerrainTileList.h"
#import "WorldWind/WWLog.h"
#import "WorldWind/Terrain/WWTessellator.h"
#import "WorldWind/Geometry/WWVec4.h"
#import "WorldWind/Terrain/WWTerrainTile.h"
#import "WorldWind/Geometry/WWSector.h"

@implementation WWTerrainTileList

- (WWTerrainTileList*) initWithTessellator:(WWTessellator*)tessellator
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

- (void) addTile:(WWTerrainTile*)tile
{
    if (tile == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Terrain tile is nil")
    }

    [self->tiles addObject:tile];
}

- (WWTerrainTile*) objectAtIndex:(NSUInteger)index
{
    return [self->tiles objectAtIndex:index];
}

- (NSUInteger) count
{
    return [self->tiles count];
}

- (void) removeAllTiles
{
    [self->tiles removeAllObjects];
}

- (BOOL) surfacePoint:(double)latitude
            longitude:(double)longitude
               offset:(double)offset
               result:(WWVec4*)result
{
    if (result == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Result pointer is nil")
    }

    for (WWTerrainTile* tile in tiles)
    {
        if ([[tile sector] contains:latitude longitude:longitude])
        {
            [tile surfacePoint:latitude longitude:longitude offset:offset result:result];
            return YES;
        }
    }

    return NO;
}

@end