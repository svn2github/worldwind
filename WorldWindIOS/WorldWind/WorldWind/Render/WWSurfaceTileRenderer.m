/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Render/WWSurfaceTileRenderer.h"
#import "WorldWind/Render/WWGpuProgram.h"
#import "WorldWind/Render/WWDrawContext.h"
#import "WorldWind/Terrain/WWTerrainTile.h"
#import "WorldWind/Terrain/WWTerrainTileList.h"
#import "WorldWind/Geometry/WWMatrix.h"
#import "WorldWind/Render/WWSurfaceTile.h"
#import "WorldWind/Geometry/WWSector.h"
#import "WorldWind/Util/WWGpuResourceCache.h"
#import "WorldWind/Util/WWUtil.h"
#import "WorldWind/WWLog.h"
#import "WorldWind/Util/WWMath.h"

// STRINGIFY is used in the shader files.
#define STRINGIFY(A) #A
#import "WorldWind/Shaders/SurfaceTileRenderer.vert"
#import "WorldWind/Shaders/SurfaceTileRenderer.frag"

@implementation WWSurfaceTileRenderer

- (WWSurfaceTileRenderer*) init
{
    self = [super init];

    programKey = [WWUtil generateUUID];
    tileCoordMatrix = [[WWMatrix alloc] initWithIdentity];
    texCoordMatrix = [[WWMatrix alloc] initWithIdentity];

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
    if (terrainTiles == nil)
    {
        WWLog(@"No surface geometry");
        return;
    }

    WWGpuProgram* program = [self gpuProgram:dc];
    [self beginRendering:dc program:program opacity:opacity];
    [terrainTiles beginRendering:dc];
    NSUInteger tileCount = 0;

    @try
    {
        if ([surfaceTile bind:dc])
        {
            [self drawIntersectingTiles:dc surfaceTile:surfaceTile terrainTiles:terrainTiles tileCount:&tileCount];
        }
    }
    @finally
    {
        [terrainTiles endRendering:dc];
        [self endRendering:dc];
        [dc setNumRenderedTiles:[dc numRenderedTiles] + tileCount];
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
    if (terrainTiles == nil)
    {
        WWLog(@"No surface geometry");
        return;
    }

    WWGpuProgram* program = [self gpuProgram:dc];
    [self beginRendering:dc program:program opacity:opacity];
    [terrainTiles beginRendering:dc];
    NSUInteger tileCount = 0;

    @try
    {
        for (NSUInteger i = 0; i < [terrainTiles count]; i++)
        {
            WWTerrainTile* terrainTile = [terrainTiles objectAtIndex:i];
            [self drawIntersectingTiles:dc terrainTile:terrainTile surfaceTiles:surfaceTiles tileCount:&tileCount];
        }
    }
    @finally
    {
        [terrainTiles endRendering:dc];
        [self endRendering:dc];
        [dc setNumRenderedTiles:[dc numRenderedTiles] + tileCount];
    }
}

- (void) beginRendering:(WWDrawContext*)dc program:(WWGpuProgram*)program opacity:(float)opacity
{
    [program bind];
    [dc setCurrentProgram:program];

    [program loadUniformSampler:@"tileTexture" value:0];
    [program loadUniformFloat:@"opacity" value:opacity];
}

- (void) endRendering:(WWDrawContext*)dc
{
    glUseProgram(0);
    [dc setCurrentProgram:nil];
}

- (void) drawIntersectingTiles:(WWDrawContext*)dc
                   terrainTile:(WWTerrainTile*)terrainTile
                  surfaceTiles:(NSArray*)surfaceTiles
                     tileCount:(NSUInteger*)tileCount
{
    WWSector* terrainTileSector = [terrainTile sector];

    [terrainTile beginRendering:dc];
    @try
    {
        for (id <WWSurfaceTile> surfaceTile in surfaceTiles)
        {
            if ([[surfaceTile sector] intersects:terrainTileSector] && [surfaceTile bind:dc])
            {
                [self applyTileState:dc terrainTile:terrainTile surfaceTile:surfaceTile];
                [terrainTile render:dc];
                (*tileCount)++;
            }
        }
    }
    @finally
    {
        [terrainTile endRendering:dc];
    }
}

- (void) drawIntersectingTiles:(WWDrawContext*)dc
                   surfaceTile:(id <WWSurfaceTile>)surfaceTile
                  terrainTiles:(WWTerrainTileList*)terrainTiles
                     tileCount:(NSUInteger*)tileCount
{
    WWSector* surfaceTileSector = [surfaceTile sector];

    for (NSUInteger i = 0; i < [terrainTiles count]; i++)
    {
        WWTerrainTile* terrainTile = [terrainTiles objectAtIndex:i];

        if ([[terrainTile sector] intersects:surfaceTileSector])
        {
            [terrainTile beginRendering:dc];
            @try
            {
                [self applyTileState:dc terrainTile:terrainTile surfaceTile:surfaceTile];
                [terrainTile render:dc];
                (*tileCount)++;
            }
            @finally
            {
                [terrainTile endRendering:dc];
            }
        }
    }
}

- (void) applyTileState:(WWDrawContext*)dc terrainTile:(WWTerrainTile*)terrainTile surfaceTile:(id <WWSurfaceTile>)surfaceTile
{
    WWGpuProgram* prog = [dc currentProgram];

    WWSector* terrainSector = [terrainTile sector];
    double terrainDeltaLon = RADIANS([terrainSector deltaLon]);
    double terrainDeltaLat = RADIANS([terrainSector deltaLat]);

    WWSector* surfaceSector = [surfaceTile sector];
    double surfaceDeltaLon = RADIANS([surfaceSector deltaLon]);
    double surfaceDeltaLat = RADIANS([surfaceSector deltaLat]);

    double sScale = surfaceDeltaLon > 0 ? terrainDeltaLon / surfaceDeltaLon : 1;
    double tScale = surfaceDeltaLat > 0 ? terrainDeltaLat / surfaceDeltaLat : 1;
    double sTrans = -([surfaceSector minLongitudeRadians] - [terrainSector minLongitudeRadians]) / terrainDeltaLon;
    double tTrans = -([surfaceSector minLatitudeRadians] - [terrainSector minLatitudeRadians]) / terrainDeltaLat;

    [tileCoordMatrix set:sScale m01:0 m02:0 m03:sScale * sTrans
            m10:0 m11:tScale m12:0 m13:tScale * tTrans
            m20:0 m21:0 m22:1 m23:0
            m30:0 m31:0 m32:0 m33:1];
    [prog loadUniformMatrix:@"tileCoordMatrix" matrix:tileCoordMatrix];

    [texCoordMatrix setToUnitYFlip];
    [surfaceTile applyInternalTransform:dc matrix:texCoordMatrix];
    [texCoordMatrix multiplyMatrix:tileCoordMatrix];
    [prog loadUniformMatrix:@"texCoordMatrix" matrix:texCoordMatrix];
}

- (WWGpuProgram*) gpuProgram:(WWDrawContext*)dc
{
    WWGpuProgram* program = [[dc gpuResourceCache] getProgramForKey:programKey];
    if (program != nil)
        return program;

    @try
    {
        program = [[WWGpuProgram alloc] initWithShaderSource:SurfaceTileRendererVertexShader
                                              fragmentShader:SurfaceTileRendererFragmentShader];
        [[dc gpuResourceCache] putProgram:program forKey:programKey];
    }
    @catch (NSException* exception)
    {
        WWLogE(@"making GPU program", exception);
    }

    return program;
}

@end