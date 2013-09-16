/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WWElevationShadingLayer.h"
#import "WWLog.h"
#import "WWTerrainTileList.h"
#import "WWDrawContext.h"
#import "WWTessellator.h"
#import "WWBasicProgram.h"
#import "WWElevationShadingProgram.h"

@implementation WWElevationShadingLayer

- (WWElevationShadingLayer*) init
{
    self = [super init];

    [self setDisplayName:@"Elevation Shading"];

    _yellowThreshold = 2000.0;
    _redThreshold = 3000.0;

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

    [dc bindProgramForKey:[WWElevationShadingProgram programKey] class:[WWElevationShadingProgram class]];
    @try
    {
        WWElevationShadingProgram* program = (WWElevationShadingProgram*) [dc currentProgram];
        [program loadYellowThreshold:_yellowThreshold];
        [program loadRedThreshold:_redThreshold];
        [program loadOpacity: [self opacity]];

        [tess setElevationShadingEnabled:YES];
        [tess beginRendering:dc];

        NSUInteger count = [surfaceTiles count];
        for (NSUInteger i = 0; i < count; i++)
        {
            WWTerrainTile* tile = [surfaceTiles objectAtIndex:i];

            [tess beginRendering:dc tile:tile];
            [tess render:dc tile:tile];
            [tess endRendering:dc tile:tile];
        }
    }
    @finally
    {
        [tess endRendering:dc];
        [tess setElevationShadingEnabled:NO];
        [dc bindProgram:nil];
    }
}

@end