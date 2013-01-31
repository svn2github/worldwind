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
#import "WorldWind/Util/WWRetriever.h"
#import "WorldWind/WorldWindConstants.h"
#import "WorldWind/Util/WWUtil.h"
#import "WorldWind/Geometry/WWBoundingBox.h"
#import "WorldWind/Navigate/WWNavigatorState.h"
#import "WorldWind/Util/WWMemoryCache.h"
#import "WorldWind/WorldWind.h"
#import "WorldWind/Formats/PVRTC/WWPVRTCImage.h"
#import "WorldWind/Render/WWTexture.h"

@implementation WWTiledImageLayer

- (WWTiledImageLayer*) initWithSector:(WWSector*)sector
                       levelZeroDelta:(WWLocation*)levelZeroDelta
                            numLevels:(int)numLevels
                          imageFormat:(NSString*)imageFormat
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

    if (imageFormat == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Image format is nil")
    }

    if (cachePath == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Cache path is nil")
    }

    self = [super init];

    self->tileCache = [[WWMemoryCache alloc] initWithCapacity:500000 lowWater:400000];

    _imageFormat = imageFormat;
    _cachePath = cachePath;

    self->detailHintOrigin = 2.5;

    self->levels = [[WWLevelSet alloc] initWithSector:sector
                                       levelZeroDelta:levelZeroDelta
                                            numLevels:numLevels];

    self->currentTiles = [[NSMutableArray alloc] init];
    self->topLevelTiles = [[NSMutableArray alloc] init];
    self->currentRetrievals = [[NSMutableSet alloc] init];
    self->currentLoads = [[NSMutableSet alloc] init];

    // Set up to handle retrieval and image read monitoring.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleTextureRetrievalNotification:)
                                                 name:WW_RETRIEVAL_STATUS // retrieval from net
                                               object:self];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleTextureReadNotification:)
                                                 name:WW_REQUEST_STATUS // opening image file on disk
                                               object:self];

    return self;
}

- (void) handleTextureRetrievalNotification:(NSNotification*)notification
{
    NSDictionary* avList = [notification userInfo];
    NSString* retrievalStatus = [avList valueForKey:WW_RETRIEVAL_STATUS];
    NSString* imagePath = [avList valueForKey:WW_FILE_PATH];

    [self->currentRetrievals removeObject:imagePath];

    if ([retrievalStatus isEqualToString:WW_SUCCEEDED])
    {
        [self->currentRetrievals removeObject:imagePath];

        if (_compressTextures)
        {
            [WWPVRTCImage compressFile:[[notification userInfo] valueForKey:WW_FILE_PATH]];
        }

        NSNotification* redrawNotification = [NSNotification notificationWithName:WW_REQUEST_REDRAW object:self];
        [[NSNotificationCenter defaultCenter] postNotification:redrawNotification];
    }
}

- (void) handleTextureReadNotification:(NSNotification*)notification
{
    NSDictionary* avList = [notification userInfo];
    NSString* retrievalStatus = [avList valueForKey:WW_REQUEST_STATUS];
    NSString* imagePath = [avList valueForKey:WW_FILE_PATH];

    [self->currentLoads removeObject:imagePath];

    if ([retrievalStatus isEqualToString:WW_SUCCEEDED])
    {
        [self->currentLoads removeObject:imagePath];

        NSNotification* redrawNotification = [NSNotification notificationWithName:WW_REQUEST_REDRAW object:self];
        [[NSNotificationCenter defaultCenter] postNotification:redrawNotification];
    }
}

- (void) createTopLevelTiles
{
    [self->topLevelTiles removeAllObjects];

    [WWTile createTilesForLevel:[self->levels firstLevel]
                    tileFactory:self
                       tilesOut:self->topLevelTiles];
}

- (void) doRender:(WWDrawContext*)dc
{
    if ([dc surfaceGeometry] == nil)
        return;

    [self assembleTiles:dc];

//    NSLog(@"CURRENT TILES %d", [self->currentTiles count]);
//    for (NSUInteger i = 0; i < [self->currentTiles count]; i++)
//    {
//        WWTextureTile* tile = [self->currentTiles objectAtIndex:i];
//        WWSector* s = [tile sector];
//        NSLog(@"SHOWING %f, %f, %f, %f", [s minLatitude], [s maxLatitude], [s minLongitude], [s maxLongitude]);
//    }

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

    if (visibleSector != nil && ![visibleSector intersects:[tile sector]])
        return NO;

    return [[tile extent] intersects:[[dc navigatorState] frustumInModelCoordinates]];
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

        [tile updateReferencePoints:[dc globe] verticalExaggeration:[dc verticalExaggeration]];
        [tile updateExtent:[dc globe] verticalExaggeration:[dc verticalExaggeration]];

        self->currentAncestorTile = nil;

        if ([self isTileVisible:dc tile:tile])
        {
            [self addTileOrDescendants:dc tile:tile];
        }
    }
}

- (void) addTileOrDescendants:(WWDrawContext*)dc tile:(WWTextureTile*)tile
{
    if ([self tileMeetsRenderCriteria:dc tile:tile])
    {
        [self addTile:dc tile:tile];
        return;
    }

    WWTextureTile* ancestorTile = nil;

    @try
    {
        if ([self isTileTextureLocal:dc tile:tile] || [[tile level] levelNumber] == 0)
        {
            ancestorTile = self->currentAncestorTile;
            self->currentAncestorTile = tile;
        }

        // TODO: Surround this loop with an autorelease pool since a lot of tiles are generated?
        WWLevel* nextLevel = [self->levels level:[[tile level] levelNumber] + 1];
        NSArray* subTiles = [tile subdivide:nextLevel cache:self->tileCache tileFactory:self];
        for (NSUInteger i = 0; i < 4; i++)
        {
            WWTile* child = [subTiles objectAtIndex:i];

            [child updateReferencePoints:[dc globe] verticalExaggeration:[dc verticalExaggeration]];
            [child updateExtent:[dc globe] verticalExaggeration:[dc verticalExaggeration]];

            if ([[self->levels sector] intersects:[child sector]]
                    && [self isTileVisible:dc tile:(WWTextureTile*) child])
            {
                [self addTileOrDescendants:dc tile:(WWTextureTile*) child];
            }
        }
    }
    @finally
    {
        if (ancestorTile != nil)
        {
            self->currentAncestorTile = ancestorTile;
        }
    }
}

- (void) addTile:(WWDrawContext*)dc tile:(WWTextureTile*)tile
{
    [tile setFallbackTile:nil];

    if ([self isTileTextureLocal:dc tile:tile])
    {
        [self->currentTiles addObject:tile];
        return;
    }

    [self retrieveTileImage:dc tile:tile];

    if (self->currentAncestorTile != nil)
    {
        if ([self isTileTextureLocal:dc tile:self->currentAncestorTile])
        {
            [tile setFallbackTile:self->currentAncestorTile];
            [self->currentTiles addObject:tile];
        }
        else if ([[self->currentAncestorTile level] levelNumber] == 0)
        {
            [self retrieveTileImage:dc tile:self->currentAncestorTile];
        }
    }
}

- (BOOL) isTileTextureLocal:(WWDrawContext*)dc tile:(WWTextureTile*)tile
{
    return [dc.gpuResourceCache containsKey:[tile imagePath]];
}

- (BOOL) tileMeetsRenderCriteria:(WWDrawContext*)dc tile:(WWTextureTile*)tile
{
    return [self->levels isLastLevel:[[tile level] levelNumber]]
            || ![tile mustSubdivide:dc detailFactor:(self->detailHintOrigin + _detailHint)];
}

- (WWTile*) createTile:(WWSector*)sector level:(WWLevel*)level row:(int)row column:(int)column
{
    NSString* formatSuffix = _compressTextures ? @"pvr" : [WWUtil suffixForMimeType:_imageFormat];

    NSString* imagePath = [NSString stringWithFormat:@"%@/%d/%d/%d_%d.%@",
                                                     _cachePath, [level levelNumber], row, row, column, formatSuffix];

    return [[WWTextureTile alloc] initWithSector:sector level:level row:row column:column imagePath:imagePath];
}

- (void) retrieveTileImage:(WWDrawContext*)dc tile:(WWTextureTile*)tile
{
    // See if it's already on disk.
    if ([[NSFileManager defaultManager] fileExistsAtPath:[tile imagePath]])
    {
        if ([self->currentLoads containsObject:[tile imagePath]])
            return;
        [self->currentLoads addObject:[tile imagePath]];

        WWTexture* texture = [[WWTexture alloc] initWithImagePath:[tile imagePath]
                                                            cache:[dc gpuResourceCache]
                                                           object:self];
        [texture setThreadPriority:0.1];
        [[WorldWind retrievalQueue] addOperation:texture];
        return;
    }

    // If the app is connected to the network, retrieve the image from there.

    if ([WorldWind isOfflineMode] || ![WorldWind isNetworkAvailable])
        return;

    if ([self->currentRetrievals containsObject:[tile imagePath]])
        return;
    [self->currentRetrievals addObject:[tile imagePath]];

    NSURL* url = [self resourceUrlForTile:tile imageFormat:_imageFormat];

    if (_compressTextures)
    {
        // Download to a file with the download format suffix. The image will be compressed when the
        // notification of download success is received in handleNotification above.
        NSString* suffix = [WWUtil suffixForMimeType:_imageFormat];
        NSString* filePath = [WWUtil replaceSuffixInPath:[tile imagePath] newSuffix:suffix];
        WWRetriever* retriever = [[WWRetriever alloc] initWithUrl:url filePath:filePath object:self];
        [retriever addToQueue:retriever];
    }
    else
    {
        WWRetriever* retriever = [[WWRetriever alloc] initWithUrl:url filePath:[tile imagePath] object:self];
        [retriever setThreadPriority:0.0];
        [retriever addToQueue:retriever];
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