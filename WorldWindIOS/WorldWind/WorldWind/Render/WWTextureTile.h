/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WorldWind/Util/WWTile.h"

@class WWMemoryCache;
@class WWLevel;
@protocol WWSurfaceTile;

/**
* Provides an image tile class for use within WWTiledImageLayer. Applications typically do not interact with this
* class.
*/
@interface WWTextureTile : WWTile <WWSurfaceTile>

/// @name Attributes

/// The full file-system path to the image.
@property(readonly, nonatomic) NSString* imagePath;

/// The tile whose texture to use when this tile's texture is not available.
@property WWTextureTile* fallbackTile;

/// @name Initializing Texture Tiles

/**
* Initializes a texture tile.
*
* @param sector The sector covered by this tile.
* @param level The level this tile is associated with.
* @param row This tile's row in the associated level.
* @param column This tile's column in the associated level.
* @param imagePath The full path to the image in the local file system.
*
* @return This texture tile, initialized.
*
* @exception NSInvalidArgumentException if the specified sector, level or image path are nil,
* or the row and column numbers are less than zero.
*/
- (WWTextureTile*) initWithSector:(WWSector*)sector
                            level:(WWLevel*)level
                              row:(int)row
                           column:(int)column
                        imagePath:(NSString*)imagePath;

@end