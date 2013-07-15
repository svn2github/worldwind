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
#import "WorldWind/WorldWind.h"
#import "WorldWind/Util/WWResourceLoader.h"
#import "WorldWind/Pick/WWPickSupport.h"
#import "WorldWind/Layer/WWLayer.h"
#import "WorldWind/Pick/WWPickedObject.h"

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
    _opacity = 1;
    _displayName = @"Surface Image";

    pickSupport = [[WWPickSupport alloc] init];

    return self;
}

- (BOOL) bind:(WWDrawContext*)dc
{
    if ([dc pickingMode])
    {
        unsigned int pickColor = [dc bindPickTexture];
        [pickSupport addPickableObject:[[WWPickedObject alloc] initWithColorCode:pickColor
                                                                      userObject:self
                                                                       pickPoint:[dc pickPoint]
                                                                        position:nil
                                                                       isTerrain:NO]];
        return YES;
    }

    WWTexture* texture = [[WorldWind resourceLoader] textureForImagePath:_imagePath cache:[dc gpuResourceCache]];
    if (texture != nil)
    {
        return [texture bind:dc];
    }

    return NO;
}

- (void) applyInternalTransform:(WWDrawContext*)dc matrix:(WWMatrix*)matrix
{
    // nothing to do here for this shape
}

- (void) render:(WWDrawContext*)dc
{
    [[dc surfaceTileRenderer] renderTile:dc surfaceTile:self opacity:_opacity];

    if ([dc pickingMode])
    {
        [pickSupport resolvePick:dc layer:[dc currentLayer]];
        [dc unbindPickTexture];
    }
}

@end