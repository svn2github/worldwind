/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "Worldwind/Terrain/WWElevationModel.h"
#import "WorldWind/Util/WWBulkRetrieverDataSource.h"
#import "WorldWind/Util/WWTileFactory.h"

@class WWAbsentResourceList;
@class WWBulkRetriever;
@class WWElevationTile;
@class WWLevelSet;
@class WWLocation;
@class WWMemoryCache;
@class WWTileKey;
@protocol WWUrlBuilder;

/**
* Represents the elevations associated with a globe. Used by the globe and the tessellator to determine elevations
* throughout the globe.
*/
@interface WWBasicElevationModel : NSObject <WWElevationModel, WWTileFactory, WWBulkRetrieverDataSource>
{
@protected
    // Coverage sector and current requested sector.
    WWSector* coverageSector;
    WWSector* currentSector;
    // Elevation model tiles and tile level set.
    WWLevelSet* levels;
    NSMutableSet* currentTiles;
    NSArray* tileSortDescriptors;
    // Elevation model tile and image caches.
    WWMemoryCache* tileCache;
    WWMemoryCache* imageCache;
    WWTileKey* tileKey;
    // Sets used to eliminate duplicate elevation image retrievals and loads.
    NSMutableSet* currentRetrievals;
    NSMutableSet* currentLoads;
    WWAbsentResourceList* absentResources;
}

/// @name Elevation Model Attributes

/// The elevation image format to request from the remote server. The default is _application/bil16_.
@property (nonatomic, readonly) NSString* retrievalImageFormat;

/// The file system path to the local directory holding this instance's cached elevation images.
@property (nonatomic, readonly) NSString* cachePath;

/// A class implementing the WWUrlBuilder protocol for creating the URL identifying a specific elevation tile. For WMS
/// elevation models the specified instance generates an HTTP URL for the WMS protocol. This property must be specified
/// prior to using the model. Although it is initialized to nil, it may not be nil when the model becomes active.
@property (nonatomic) id <WWUrlBuilder> urlBuilder;

/// The number of seconds to wait before retrieval requests time out.
@property (nonatomic) NSTimeInterval timeout;

/// Indicates the date and time at which the elevation model last changed.
/// This can be used to invalidate cached computations based on the elevation model's values.
@property (atomic, readonly) NSDate* timestamp; // This property is accessed from multiple threads, and is therefore declared atomic.

/// Indicates the elevation model's minimum elevation for all values in the model.
/// The minimum and maximum elevation values for a specific geographic area can be determined by calling
/// minAndMaxElevationsForSector:result:.
@property (nonatomic) double minElevation;

/// Indicates the elevation model's maximum elevation for all values in the model.
/// The minimum and maximum elevation values for a specific geographic area can be determined by calling
/// minAndMaxElevationsForSector:result:.
@property (nonatomic) double maxElevation;

/// @name Initializing Elevation Models

/**
* Initializes a basic elevation model.
*
* @param sector The sector this elevation model covers.
* @param levelZeroDelta The size in latitude and longitude of level zero (lowest resolution) tiles.
* @param numLevels The number of levels to define for the model. Each level is successively one power of two higher
* resolution than the next lower-numbered level. (0 is the lowest resolution level, 1 is twice that resolution, etc.)
* Each level contains four times as many tiles as the next lower-numbered level, each 1/4 the geographic size.
* @param retrievalImageFormat The mime type of the image format for the model's tiles, e.g., _application/bil16_.
* @param cachePath The local file system location in which to store the model's retrieved elevation images.
*
* @return This elevation model, initialized.
*
* @exception NSInvalidArgumentException If the sector, level zero delta, image format or cache path are nil,
* or the specified number of levels is less than one.
*/
- (WWBasicElevationModel*) initWithSector:(WWSector*)sector
                           levelZeroDelta:(WWLocation*)levelZeroDelta
                                numLevels:(int)numLevels
                     retrievalImageFormat:(NSString*)retrievalImageFormat
                                cachePath:(NSString*)cachePath;

/// @name Creating Elevation Tiles

- (WWTile*) createTile:(WWSector*)sector level:(WWLevel*)level row:(int)row column:(int)column;

- (WWTile*) createTile:(WWTileKey*)key;

/// @name Bulk Retrieval

/**
* Retrieves all elevation tiles for the region and resolution specified by the bulk retriever.
*
* WWBasicElevationModel assumes that this message is sent from a non-UI thread, and therefore performs a long running
* task to retrieve the necessary elevation tiles.
*
* @param retriever The retriever defining the region and resolution to download resources for.
*
* @exception NSInvalidArgumentException If the retriever is nil.
*/
- (void) performBulkRetrieval:(WWBulkRetriever*)retriever;

/**
* Updates the specified bulk retriever's progress according to the number of completed tiles and the total number of
* tiles that this bulk retriever data source is currently retrieving.
*
* The progress is computed as a floating-point value between 0.0 and 1.0, inclusive. A value of 1.0 indicates that the
* number of completed tiles has reached the total tile count, and the retriever's task is complete.
*
* @param retriever The retriever whose progress is updated.
* @param completed The number of completed tiles.
* @param count The total number of tiles this data source is currently retrieving.
*/
- (void) bulkRetriever:(WWBulkRetriever*)retriever tilesCompleted:(NSUInteger)completed tileCount:(NSUInteger)count;

/// @name Methods of Interest Only to Subclasses

- (void) assembleTilesForLevel:(WWLevel*)level sector:(WWSector*)sector retrieveTiles:(BOOL)retrieveTiles;

- (void) addTileOrAncestorForLevel:(WWLevel*)level row:(int)row column:(int)column retrieveTiles:(BOOL)retrieveTiles;

- (void) addAncestorForLevel:(WWLevel*)level row:(int)row column:(int)column retrieveTiles:(BOOL)retrieveTiles;

- (WWElevationTile*) tileForLevelNumber:(int)levelNumber row:(int)row column:(int)column cache:(WWMemoryCache*)cache;

- (BOOL) isTileImageInMemory:(WWElevationTile*)tile;

- (BOOL) isTileImageOnDisk:(WWElevationTile*)tile;

- (void) loadOrRetrieveTileImage:(WWElevationTile*)tile;

- (void) loadTileImage:(WWElevationTile*)tile;

- (NSString*) retrieveTileImage:(WWElevationTile*)tile;

- (NSURL*) resourceUrlForTile:(WWTile*)tile imageFormat:(NSString*)imageFormat;

- (void) handleImageLoadNotification:(NSNotification*)notification;

- (void) handleImageRetrievalNotification:(NSNotification*)notification;

@end