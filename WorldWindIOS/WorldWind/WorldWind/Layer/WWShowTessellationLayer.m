/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "WorldWind/Layer/WWShowTessellationLayer.h"
#import "WorldWind/Render/WWDrawContext.h"
#import "WorldWind/Render/WWGpuProgram.h"
#import "WorldWind/Shaders/WWBasicProgram.h"
#import "WorldWind/Terrain/WWTerrainTile.h"
#import "WorldWind/Terrain/WWTerrainTileList.h"
#import "WorldWind/Terrain/WWTessellator.h"
#import "WorldWind/Util/WWColor.h"
#import "WorldWind/WWLog.h"

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
    WWTessellator* tess = [surfaceTiles tessellator];
    if (surfaceTiles == nil || tess == nil)
    {
        return;
    }

    WWColor* wireframeColor = [[WWColor alloc] initWithR:1 g:1 b:1 a:1];
    WWColor* outlineColor = [[WWColor alloc] initWithR:1 g:0 b:0 a:1];

    [self beginRendering:dc];
    @try
    {
        [tess beginRendering:dc];
        WWBasicProgram* program = (WWBasicProgram*) [dc currentProgram];

        NSUInteger count = [surfaceTiles count];
        for (NSUInteger i = 0; i < count; i++)
        {
            WWTerrainTile* tile = [surfaceTiles objectAtIndex:i];

            [tess beginRendering:dc tile:tile];
            [program loadColor:wireframeColor];
            [tess renderWireframe:dc tile:tile];
            [program loadColor:outlineColor];
            [tess renderOutline:dc tile:tile];
            [tess endRendering:dc tile:tile];
        }
    }
    @finally
    {
        [tess endRendering:dc];
        [self endRendering:dc];
    }

}

- (void) beginRendering:(WWDrawContext*)dc
{
    [dc bindProgramForKey:[WWBasicProgram programKey] class:[WWBasicProgram class]];
    glDepthMask(GL_FALSE); // Disable depth buffer writes. The diagnostics should not occlude any other objects.
}

- (void) endRendering:(WWDrawContext*)dc
{
    [dc bindProgram:nil];
    glDepthMask(GL_TRUE); // Re-enable depth buffer writes.
}

@end