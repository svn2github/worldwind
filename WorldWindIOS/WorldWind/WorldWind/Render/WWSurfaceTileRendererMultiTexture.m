/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id: WWSurfaceTileRenderer.m 1428 2013-06-11 15:57:38Z tgaskins $
 */

#import "WWSurfaceTileRendererMultiTexture.h"
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

@implementation WWSurfaceTileRendererMultiTexture

- (WWSurfaceTileRendererMultiTexture*) init
{
    self = [super init];

    self->tileCoordMatrix0 = [[WWMatrix alloc] initWithIdentity];
    self->texCoordMatrix0 = [[WWMatrix alloc] initWithIdentity];
    self->tileCoordMatrix1 = [[WWMatrix alloc] initWithIdentity];
    self->texCoordMatrix1 = [[WWMatrix alloc] initWithIdentity];
    self->tileCoordMatrix2 = [[WWMatrix alloc] initWithIdentity];
    self->texCoordMatrix2 = [[WWMatrix alloc] initWithIdentity];
    self->tileCoordMatrix3 = [[WWMatrix alloc] initWithIdentity];
    self->texCoordMatrix3 = [[WWMatrix alloc] initWithIdentity];

    _intersectingTiles = [[NSMutableArray alloc] init];
    _intersectingGeometry = [[NSMutableArray alloc] init];

    self->programKey = [WWUtil generateUUID];

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
    @try
    {
        if ([surfaceTile bind:dc])
        {
            [_intersectingGeometry removeAllObjects];
            [self assembleIntersectingGeometry:surfaceTile terrainTiles:terrainTiles];

            for (NSUInteger i = 0; i < [_intersectingGeometry count]; i++)
            {
                WWTerrainTile* terrainTile = [_intersectingGeometry objectAtIndex:i];

                [terrainTile beginRendering:dc];
                @try
                {
                    [self applyTileState:dc terrainTile:terrainTile surfaceTile:surfaceTile
                         tileCoordMatrixName:@"tileCoordMatrix0" texCoordMatrixName:@"texCoordMatrix0"
                         tileCoordMatrix:tileCoordMatrix0 texCoordMatrix:texCoordMatrix0];
                    [terrainTile render:dc];
//                    [terrainTile renderWireframe:dc];
                }
                @finally
                {
                    [terrainTile endRendering:dc];
                }
            }
        }
    }
    @finally
    {
        [terrainTiles endRendering:dc];
        [self endRendering:dc];
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

    @try
    {
        for (NSUInteger i = 0; i < [terrainTiles count]; i++)
        {
            WWTerrainTile* terrainTile = [terrainTiles objectAtIndex:i];

            [_intersectingTiles removeAllObjects];
            [self assembleIntersectingTiles:terrainTile surfaceTiles:surfaceTiles];
            if ([_intersectingTiles count] == 0)
            {
                continue;
            }

            [terrainTile beginRendering:dc];
            @try
            {
                [dc setNumRenderedTiles:[dc numRenderedTiles] + [_intersectingTiles count]]; // for statistics only
                for (NSUInteger j = 0; j < [_intersectingTiles count];)
                {
                    int numSimultaneousTextures = 0;

                    id <WWSurfaceTile> surfaceTile = [_intersectingTiles objectAtIndex:j];
                    glActiveTexture(GL_TEXTURE0);
                    if ([surfaceTile bind:dc])
                    {
                        ++numSimultaneousTextures;
                        [self applyTileState:dc terrainTile:terrainTile surfaceTile:surfaceTile
                             tileCoordMatrixName:@"tileCoordMatrix0" texCoordMatrixName:@"texCoordMatrix0"
                             tileCoordMatrix:tileCoordMatrix0 texCoordMatrix:texCoordMatrix0];
                    }
                    ++j;

                    if (j < [_intersectingTiles count])
                    {
                        surfaceTile = [_intersectingTiles objectAtIndex:j];
                        glActiveTexture(GL_TEXTURE1);
                        if ([surfaceTile bind:dc])
                        {
                            ++numSimultaneousTextures;
                            [self applyTileState:dc terrainTile:terrainTile surfaceTile:surfaceTile
                                 tileCoordMatrixName:@"tileCoordMatrix1" texCoordMatrixName:@"texCoordMatrix1"
                                 tileCoordMatrix:tileCoordMatrix1 texCoordMatrix:texCoordMatrix1];
                        }
                        ++j;
                    }

                    if (j < [_intersectingTiles count])
                    {
                        surfaceTile = [_intersectingTiles objectAtIndex:j];
                        glActiveTexture(GL_TEXTURE2);
                        if ([surfaceTile bind:dc])
                        {
                            ++numSimultaneousTextures;
                            [self applyTileState:dc terrainTile:terrainTile surfaceTile:surfaceTile
                             tileCoordMatrixName:@"tileCoordMatrix2" texCoordMatrixName:@"texCoordMatrix2"
                                 tileCoordMatrix:tileCoordMatrix2 texCoordMatrix:texCoordMatrix2];
                        }
                        ++j;
                    }

                    if (j < [_intersectingTiles count])
                    {
                        surfaceTile = [_intersectingTiles objectAtIndex:j];
                        glActiveTexture(GL_TEXTURE3);
                        if ([surfaceTile bind:dc])
                        {
                            ++numSimultaneousTextures;
                            [self applyTileState:dc terrainTile:terrainTile surfaceTile:surfaceTile
                             tileCoordMatrixName:@"tileCoordMatrix3" texCoordMatrixName:@"texCoordMatrix3"
                                 tileCoordMatrix:tileCoordMatrix3 texCoordMatrix:texCoordMatrix3];
                        }
                        ++j;
                    }

                    if (numSimultaneousTextures > 0)
                    {
                        [program loadUniformInt:@"numTextures" value:numSimultaneousTextures];
                        [terrainTile render:dc];
                    }
                }
            }
            @finally
            {
                [terrainTile endRendering:dc];
            }

        }
    }
    @finally
    {
        [terrainTiles endRendering:dc];
        [self endRendering:dc];
    }

}

- (void) beginRendering:(WWDrawContext*)dc program:(WWGpuProgram*)program opacity:(float)opacity
{
    [program bind];
    [dc setCurrentProgram:program];

    glActiveTexture(GL_TEXTURE0);

    [program loadUniformSampler:@"tileTexture0" value:0];
    [program loadUniformSampler:@"tileTexture1" value:1];
    [program loadUniformSampler:@"tileTexture2" value:2];
    [program loadUniformSampler:@"tileTexture3" value:3];
    [program loadUniformFloat:@"opacity" value:opacity];
}

- (void) endRendering:(WWDrawContext*)dc
{
    [dc setCurrentProgram:nil];

    glUseProgram(0);
    glActiveTexture(GL_TEXTURE0);

    [_intersectingGeometry removeAllObjects];
    [_intersectingTiles removeAllObjects];
}

- (void) assembleIntersectingTiles:(WWTerrainTile*)terrainTile surfaceTiles:(NSArray*)surfaceTiles
{
    WWSector* terrainTileSector = [terrainTile sector];

    for (NSUInteger i = 0; i < [surfaceTiles count]; i++)
    {
        id <WWSurfaceTile> surfaceTile = [surfaceTiles objectAtIndex:i];

        if (surfaceTile != nil && [[surfaceTile sector] intersects:terrainTileSector])
        {
            [_intersectingTiles addObject:surfaceTile];
        }
    }
}

- (void) assembleIntersectingGeometry:(id <WWSurfaceTile>)surfaceTile terrainTiles:(WWTerrainTileList*)terrainTiles
{
    WWSector* surfaceTileSector = [surfaceTile sector];

    for (NSUInteger i = 0; i < [terrainTiles count]; i++)
    {
        WWTerrainTile* terrainTile = [terrainTiles objectAtIndex:i];

        if (terrainTile != nil && [[terrainTile sector] intersects:surfaceTileSector])
        {
            [_intersectingGeometry addObject:terrainTile];
        }
    }
}

- (void) applyTileState:(WWDrawContext*)dc
            terrainTile:(WWTerrainTile*)terrainTile
            surfaceTile:(id <WWSurfaceTile>)surfaceTile
    tileCoordMatrixName:(NSString*)tileCoordMatrixName
     texCoordMatrixName:(NSString*)texCoordMatrixName
        tileCoordMatrix:(WWMatrix*)tileCoordMatrix
         texCoordMatrix:(WWMatrix*)texCoordMatrix
{
    WWGpuProgram* prog = [dc currentProgram];

    [self computeTileCoordMatrix:terrainTile surfaceTile:surfaceTile result:tileCoordMatrix];
    [prog loadUniformMatrix:tileCoordMatrixName matrix:tileCoordMatrix];

    [texCoordMatrix setToUnitYFlip];
    [surfaceTile applyInternalTransform:dc matrix:texCoordMatrix];
    [texCoordMatrix multiplyMatrix:tileCoordMatrix];
    [prog loadUniformMatrix:texCoordMatrixName matrix:texCoordMatrix];
}

- (void) computeTileCoordMatrix:(WWTerrainTile*)terrainTile surfaceTile:(id <WWSurfaceTile>)surfaceTile result:(WWMatrix*)result
{
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

    [result set:sScale m01:0 m02:0 m03:sScale * sTrans
            m10:0 m11:tScale m12:0 m13:tScale * tTrans
            m20:0 m21:0 m22:1 m23:0
            m30:0 m31:0 m32:0 m33:1];
}

// STRINGIFY is used in the shader files.
#define STRINGIFY(A) #A
#import "WorldWind/Shaders/SurfaceTileRendererMultiTexture.vert"
#import "WorldWind/Shaders/SurfaceTileRendererMultiTexture.frag"

- (WWGpuProgram*) gpuProgram:(WWDrawContext*)dc
{
    WWGpuProgram* program = [[dc gpuResourceCache] getProgramForKey:self->programKey];
    if (program != nil)
        return program;

    @try
    {
        program = [[WWGpuProgram alloc] initWithShaderSource:SurfaceTileRendererVertexShader
                                              fragmentShader:SurfaceTileRendererFragmentShader];
        [[dc gpuResourceCache] putProgram:program forKey:self->programKey];
    }
    @catch (NSException* exception)
    {
        WWLogE(@"making GPU program", exception);
    }

    return program;
}

@end