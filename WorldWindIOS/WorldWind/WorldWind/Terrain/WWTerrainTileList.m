/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Terrain/WWTerrainTileList.h"
#import "WorldWind/WWLog.h"

@implementation WWTerrainTileList

- (WWTerrainTileList*) initWithTessellator:(WWTessellator *)tessellator
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

- (void) addTile:(WWTerrainTile *)tile
{
    [self->tiles addObject:tile];
}

- (WWTerrainTile*) objectAtIndex:(int)index
{
    return [self->tiles objectAtIndex:index];
}

- (NSUInteger) count
{
    return [self->tiles count];
}

- (void) beginRendering:(WWDrawContext *)dc
{
    
}

- (void) endRendering:(WWDrawContext *)dc
{
    
}

@end
