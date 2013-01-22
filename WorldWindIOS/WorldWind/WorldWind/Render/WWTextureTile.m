/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Render/WWSurfaceTile.h"
#import "WorldWind/Render/WWTextureTile.h"
#import "WorldWind/Util/WWLevel.h"
#import "WorldWind/Render/WWTexture.h"
#import "WorldWind/Util/WWGpuResourceCache.h"
#import "WorldWind/Render/WWDrawContext.h"
#import "WorldWind/WWLog.h"
#import "WorldWind/Geometry/WWMatrix.h"

@implementation WWTextureTile

- (WWTextureTile*) initWithSector:(WWSector*)sector
                            level:(WWLevel*)level
                              row:(int)row
                           column:(int)column
                        imagePath:(NSString*)imagePath
{
    // superclass checks sector, level, row and column arguments.

    self = [super initWithSector:sector level:level row:row column:column];

    if (imagePath == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Tile image path is nil")
    }

    _imagePath = imagePath;

    return self;
}

- (long) sizeInBytes
{
    return 8 + [_imagePath length];
}

- (BOOL) bind:(WWDrawContext*)dc
{
    WWTexture* texture = [[dc gpuResourceCache] getTextureForKey:_imagePath];
    if (texture != nil)
    {
        return [texture bind:dc];
    }

    texture = [[WWTexture alloc] initWithImagePath:_imagePath];
    if ([texture bind:dc])
    {
        [[dc gpuResourceCache] putTexture:texture forKey:_imagePath];
        return YES;
    }
    else if (_fallbackTile != nil)
    {
        return [_fallbackTile bind:dc];
    }

    return NO;
}

- (void) applyInternalTransform:(WWDrawContext*)dc matrix:(WWMatrix*)matrix
{
    if (_fallbackTile != nil && [[dc gpuResourceCache] getTextureForKey:_imagePath] == nil)
    {
        // Must apply a texture transform to map the tile's sector into its fallback's image.
        [self applyFallbackTransform:dc matrix:matrix];
    }
}

- (void) applyFallbackTransform:(WWDrawContext*)dc matrix:(WWMatrix*)matrix
{
    int deltaLevel = [[self level] levelNumber] - [[_fallbackTile level] levelNumber];
    if (deltaLevel <= 0)
        return; // fallback tile must be from a level whose ordinal is less than this tile

    int twoN = 2 << (deltaLevel - 1);
    double sxy = 1 / (double) twoN;
    double tx = sxy * ([self column] % twoN);
    double ty = sxy * ([self row] % twoN);

    // Apply a transform to the matrix that maps texture coordinates for this tile to texture coordinates for the
    // fallback tile. Rather than perform the full set of matrix operations, a single multiply is performed with the
    // precomputed non-zero values:
    //
    // Matrix trans = Matrix.fromTranslation(tx, ty, 0);
    // Matrix scale = Matrix.fromScale(sxy, sxy, 1);
    // matrix.multiply(trans);
    // matrix.multiply(scale);

    [matrix multiply: sxy  m01:0 m02:0 m03:tx
                 m10:0 m11:sxy m12:0 m13:ty
                 m20:0 m21:0 m22:1 m23:0
                 m30:0 m31:0 m32:0 m33:1];
}


@end