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
#import "WorldWind/Util/WWLevelSet.h"
#import "WorldWind/Util/WWLevel.h"
#import "WorldWind/Util/WWMemoryCache.h"
#import "WorldWind/Util/WWTileKey.h"
#import "WorldWind/Util/WWUrlBuilder.h"
#import "WorldWind/WorldWind.h"
#import "WorldWind/Util/WWAbsentResourceList.h"
#import "WorldWind/Util/WWRetrieverToFile.h"

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

    _timestamp = [NSDate date];
    _retrievalImageFormat = retrievalImageFormat;
    _cachePath = cachePath;
    _timeout = 20; // seconds

    coverageSector = sector;
    currentSector = [[WWSector alloc] initWithDegreesMinLatitude:0 maxLatitude:0 minLongitude:0 maxLongitude:0];

    levels = [[WWLevelSet alloc] initWithSector:sector
                                 levelZeroDelta:levelZeroDelta
                                      numLevels:numLevels];
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
                                             selector:@selector(handleImageReadNotification:)
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

    WWLevel* level = [self levelForResolution:targetResolution];
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

    WWLevel* level = [self levelForTileDelta:[sector deltaLat]];
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
//-- Tile Factory Protocol --//
//--------------------------------------------------------------------------------------------------------------------//

- (WWTile*) createTile:(WWSector*)sector level:(WWLevel*)level row:(int)row column:(int)column
{
    NSString* imagePath = [NSString stringWithFormat:@"%@/%d/%d/%d_%d.%@",
                                                     _cachePath, [level levelNumber], row, row, column, @"raw"];

    return [[WWElevationTile alloc] initWithSector:sector level:level row:row column:column imagePath:imagePath
                                             cache:imageCache];
}

//--------------------------------------------------------------------------------------------------------------------//
//-- Methods of Interest Only to Subclasses --//
//--------------------------------------------------------------------------------------------------------------------//

- (WWLevel*) levelForResolution:(double)targetResolution
{
    WWLevel* lastLevel = [levels lastLevel];

    if ([lastLevel texelSize] >= targetResolution)
    {
        return lastLevel; // Can't do any better than the last level.
    }

    for (int i = 0; i < [levels numLevels]; i++)
    {
        WWLevel* level = [levels level:i];

        if ([level texelSize] <= targetResolution)
        {
            return level;
        }
    }

    return lastLevel;
}

- (WWLevel*) levelForTileDelta:(double)deltaLat
{
    WWLevel* lastLevel = [levels lastLevel];

    if ([[lastLevel tileDelta] latitude] >= deltaLat)
    {
        return lastLevel; // Can't do any better than the last level.
    }

    for (int i = 0; i < [levels numLevels]; i++)
    {
        WWLevel* level = [levels level:i];

        if ([[level tileDelta] latitude] <= deltaLat)
        {
            return level;
        }
    }

    return lastLevel;
}

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
    WWElevationTile* tile = [self tileForLevelNumber:[level levelNumber] row:row column:column];

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
        tile = [self tileForLevelNumber:i row:r column:c];

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

- (WWElevationTile*) tileForLevelNumber:(int)levelNumber row:(int)row column:(int)column
{
    [tileKey setLevelNumber:levelNumber row:row column:column];
    WWTile* tile = [tileCache getValueForKey:tileKey];

    if (tile != nil)
    {
        return (WWElevationTile*) tile;
    }
    else
    {
        WWLevel* level = [levels level:levelNumber];
        WWSector* sector = [WWTile computeSector:level row:row column:column];

        tile = [self createTile:sector level:level row:row column:column];
        [tileCache putValue:tile forKey:[tileKey copy]];

        return (WWElevationTile*) tile;
    }
}

- (BOOL) isTileImageInMemory:(WWElevationTile*)tile
{
    return [imageCache containsKey:[tile imagePath]];
}

- (void) loadOrRetrieveTileImage:(WWElevationTile*)tile
{
    // See if it's already on disk.
    if ([[NSFileManager defaultManager] fileExistsAtPath:[tile imagePath]])
    {
        [self loadTileImage:tile];
    }
    else // If the app is connected to the network, retrieve the image from there.
    {
        [self retrieveTileImage:tile];
    }
}

- (void) loadTileImage:(WWElevationTile*)tile
{
    if ([currentLoads containsObject:[tile imagePath]])
    {
        return;
    }

    [currentLoads addObject:[tile imagePath]];

    WWElevationImage* image = [[WWElevationImage alloc] initWithImagePath:[tile imagePath]
                                                                   sector:[tile sector]
                                                               imageWidth:[tile tileWidth]
                                                              imageHeight:[tile tileHeight]
                                                                    cache:imageCache
                                                                   object:self];
    [[WorldWind loadQueue] addOperation:image];
}

- (void) retrieveTileImage:(WWElevationTile*)tile
{
    if ([WorldWind isOfflineMode])
    {
        return;
    }

    if ([currentRetrievals containsObject:[tile imagePath]] || [absentResources isResourceAbsent:[tile imagePath]])
    {
        return;
    }

    [currentRetrievals addObject:[tile imagePath]];

    NSURL* url = [self resourceUrlForTile:tile imageFormat:_retrievalImageFormat];
    WWRetrieverToFile* retriever = [[WWRetrieverToFile alloc] initWithUrl:url filePath:[tile imagePath] object:self timeout:_timeout];
    [[WorldWind retrievalQueue] addOperation:retriever];
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

- (void) handleImageRetrievalNotification:(NSNotification*)notification
{
    NSDictionary* avList = [notification userInfo];
    NSString* retrievalStatus = [avList valueForKey:WW_RETRIEVAL_STATUS];
    NSString* imagePath = [avList valueForKey:WW_FILE_PATH];

    [currentRetrievals removeObject:imagePath];

    if ([retrievalStatus isEqualToString:WW_SUCCEEDED])
    {
        _timestamp = [NSDate date];
        [absentResources unmarkResourceAbsent:imagePath];

        NSNotification* redrawNotification = [NSNotification notificationWithName:WW_REQUEST_REDRAW object:self];
        [[NSNotificationCenter defaultCenter] postNotification:redrawNotification];
    }
    else
    {
        [absentResources markResourceAbsent:imagePath];
    }
}

- (void) handleImageReadNotification:(NSNotification*)notification
{
    NSDictionary* avList = [notification userInfo];
    NSString* retrievalStatus = [avList valueForKey:WW_REQUEST_STATUS];
    NSString* imagePath = [avList valueForKey:WW_FILE_PATH];

    [currentLoads removeObject:imagePath];

    if ([retrievalStatus isEqualToString:WW_SUCCEEDED])
    {
        _timestamp = [NSDate date];

        NSNotification* redrawNotification = [NSNotification notificationWithName:WW_REQUEST_REDRAW object:self];
        [[NSNotificationCenter defaultCenter] postNotification:redrawNotification];
    }
}

@end