/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "Worldwind/Terrain/WWElevationModel.h"
#import "WorldWind/Util/WWTileFactory.h"

@class WWElevationTile;
@class WWLevelSet;
@class WWLocation;
@class WWMemoryCache;
@class WWTileKey;
@protocol WWUrlBuilder;
@class WWAbsentResourceList;

/**
* Represents the elevations associated with a globe. Used by the globe and the tessellator to determine elevations
* throughout the globe.
*/
@interface WWBasicElevationModel : NSObject <WWElevationModel, WWTileFactory>
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
@property(nonatomic, readonly) NSString* retrievalImageFormat;

/// The file system path to the local directory holding this instance's cached elevation images.
@property(nonatomic, readonly) NSString* cachePath;

/// Indicates the date and time at which the elevation model last changed.
/// This can be used to invalidate cached computations based on the elevation model's values.
@property(readonly) NSDate* timestamp; // This property is accessed from multiple threads, and is therefore declared atomic.

/// Indicates the elevation model's minimum elevation for all values in the model.
/// The minimum and maximum elevation values for a specific geographic area can be determined by calling
/// minAndMaxElevationsForSector:result:.
@property(nonatomic) double minElevation;

/// Indicates the elevation model's maximum elevation for all values in the model.
/// The minimum and maximum elevation values for a specific geographic area can be determined by calling
/// minAndMaxElevationsForSector:result:.
@property(nonatomic) double maxElevation;

/// A class implementing the WWUrlBuilder protocol for creating the URL identifying a specific elevation tile. For WMS
/// elevation models the specified instance generates an HTTP URL for the WMS protocol. This property must be specified
/// prior to using the model. Although it is initialized to nil, it may not be nil when the model becomes active.
@property(nonatomic) id <WWUrlBuilder> urlBuilder;

/// The number of seconds to wait before retrieval requests time out.
@property (nonatomic) NSTimeInterval timeout;

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

/// @name Methods of Interest Only to Subclasses

- (WWLevel*) levelForResolution:(double)targetResolution;

- (WWLevel*) levelForTileDelta:(double)deltaLat;

- (void) assembleTilesForLevel:(WWLevel*)level sector:(WWSector*)sector retrieveTiles:(BOOL)retrieveTiles;

- (void) addTileOrAncestorForLevel:(WWLevel*)level row:(int)row column:(int)column retrieveTiles:(BOOL)retrieveTiles;

- (void) addAncestorForLevel:(WWLevel*)level row:(int)row column:(int)column retrieveTiles:(BOOL)retrieveTiles;

- (WWElevationTile*) tileForLevelNumber:(int)levelNumber row:(int)row column:(int)column;

- (BOOL) isTileImageInMemory:(WWElevationTile*)tile;

- (void) loadOrRetrieveTileImage:(WWElevationTile*)tile;

- (void) loadTileImage:(WWElevationTile*)tile;

- (void) retrieveTileImage:(WWElevationTile*)tile;

- (NSURL*) resourceUrlForTile:(WWTile*)tile imageFormat:(NSString*)imageFormat;

- (void) handleImageRetrievalNotification:(NSNotification*)notification;

- (void) handleImageReadNotification:(NSNotification*)notification;

@end