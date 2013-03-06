/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WorldWind/Util/WWTile.h"

@class WWElevationImage;
@class WWMemoryCache;

/**
* Provides an elevation tile class for use within WWBasicElevationModel. Applications typically do not interact with
* this class.
*/
@interface WWElevationTile : WWTile

/// @name Elevation Tile Attributes

/// The full path to the image in the local file system.
@property(readonly, nonatomic) NSString* imagePath;

/// The memory cache the image is retrieved from.
@property(nonatomic, readonly) WWMemoryCache* memoryCache;

/**
* Returns the tile's image from its memory cache, or nil if the image is not in the memory cache.
*
* The elevation tile does not make any attempt to read its image and put it in the memory cache. This must be
* accomplished by adding a WWElevationImage corresponding to the tile to an NSOperationQueue.
*
* @return The tile's image, or nil if the image is not in the memory cache.
*/
- (WWElevationImage*) image;

/// @name Initializing Elevation Tiles

/**
* Initializes an elevation tile.
*
* @param sector The sector covered by this tile.
* @param level The level this tile is associated with.
* @param row This tile's row in the associated level.
* @param column This tile's column in the associated level.
* @param imagePath The full path to the image in the local file system.
* @param cache The memory cache the image is retrieved from.
*
* @return This elevation tile, initialized.
*
* @exception NSInvalidArgumentException if the specified sector, level, image path or cache are nil, or the row and
* column numbers are less than zero.
*/
- (WWElevationTile*) initWithSector:(WWSector*)sector
                              level:(WWLevel*)level
                                row:(int)row
                             column:(int)column
                          imagePath:(NSString*)imagePath
                              cache:(WWMemoryCache*)cache;

@end