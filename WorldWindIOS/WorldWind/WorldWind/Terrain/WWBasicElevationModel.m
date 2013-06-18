/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "WorldWind/Terrain/WWBasicElevationModel.h"
#import "WorldWind/Terrain/WWElevationImage.h"
#import "WorldWind/Terrain/WWElevationTile.h"
#import "WorldWind/Geometry/WWLocation.h"
#import "WorldWind/Geometry/WWSector.h"
#import "WorldWind/Util/WWAbsentResourceList.h"
#import "WorldWind/Util/WWBulkRetriever.h"
#import "WorldWind/Util/WWLevel.h"
#import "WorldWind/Util/WWLevelSet.h"
#import "WorldWind/Util/WWMath.h"
#import "WorldWind/Util/WWMemoryCache.h"
#import "WorldWind/Util/WWRetrieverToFile.h"
#import "WorldWind/Util/WWTileKey.h"
#import "WorldWind/Util/WWUrlBuilder.h"
#import "WorldWind/WorldWind.h"

@implementation WWBasicElevationModel

//--------------------------------------------------------------------------------------------------------------------//
//-- Initializing Elevation Models --//
//--------------------------------------------------------------------------------------------------------------------//

- (WWBasicElevationModel*) initWithSector:(WWSector*)sector
                           levelZeroDelta:(WWLocation*)levelZeroDelta
                                numLevels:(int)numLevels
                     retrievalImageFormat:(NSString*)retrievalImageFormat
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

    if (retrievalImageFormat == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Image format is nil")
    }

    if (cachePath == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Cache path is nil")
    }

    self = [super init];

    _retrievalImageFormat = retrievalImageFormat;
    _cachePath = cachePath;
    _timeout = 20; // seconds
    _timestamp = [NSDate date];

    coverageSector = sector;
    currentSector = [[WWSector alloc] initWithDegreesMinLatitude:0 maxLatitude:0 minLongitude:0 maxLongitude:0];

    levels = [[WWLevelSet alloc] initWithSector:sector levelZeroDelta:levelZeroDelta numLevels:numLevels];
    currentTiles = [[NSMutableSet alloc] init];
    tileSortDescriptors = [NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"level" ascending:YES]];

    tileCache = [[WWMemoryCache alloc] initWithCapacity:1000000 lowWater:800000]; // Holds 975 tiles.
    imageCache = [[WWMemoryCache alloc] initWithCapacity:10000000 lowWater:8000000]; // Holds 76 16-bit 256x256 images.
    tileKey = [[WWTileKey alloc] initWithLevelNumber:0 row:0 column:0];

    currentRetrievals = [[NSMutableSet alloc] init];
    currentLoads = [[NSMutableSet alloc] init];
    absentResources = [[WWAbsentResourceList alloc] initWithMaxTries:3 minCheckInterval:10];

    // Set up to handle retrieval and image read monitoring.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleImageRetrievalNotification:)
                                                 name:WW_RETRIEVAL_STATUS // retrieval from net
                                               object:self];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleImageLoadNotification:)
                                                 name:WW_REQUEST_STATUS // opening image file on disk
                                               object:self];

    return self;
}

- (void) dispose
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

//--------------------------------------------------------------------------------------------------------------------//
//-- Retrieving Elevations --//
//--------------------------------------------------------------------------------------------------------------------//

- (double) elevationForLatitude:(double)latitude longitude:(double)longitude
{
    if (![coverageSector contains:latitude longitude:longitude])
    {
        return 0; // Location is outside the elevation model's coverage area.
    }

    WWLevel* level = [levels lastLevel];
    double deltaLat = [[level tileDelta] latitude];
    double deltaLon = [[level tileDelta] longitude];
    int r = [WWTile computeRow:deltaLat latitude:latitude];
    int c = [WWTile computeColumn:deltaLon longitude:longitude];

    WWElevationTile* tile = nil;
    WWElevationImage* image = nil;

    for (int i = [level levelNumber]; i >= 0; i--) // Iterate from the last level to the first level.
    {
        [tileKey setLevelNumber:i row:r column:c];
        tile = [tileCache getValueForKey:tileKey]; // TODO: Test the relative performance of containsKey.

        if (tile != nil && (image = [tile image]) != nil) // Both the tile and its image must be local.
        {
            break;
        }

        r /= 2;
        c /= 2;
    }

    return image != nil ? [image elevationForLatitude:latitude longitude:longitude] : 0;
}

- (double) elevationsForSector:(WWSector*)sector
                        numLat:(int)numLat
                        numLon:(int)numLon
              targetResolution:(double)targetResolution
          verticalExaggeration:(double)verticalExaggeration
                        result:(double [])result
{
    if (sector == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Sector is nil")
    }

    if (result == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Output array is nil")
    }

    if (numLat <= 0 || numLon <= 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Num lat or num lon is not positive")
    }

    WWLevel* level = [levels levelForTexelSize:targetResolution];
    [self assembleTilesForLevel:level sector:sector retrieveTiles:YES];

    if ([currentTiles count] == 0)
    {
        return 0; // Sector is outside the elevation model's coverage area. Do not modify the result array.
    }

    // TODO: Populate location with minElevation if a value cannot be determined.

    NSArray* sortedTiles = [currentTiles sortedArrayUsingDescriptors:tileSortDescriptors];

    double maxResolution = 0;
    double resolution;

    for (WWElevationTile* tile in sortedTiles)
    {
        WWElevationImage* image = [tile image];
        if (image != nil)
        {
            [image elevationsForSector:sector
                                numLat:numLat
                                numLon:numLon
                  verticalExaggeration:verticalExaggeration
                                result:result];

            resolution = [tile texelSize];

            if (maxResolution < resolution)
            {
                maxResolution = resolution;
            }
        }
        else
        {
            maxResolution = FLT_MAX;
        }
    }

    return maxResolution;
}

- (void) minAndMaxElevationsForSector:(WWSector*)sector result:(double [])result
{
    if (sector == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Sector is nil")
    }

    if (result == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Output array is nil")
    }

    WWLevel* level = [levels levelForTileDelta:[sector deltaLat]];
    [self assembleTilesForLevel:level sector:sector retrieveTiles:NO];

    if ([currentTiles count] == 0)
    {
        return; // Sector is outside the elevation model's coverage area. Do not modify the result array.
    }

    BOOL haveElevations = NO;
    double elevation;
    double minElevation = +DBL_MAX;
    double maxElevation = -DBL_MAX;

    for (WWElevationTile* tile in currentTiles) // No need to sort.
    {
        WWElevationImage* image = [tile image];
        if (image != nil)
        {
            haveElevations = YES;

            elevation = [image minElevation];
            if (minElevation > elevation)
            {
                minElevation = elevation;
            }

            elevation = [image maxElevation];
            if (maxElevation < elevation)
            {
                maxElevation = elevation;
            }
        }
    }

    if (haveElevations)
    {
        result[0] = minElevation;
        result[1] = maxElevation;
    }
    else
    {
        result[0] = _minElevation;
        result[1] = _maxElevation;
    }
}

//--------------------------------------------------------------------------------------------------------------------//
//-- Creating Elevation Tiles --//
//--------------------------------------------------------------------------------------------------------------------//

- (WWTile*) createTile:(WWSector*)sector level:(WWLevel*)level row:(int)row column:(int)column
{
    NSString* imagePath = [NSString stringWithFormat:@"%@/%d/%d/%d_%d.%@",
                                                     _cachePath, [level levelNumber], row, row, column, @"raw"];

    return [[WWElevationTile alloc] initWithSector:sector level:level row:row column:column imagePath:imagePath
                                             cache:imageCache];
}

- (WWTile*) createTile:(WWTileKey*)key
{
    WWLevel* level = [levels level:[key levelNumber]];
    int row = [key row];
    int column = [key column];

    WWSector* sector = [WWTile computeSector:level row:row column:column];

    return [self createTile:sector level:level row:row column:column];
}

//--------------------------------------------------------------------------------------------------------------------//
//-- Bulk Retrieval --//
//--------------------------------------------------------------------------------------------------------------------//

#define BULK_RETRIEVER_SIMULTANEOUS_TILES 8
#define BULK_RETRIEVER_SLEEP_INTERVAL 0.1

- (void) performBulkRetrieval:(WWBulkRetriever*)retriever
{
    if (retriever == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Retriever is nil")
    }

    int lastLevel = [[levels levelForTexelSize:[retriever targetResolution]] levelNumber];
    NSUInteger tileCount = [levels tileCountForSector:[retriever sector] lastLevel:lastLevel];
    NSUInteger simultaneousTileCount = BULK_RETRIEVER_SIMULTANEOUS_TILES;
    NSUInteger completedTileCount = 0;

    NSEnumerator* tileEnumerator = [levels tileEnumeratorForSector:[retriever sector] lastLevel:lastLevel];
    NSMutableArray* tiles = [[NSMutableArray alloc] initWithCapacity:simultaneousTileCount];
    NSMutableArray* completedTiles = [[NSMutableArray alloc] initWithCapacity:simultaneousTileCount];

    do
    {
        @autoreleasepool
        {
            for (WWTile* tile in tiles)
            {
                if ([self retrieveTileImage:(WWElevationTile*) tile] != nil) // tile absent or local
                {
                    [self bulkRetriever:retriever tilesCompleted:++completedTileCount tileCount:tileCount];
                    [completedTiles addObject:tile];
                }
            }

            [tiles removeObjectsInArray:completedTiles];
            [completedTiles removeAllObjects];

            while ([tiles count] < simultaneousTileCount && ![retriever mustStopBulkRetrieval])
            {
                @autoreleasepool
                {
                    id nextObject = [tileEnumerator nextObject];
                    if (nextObject == nil)
                    {
                        break;
                    }

                    WWTile* nextTile = [self createTile:(WWTileKey*) nextObject];
                    if ([self retrieveTileImage:(WWElevationTile*) nextTile] != nil) // tile absent or local
                    {
                        [self bulkRetriever:retriever tilesCompleted:++completedTileCount tileCount:tileCount];
                    }
                    else
                    {
                        [tiles addObject:nextTile];
                    }
                }
            }
        }

        [NSThread sleepForTimeInterval:BULK_RETRIEVER_SLEEP_INTERVAL];
    }
    while ([tiles count] > 0 && ![retriever mustStopBulkRetrieval]);
}

- (void) bulkRetriever:(WWBulkRetriever*)retriever tilesCompleted:(NSUInteger)completed tileCount:(NSUInteger)count
{
    float progress = WWCLAMP((float) completed / (float) count, 0, 1);
    dispatch_async(dispatch_get_main_queue(), ^{
        [retriever setProgress:progress];
    });
}

//--------------------------------------------------------------------------------------------------------------------//
//-- Methods of Interest Only to Subclasses --//
//--------------------------------------------------------------------------------------------------------------------//

- (void) assembleTilesForLevel:(WWLevel*)level sector:(WWSector*)sector retrieveTiles:(BOOL)retrieveTiles
{
    [currentTiles removeAllObjects];

    // Intersect the requested sector with the elevation model's coverage area. This avoids attempting to assemble tiles
    // that are outside the coverage area.
    [currentSector set:sector];
    [currentSector intersection:coverageSector];

    if ([currentSector isEmpty])
    {
        return; // Sector is outside the elevation model's coverage area.
    }

    double deltaLat = [[level tileDelta] latitude];
    double deltaLon = [[level tileDelta] longitude];

    int firstRow = [WWTile computeRow:deltaLat latitude:[currentSector minLatitude]];
    int lastRow = [WWTile computeRow:deltaLat latitude:[currentSector maxLatitude]];
    int firstCol = [WWTile computeColumn:deltaLon longitude:[currentSector minLongitude]];
    int lastCol = [WWTile computeColumn:deltaLon longitude:[currentSector maxLongitude]];

    for (int row = firstRow; row <= lastRow; row++)
    {
        for (int col = firstCol; col <= lastCol; col++)
        {
            [self addTileOrAncestorForLevel:level row:row column:col retrieveTiles:retrieveTiles];
        }
    }
}

- (void) addTileOrAncestorForLevel:(WWLevel*)level row:(int)row column:(int)column retrieveTiles:(BOOL)retrieveTiles
{
    WWElevationTile* tile = [self tileForLevelNumber:[level levelNumber] row:row column:column cache:tileCache];

    if ([self isTileImageInMemory:tile])
    {
        [currentTiles addObject:tile];
    }
    else
    {
        if (retrieveTiles)
        {
            [self loadOrRetrieveTileImage:tile];
        }

        if ([level isFirstLevel])
        {
            [currentTiles addObject:tile]; // No ancestor tile to add.
        }
        else
        {
            [self addAncestorForLevel:level row:row column:column retrieveTiles:retrieveTiles];
        }
    }
}

- (void) addAncestorForLevel:(WWLevel*)level row:(int)row column:(int)column retrieveTiles:(BOOL)retrieveTiles
{
    WWElevationTile* tile = nil;

    int r = row / 2;
    int c = column / 2;

    for (int i = [level levelNumber] - 1; i >= 0; i--) // Iterate from the parent level to the first level.
    {
        tile = [self tileForLevelNumber:i row:r column:c cache:tileCache];

        if ([self isTileImageInMemory:tile])
        {
            [currentTiles addObject:tile]; // Have an ancestor tile with an in-memory image.
            return;
        }

        r /= 2;
        c /= 2;
    }

    // No ancestor tiles have an in-memory image. Retrieve the ancestor tile corresponding for the first level, and
    // add it. We add the necessary tiles to provide coverage over the requested sector in order to accurately return
    // whether or not this elevation model has data for the entire sector.
    [currentTiles addObject:tile];

    if (retrieveTiles)
    {
        [self loadOrRetrieveTileImage:tile];
    }
}

- (WWElevationTile*) tileForLevelNumber:(int)levelNumber row:(int)row column:(int)column cache:(WWMemoryCache*)cache
{
    [tileKey setLevelNumber:levelNumber row:row column:column];
    WWTile* tile = [cache getValueForKey:tileKey];

    if (tile != nil)
    {
        return (WWElevationTile*) tile;
    }
    else
    {
        WWLevel* level = [levels level:levelNumber];
        WWSector* sector = [WWTile computeSector:level row:row column:column];

        tile = [self createTile:sector level:level row:row column:column];
        [cache putValue:tile forKey:[tileKey copy]];

        return (WWElevationTile*) tile;
    }
}

- (BOOL) isTileImageInMemory:(WWElevationTile*)tile
{
    return [imageCache containsKey:[tile imagePath]];
}

- (BOOL) isTileImageOnDisk:(WWElevationTile*)tile
{
    return [[NSFileManager defaultManager] fileExistsAtPath:[tile imagePath]];
}

- (void) loadOrRetrieveTileImage:(WWElevationTile*)tile
{
    if ([self isTileImageOnDisk:tile])
    {
        [self loadTileImage:tile];
    }
    else
    {
        [self retrieveTileImage:tile];
    }
}

- (void) loadTileImage:(WWElevationTile*)tile
{
    @synchronized (currentLoads)
    {
        if ([currentLoads containsObject:[tile imagePath]])
        {
            return;
        }

        [currentLoads addObject:[tile imagePath]];
    }

    WWElevationImage* image = [[WWElevationImage alloc] initWithImagePath:[tile imagePath]
                                                                   sector:[tile sector]
                                                               imageWidth:[tile tileWidth]
                                                              imageHeight:[tile tileHeight]
                                                                    cache:imageCache
                                                                   object:self];
    [[WorldWind loadQueue] addOperation:image];
}

- (NSString*) retrieveTileImage:(WWElevationTile*)tile
{
    if ([WorldWind isOfflineMode])
    {
        return nil; // don't know the tile's status in offline mode
    }

    if ([absentResources isResourceAbsent:[tile imagePath]])
    {
        return WW_ABSENT;
    }

    @synchronized (currentRetrievals)
    {
        // Synchronize checking for the file on disk with adding the tile to currentRetrievals. This avoids unnecessary
        // retrievals initiated when a retrieval completes between the time this thread checks for the file on disk and
        // checks the currentRetrievals list.

        if ([self isTileImageOnDisk:tile])
        {
            return WW_LOCAL;
        }
        else if ([currentRetrievals containsObject:[tile imagePath]])
        {
            return nil; // don't know the tile's status until retrieval completes
        }

        [currentRetrievals addObject:[tile imagePath]];
    }

    NSURL* url = [self resourceUrlForTile:tile imageFormat:_retrievalImageFormat];
    WWRetrieverToFile* retriever = [[WWRetrieverToFile alloc] initWithUrl:url filePath:[tile imagePath] object:self timeout:_timeout];
    [[WorldWind retrievalQueue] addOperation:retriever];

    return nil; // don't know the tile's status until retrieval completes
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

- (void) handleImageLoadNotification:(NSNotification*)notification
{
    NSDictionary* avList = [notification userInfo];
    NSString* retrievalStatus = [avList valueForKey:WW_REQUEST_STATUS];
    NSString* imagePath = [avList valueForKey:WW_FILE_PATH];

    @try
    {
        if ([retrievalStatus isEqualToString:WW_SUCCEEDED])
        {
            _timestamp = [NSDate date];
            [[NSNotificationCenter defaultCenter] postNotificationName:WW_REQUEST_REDRAW object:self];
        }
    }
    @finally
    {
        @synchronized (currentLoads)
        {
            [currentLoads removeObject:imagePath];
        }
    }
}

- (void) handleImageRetrievalNotification:(NSNotification*)notification
{
    NSDictionary* avList = [notification userInfo];
    NSString* retrievalStatus = [avList valueForKey:WW_RETRIEVAL_STATUS];
    NSString* imagePath = [avList valueForKey:WW_FILE_PATH];
    NSNumber* responseCode = [avList valueForKey:WW_RESPONSE_CODE];
    NSURL* url = [avList objectForKey:WW_URL];

    // Check the response code.
    if (responseCode == nil || [responseCode intValue] != 200)
    {
        WWLog(@"Unexpected response code %@ retrieving %@",
        responseCode != nil ? [responseCode stringValue] : @"(no response code)", [url absoluteString]);

        [absentResources markResourceAbsent:imagePath];
        [[NSFileManager defaultManager] removeItemAtPath:imagePath error:nil];
        [currentRetrievals removeObject:imagePath];
        return;
    }

    // Check to see that the mime type returned is the same as the one requested. When these are inconsistent it
    // usually means that the request failed and the server returned an exception message in either HTML or XML.
    NSString* mimeType = [avList objectForKey:WW_MIME_TYPE];
    if (mimeType == nil || [mimeType caseInsensitiveCompare:_retrievalImageFormat] != NSOrderedSame)
    {
        // Any exception message would have been written to the output file. Read and show the message.
        NSError* error = nil;
        NSString* msg = [[NSString alloc] initWithContentsOfFile:imagePath
                                                        encoding:NSUTF8StringEncoding
                                                           error:&error];
        WWLog(@"Unexpeted mime type %@ for request %@: %@",
        mimeType != nil ? mimeType : @"(no mime type in response)", [url absoluteString], error == nil ? msg : @"");

        [absentResources markResourceAbsent:imagePath];
        [[NSFileManager defaultManager] removeItemAtPath:imagePath error:nil];
        [currentRetrievals removeObject:imagePath];
        return;
    }

    @try
    {
        if ([retrievalStatus isEqualToString:WW_SUCCEEDED])
        {
            _timestamp = [NSDate date];
            [absentResources unmarkResourceAbsent:imagePath];
            [[NSNotificationCenter defaultCenter] postNotificationName:WW_REQUEST_REDRAW object:self];
        }
        else
        {
            [absentResources markResourceAbsent:imagePath];
        }
    }
    @finally
    {
        @synchronized (currentRetrievals)
        {
            [currentRetrievals removeObject:imagePath];
        }
    }
}

@end