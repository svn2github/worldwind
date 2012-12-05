/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "WorldWind/Layer/WWShowTessellationLayer.h"
#import "WorldWind/Render/WWDrawContext.h"
#import "WorldWind/Terrain/WWTerrainTile.h"
#import "WorldWind/Terrain/WWTerrainTileList.h"
#import "WorldWind/WWLog.h"

@implementation WWShowTessellationLayer

- (void) render:(WWDrawContext*)dc
{
    if (dc == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Draw context is nil")
    }

    WWTerrainTileList* surfaceTiles = [dc surfaceGeometry];
    if (surfaceTiles == nil || [surfaceTiles count] == 0)
        return;

    [surfaceTiles beginRendering:dc];

    NSUInteger count = [surfaceTiles count];
    for (NSUInteger i = 0; i < count; i++)
    {
        WWTerrainTile* tile = [surfaceTiles objectAtIndex:i];

        [tile beginRendering:dc];
        [tile renderWireframe:dc];
        [tile endRendering:dc];
    }

    [surfaceTiles endRendering:dc];

}

@end