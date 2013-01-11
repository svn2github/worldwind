/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Layer/WWTiledImageLayer.h"
#import "WorldWind/Util/WWLevelSet.h"
#import "WorldWind/Geometry/WWSector.h"
#import "WorldWind/Geometry/WWLocation.h"
#import "WorldWind/WWLog.h"
#import "WorldWind/Render/WWDrawContext.h"
#import "WorldWind/Render/WWSurfaceTileRenderer.h"
#import "WorldWind/Util/WWTile.h"
#import "WorldWind/Render/WWSurfaceTile.h"
#import "WorldWind/Render/WWTextureTile.h"
#import "WorldWind/Util/WWLevel.h"
#import "WorldWind/Util/WWGpuResourceCache.h"
#import "WorldWind/Util/WWWmsUrlBuilder.h"

@implementation WWTiledImageLayer

- (WWTiledImageLayer*) initWithSector:(WWSector*)sector
                       levelZeroDelta:(WWLocation*)levelZeroDelta
                            numLevels:(int)numLevels
                            cachePath:(NSString*)cachePath
{
    if (sector == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Sector is nil")
    }

    if (levelZeroDelta == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Level 0 delta is nil")
    }

    if (numLevels < 1)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Number of levels is less than 1")
    }

    if (cachePath == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Cache path is nil")
    }

    self = [super init];

    _cachePath = cachePath;

    _imageFormat = @"image/png";
    _formatSuffix = @".png";

    self->levels = [[WWLevelSet alloc] initWithSector:sector
                                               origin:nil
                                       levelZeroDelta:levelZeroDelta
                                            numLevels:numLevels];

    self->currentTiles = [[NSMutableArray alloc] init];
    self->topLevelTiles = [[NSMutableArray alloc] init];

    return self;
}

- (void) doRender:(WWDrawContext*)dc
{
    if ([dc surfaceGeometry] == nil)
        return;

    [self assembleTiles:dc];

    if ([self->currentTiles count] > 0)
    {
        [[dc surfaceTileRenderer] renderTiles:dc surfaceTiles:self->currentTiles];

        // TODO: Check texture expiration

        [self->currentTiles removeAllObjects];
    }
}

- (BOOL) isLayerInView:(WWDrawContext*)dc
{
    WWSector* visibleSector = [dc visibleSector];

    return visibleSector == nil || [visibleSector intersects:[self->levels sector]];
}

- (BOOL) isTileVisible:(WWDrawContext*)dc tile:(WWTextureTile*)tile
{
    WWSector* visibleSector = [dc visibleSector];

    // TODO: check against 3D extent
    return visibleSector == nil || [visibleSector intersects:[tile sector]];
}

- (void) assembleTiles:(WWDrawContext*)dc
{
    [self->currentTiles removeAllObjects];

    if ([self->topLevelTiles count] == 0)
    {
        [self createTopLevelTiles];
    }

    for (NSUInteger i = 0; i < [self->topLevelTiles count]; i++)
    {
        WWTextureTile* tile = [self->topLevelTiles objectAtIndex:i];

        // TODO: update tile extent

        if ([self isTileVisible:dc tile:tile])
        {
            [self addTileOrDescendants:dc tile:tile];
        }
    }
}

- (void) addTileOrDescendants:(WWDrawContext*)dc tile:(WWTextureTile*)tile // TODO
{
    if ([self tileMeetsRenderCriteria:dc tile:tile])
    {
        [self addTile:dc tile:tile];
    }
}

- (void) createTopLevelTiles
{
    [self->topLevelTiles removeAllObjects];

    [WWTile createTilesForLevel:[self->levels firstLevel]
                    tileFactory:self
                       tilesOut:self->topLevelTiles];
}

- (void) addTile:(WWDrawContext*)dc tile:(WWTextureTile*)tile
{
    if ([dc.gpuResourceCache containsKey:[tile imagePath]])
    {
        [self->currentTiles addObject:tile];
    }
    else if ([[NSFileManager defaultManager] fileExistsAtPath:[tile imagePath]])
    {
        [self->currentTiles addObject:tile];
    }
    else
    {
        [self retrieveTileImage:tile];
    }
}

- (BOOL) tileMeetsRenderCriteria:(WWDrawContext*)dc tile:(WWTextureTile*)tile
{
    return true;
}

- (WWTile*) createTile:(WWSector*)sector level:(WWLevel*)level row:(int)row column:(int)column
{
    NSString* imagePath = [NSString stringWithFormat:@"%@/%d/%d/%d_%d%@",
                                                     _cachePath, [level levelNumber], row, row, column, _formatSuffix];

    return [[WWTextureTile alloc] initWithSector:sector level:level row:row column:column imagePath:imagePath];
}

- (void) retrieveTileImage:(WWTextureTile*)tile
{
    NSURL* url = [self resourceUrlForTile:tile imageFormat:_imageFormat];

    NSError* error = nil;
    NSData* data = [NSData dataWithContentsOfURL:url options:0 error:&error];
    if (error != nil)
    {
        WWLog("@Error \"%@\" retrieving %@", [error description], [url absoluteString]);
        return;
    }

    // Ensure that the cache directory for this tile exists.
    NSString* pathDir = [[tile imagePath] stringByDeletingLastPathComponent];
    [[NSFileManager defaultManager] createDirectoryAtPath:pathDir
                              withIntermediateDirectories:YES attributes:nil error:&error];
    if (error != nil)
    {
        WWLog("@Error \"%@\" creating path %@", [error description], [tile imagePath]);
        return;
    }

    [data writeToFile:[tile imagePath] options:0 error:&error];
    if (error != nil)
    {
        WWLog("@Error \"%@\" writing file %@", [error description], [tile imagePath]);
        return;
    }
}

- (NSURL*) resourceUrlForTile:(WWTile*)tile imageFormat:(NSString*)imageFormat
{
    if (tile == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Tile is nil")
    }

    if (imageFormat == nil || [imageFormat length] == 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Image format is nil or empty")
    }

    if (_urlBuilder == nil)
    {
        WWLOG_AND_THROW(NSInternalInconsistencyException, @"URL builder is nil")
    }

    return [_urlBuilder urlForTile:tile imageFormat:imageFormat];
}

@end