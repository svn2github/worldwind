/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "Worldwind/Terrain/WWElevationModel.h"
#import "WorldWind/Util/WWTileFactory.h"

@class WWElevationTile;
@class WWLocation;
@protocol WWUrlBuilder;

@interface WWBasicElevationModel : NSObject <WWElevationModel, WWTileFactory>

/// @name Attributes

/**
* Indicates the date and time at which the elevation model last changed.
*
* This can be used to invalidate cached computations based on the elevation model's values.
*/
@property(readonly) NSDate* timestamp; // This property is accessed from multiple threads, and is therefore declared atomic.

/// The elevation image format to request from the remote server. The default is _application/bil16_.
@property(nonatomic, readonly) NSString* retrievalImageFormat;

/// The file system path to the local directory holding this instance's cached elevation images.
@property(nonatomic, readonly) NSString* cachePath;

/// A class implementing the WWUrlBuilder protocol for creating the URL identifying a specific elevation tile. For WMS
// elevation models the specified instance generates an HTTP URL for the WMS protocol. This property must be specified
// prior to using the model. Although it is initialized to nil, it may not be nil when the model becomes active.
@property(nonatomic) id <WWUrlBuilder> urlBuilder;

/// @name Initializing Tiled Elevation Models

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

- (void) assembleTilesForSector:(WWSector*)sector resolution:(double)resolution;

- (void) addTileOrAncestor:(WWLevel*)level row:(int)row column:(int)column;

- (void) addAncestorFor:(WWLevel*)level row:(int)row column:(int)column;

- (WWLevel*) levelForResolution:(double)targetResolution;

- (WWElevationTile*) tileForLevel:(WWLevel*)level row:(int)row column:(int)column;

- (BOOL) isTileImageLocal:(WWElevationTile*)tile;

- (void) retrieveTileImage:(WWElevationTile*)tile;

- (NSURL*) resourceUrlForTile:(WWTile*)tile imageFormat:(NSString*)imageFormat;

- (void) handleImageRetrievalNotification:(NSNotification*)notification;

- (void) handleImageReadNotification:(NSNotification*)notification;

@end