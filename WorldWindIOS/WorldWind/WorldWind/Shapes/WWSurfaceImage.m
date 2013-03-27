/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Shapes/WWSurfaceImage.h"
#import "WorldWind/Geometry/WWSector.h"
#import "WorldWind/Render/WWDrawContext.h"
#import "WorldWind/Render/WWSurfaceTileRenderer.h"
#import "WorldWind/Render/WWTexture.h"
#import "WorldWind/WWLog.h"
#import "WorldWind/Util/WWGpuResourceCache.h"

@implementation WWSurfaceImage

- (WWSurfaceImage*) initWithImagePath:(WWSector*)sector imagePath:(NSString*)imagePath
{
    if (sector == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Sector is nil")
    }

    if (imagePath == nil || [imagePath length] == 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Image path is nil or zero length")
    }

    self = [super init];

    _imagePath = imagePath;
    _sector = sector;

    return self;
}

- (BOOL) bind:(WWDrawContext*)dc
{
    WWTexture* texture = [[dc gpuResourceCache] getTextureForKey:_imagePath];
    if (texture != nil)
    {
        return [texture bind:dc];
    }

    texture = [[WWTexture alloc] initWithImagePath:_imagePath cache:[dc gpuResourceCache] object:self];
    BOOL yn = [texture bind:dc];

    if (yn)
    {
        [[dc gpuResourceCache] putTexture:texture forKey:_imagePath];
    }

    return yn;
}

- (void) applyInternalTransform:(WWDrawContext*)dc matrix:(WWMatrix*)matrix
{
    // nothing to do here for this shape
}

- (void) render:(WWDrawContext*)dc
{
    [[dc surfaceTileRenderer] renderTile:dc surfaceTile:self opacity:_opacity];
}

@end