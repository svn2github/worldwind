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

- (BOOL) bind:(WWDrawContext*)dc
{
    WWTexture* texture = [[dc gpuResourceCache] getTextureForKey:_imagePath];
    if (texture != nil)
    {
        return [texture bind:dc];
    }

    texture = [[WWTexture alloc] initWithImagePath:_imagePath];
    BOOL yn = [texture bind:dc];

    if (yn)
    {
        [[dc gpuResourceCache] putTexture:texture forKey:_imagePath];
    }

    return yn;
}

@end