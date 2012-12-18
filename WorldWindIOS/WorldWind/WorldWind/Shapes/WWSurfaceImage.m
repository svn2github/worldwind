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
#import "WorldWInd/WWLog.h"

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

    self->texture = [[WWTexture alloc] initWithContentsOfFile:imagePath];

    return self;
}

- (BOOL) bind:(WWDrawContext*)dc
{
    return [self->texture bind:dc];
}

- (void) render:(WWDrawContext*)dc
{
    [[dc surfaceTileRenderer] renderTile:dc surfaceTile:self];
}

@end