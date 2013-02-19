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

// STRINGIFY is used in the shader files.
#define STRINGIFY(A) #A
#import "WorldWind/Shaders/Simple.vert"
#import "WorldWind/Shaders/Simple.frag"
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

    [self makeGpuProgram];
    if (_gpuProgram == nil)
        return;

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
            [_gpuProgram loadUniformColor:@"color" color:wireframeColor];
            [tile renderWireframe:dc];
            [_gpuProgram loadUniformColor:@"color" color:outlineColor];
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
    [_gpuProgram bind];
    [dc setCurrentProgram:_gpuProgram];
    glDepthMask(false); // Disable depth buffer writes. The diagnostics should not occlude any other objects.
}

- (void) endRendering:(WWDrawContext*)dc
{
    [dc setCurrentProgram:nil];
    glUseProgram(0);
    glDepthMask(true); // Re-enable depth buffer writes.
}

- (void) makeGpuProgram
{
    if (_gpuProgram != nil)
        return;

    @try
    {
        _gpuProgram = [[WWGpuProgram alloc] initWithShaderSource:SimpleVertexShader
                                                  fragmentShader:SimpleFragmentShader];
    }
    @catch (NSException* exception)
    {
        WWLogE(@"making GPU program", exception);
    }
}

@end