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
#import "WorldWind/Render/WWGpuProgram.h"
#import "WorldWind/Util/WWColor.h"

@implementation WWShowTessellationLayer

- (WWShowTessellationLayer*) init
{
    self = [super init];

    return self;
}

- (void) doRender:(WWDrawContext*)dc
{
    if (dc == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Draw context is nil")
    }

    WWTerrainTileList* surfaceTiles = [dc surfaceGeometry];
    if (surfaceTiles == nil || [surfaceTiles count] == 0)
        return;

    WWGpuProgram* program = [dc defaultProgram];

    WWColor* wireframeColor = [[WWColor alloc] initWithR:1 g:1 b:1 a:1];
    WWColor* outlineColor = [[WWColor alloc] initWithR:1 g:0 b:0 a:1];

    [self beginRendering:dc];

    @try
    {
        [surfaceTiles beginRendering:dc];

        NSUInteger count = [surfaceTiles count];
        for (NSUInteger i = 0; i < count; i++)
        {
            WWTerrainTile* tile = [surfaceTiles objectAtIndex:i];

            [tile beginRendering:dc];
            [program loadUniformColor:@"color" color:wireframeColor];
            [tile renderWireframe:dc];
            [program loadUniformColor:@"color" color:outlineColor];
            [tile renderOutline:dc];
            [tile endRendering:dc];
        }
    }
    @finally
    {
        [surfaceTiles endRendering:dc];
        [self endRendering:dc];
    }

}

- (void) beginRendering:(WWDrawContext*)dc
{
    glDepthMask(false); // Disable depth buffer writes. The diagnostics should not occlude any other objects.
}

- (void) endRendering:(WWDrawContext*)dc
{
    glDepthMask(true); // Re-enable depth buffer writes.
}

@end