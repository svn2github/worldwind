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
#import "WorldWind/Util/WWUtil.h"
#import "WorldWind/Util/WWMath.h"
#import "WorldWind/WWLog.h"

@implementation WWSurfaceTileRenderer

- (WWSurfaceTileRenderer*) init
{
    self = [super init];

    programKey = [WWUtil generateUUID];
    tileCoordMatrix = [[WWMatrix alloc] initWithIdentity];
    textureMatrix = [[WWMatrix alloc] initWithIdentity];

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

    NSUInteger tileCount = 0;
    [self beginRendering:dc opacity:opacity];
    [terrainTiles beginRendering:dc];
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

    NSUInteger tileCount = 0;
    [self beginRendering:dc opacity:opacity];
    [terrainTiles beginRendering:dc];
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

- (void) beginRendering:(WWDrawContext*)dc opacity:(float)opacity
{
    [dc bindProgramForKey:[WWSurfaceTileRendererProgram programKey] class:[WWSurfaceTileRendererProgram class]];
    [(WWSurfaceTileRendererProgram*) [dc currentProgram] loadOpacity:opacity];
}

- (void) endRendering:(WWDrawContext*)dc
{
    [dc bindProgram:nil];
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
    WWSurfaceTileRendererProgram* program = (WWSurfaceTileRendererProgram*) [dc currentProgram];

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
    [program loadTileCoordMatrix:tileCoordMatrix];

    [textureMatrix setToUnitYFlip];
    [surfaceTile applyInternalTransform:dc matrix:textureMatrix];
    [textureMatrix multiplyMatrix:tileCoordMatrix];
    [program loadTextureMatrix:textureMatrix];
}

@end