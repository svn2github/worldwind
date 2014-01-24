/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Render/WWSurfaceTileRenderer.h"
#import "WorldWind/Geometry/WWMatrix.h"
#import "WorldWind/Geometry/WWSector.h"
#import "WorldWind/Render/WWDrawContext.h"
#import "WorldWind/Render/WWGpuProgram.h"
#import "WorldWind/Render/WWSurfaceTile.h"
#import "WorldWind/Shaders/WWSurfaceTileRendererProgram.h"
#import "WorldWind/Terrain/WWTerrainTile.h"
#import "WorldWind/Terrain/WWTerrainTileList.h"
#import "WorldWind/Terrain/WWTessellator.h"
#import "WorldWind/Util/WWFrameStatistics.h"
#import "WorldWind/Util/WWMath.h"
#import "WorldWind/WWLog.h"

@implementation WWSurfaceTileRenderer

- (WWSurfaceTileRenderer*) init
{
    self = [super init];

    texMaskMatrix = [[WWMatrix alloc] initWithIdentity];
    texSamplerMatrix = [[WWMatrix alloc] initWithIdentity];

    return self;
}

- (void) renderTile:(WWDrawContext*)dc surfaceTile:(id <WWSurfaceTile>)surfaceTile opacity:(float)opacity
{
    if (dc == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Draw context is nil")
    }

    if (surfaceTile == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Surface tile is nil")
    }

    WWTerrainTileList* terrainTiles = [dc surfaceGeometry];
    WWTessellator* tess = [terrainTiles tessellator];
    if (terrainTiles == nil || tess == nil)
    {
        WWLog(@"No surface geometry");
        return;
    }

    NSUInteger tileCount = 0;
    [self beginRendering:dc opacity:opacity];
    [tess beginRendering:dc];
    @try
    {
        if ([surfaceTile bind:dc])
        {
            WWSector* __unsafe_unretained surfaceTileSector = [surfaceTile sector];

            for (NSUInteger i = 0; i < [terrainTiles count]; i++)
            {
                WWTerrainTile* __unsafe_unretained terrainTile = [terrainTiles objectAtIndex:i];
                if ([[terrainTile sector] intersects:surfaceTileSector])
                {
                    [tess beginRendering:dc tile:terrainTile];
                    @try
                    {
                        [self applyTileState:dc terrainTile:terrainTile surfaceTile:surfaceTile];
                        [tess render:dc tile:terrainTile];
                        tileCount++;
                    }
                    @finally
                    {
                        [tess endRendering:dc tile:terrainTile];
                    }
                }
            }
        }
    }
    @finally
    {
        [tess endRendering:dc];
        [self endRendering:dc];
        [[dc frameStatistics] incrementRenderedTileCount:tileCount];
    }
}

- (void) renderTiles:(WWDrawContext*)dc surfaceTiles:(NSArray*)surfaceTiles opacity:(float)opacity
{
    if (dc == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Draw context is nil")
    }

    if (surfaceTiles == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Surface tiles list is nil")
    }

    WWTerrainTileList* terrainTiles = [dc surfaceGeometry];
    WWTessellator* tess = [terrainTiles tessellator];
    if (terrainTiles == nil || tess == nil)
    {
        WWLog(@"No surface geometry");
        return;
    }

    NSUInteger tileCount = 0;
    [self beginRendering:dc opacity:opacity];
    [tess beginRendering:dc];
    @try
    {
        for (NSUInteger i = 0; i < [terrainTiles count]; i++)
        {
            WWTerrainTile* __unsafe_unretained terrainTile = [terrainTiles objectAtIndex:i];
            WWSector* __unsafe_unretained terrainTileSector = [terrainTile sector];
            [tess beginRendering:dc tile:terrainTile];
            @try
            {
                for (id <WWSurfaceTile> __unsafe_unretained surfaceTile in surfaceTiles)
                {
                    if ([[surfaceTile sector] intersects:terrainTileSector] && [surfaceTile bind:dc])
                    {
                        [self applyTileState:dc terrainTile:terrainTile surfaceTile:surfaceTile];
                        [tess render:dc tile:terrainTile];
                        tileCount++;
                    }
                }
            }
            @finally
            {
                [tess endRendering:dc tile:terrainTile];
            }
        }
    }
    @finally
    {
        [tess endRendering:dc];
        [self endRendering:dc];
        [[dc frameStatistics] incrementRenderedTileCount:tileCount];
    }
}

- (void) beginRendering:(WWDrawContext* __unsafe_unretained)dc opacity:(float)opacity
{
    [dc bindProgramForKey:[WWSurfaceTileRendererProgram programKey] class:[WWSurfaceTileRendererProgram class]];

    WWSurfaceTileRendererProgram* __unsafe_unretained program = (WWSurfaceTileRendererProgram*) [dc currentProgram];
    [program loadTexSampler:GL_TEXTURE0];
    [program loadOpacity:opacity];
}

- (void) endRendering:(WWDrawContext* __unsafe_unretained)dc
{
    [dc bindProgram:nil];
}

- (void) applyTileState:(WWDrawContext* __unsafe_unretained)dc terrainTile:(WWTerrainTile* __unsafe_unretained)terrainTile surfaceTile:(id <WWSurfaceTile> __unsafe_unretained)surfaceTile
{
    WWSurfaceTileRendererProgram* __unsafe_unretained program = (WWSurfaceTileRendererProgram*) [dc currentProgram];

    WWSector* __unsafe_unretained terrainSector = [terrainTile sector];
    double terrainDeltaLon = RADIANS([terrainSector deltaLon]);
    double terrainDeltaLat = RADIANS([terrainSector deltaLat]);

    WWSector* __unsafe_unretained surfaceSector = [surfaceTile sector];
    double surfaceDeltaLon = RADIANS([surfaceSector deltaLon]);
    double surfaceDeltaLat = RADIANS([surfaceSector deltaLat]);

    double sScale = surfaceDeltaLon > 0 ? terrainDeltaLon / surfaceDeltaLon : 1;
    double tScale = surfaceDeltaLat > 0 ? terrainDeltaLat / surfaceDeltaLat : 1;
    double sTrans = -([surfaceSector minLongitudeRadians] - [terrainSector minLongitudeRadians]) / terrainDeltaLon;
    double tTrans = -([surfaceSector minLatitudeRadians] - [terrainSector minLatitudeRadians]) / terrainDeltaLat;

    [texMaskMatrix set:sScale m01:0 m02:0 m03:sScale * sTrans
            m10:0 m11:tScale m12:0 m13:tScale * tTrans
            m20:0 m21:0 m22:1 m23:0
            m30:0 m31:0 m32:0 m33:1];

    [texSamplerMatrix setToUnitYFlip];
    [surfaceTile applyInternalTransform:dc matrix:texSamplerMatrix];
    [texSamplerMatrix multiplyMatrix:texMaskMatrix];

    [program loadTexSamplerMatrix:texSamplerMatrix];
    [program loadTexMaskMatrix:texMaskMatrix];
}

@end