/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

@class WWSector;
@class WWLevel;
@protocol WWTileFactory;

/**
* Provides a base class for texture tiles used by tiled image layers and elevation tiles used by elevation models.
* Applications typically do not interact with this class.
*/
@interface WWTile : NSObject

/// @name Attributes

/// The sector this tile spans.
@property(readonly, nonatomic) WWSector* sector;

/// The level this tile is associated with.
@property(readonly, nonatomic) WWLevel* level;

/// The tile's row in the associated level.
@property(readonly, nonatomic) int row;

/// The tile's column in the associated level.
@property(readonly, nonatomic) int column;

/// The resolution of a single pixel or cell in a tile of this level set.
@property(readonly, nonatomic) double resolution; // TODO: Is this property necessary?

/**
* Indicates the width in pixels or cells of this tile's resource.
*
* @return The requested width.
*/
- (int) tileWidth;

/**
* Indicates the height in pixels of cells of this tile's resource.
*
* @return The requested height.
*/
- (int) tileHeight;

/**
* Computes a row number for a tile within a level given its latitude.
*
* @param delta The level's latitudinal tile delta in degrees.
* @param latitude The tile's minimum latitude.
*
* @return the row number of the specified tile.
*
* @exception NSInvalidArgumentException if the specified delta is less than or equal to 0 or the specified latitude
* is not within the range -90, 90.
*/
+ (int) computeRow:(double)delta latitude:(double)latitude;

/**
* Computes a column number for a tile within a level given its longitude.
*
* @param delta The level's longitudinal tile delta in degrees.
* @param longitude The tile's minimum longitude.
*
* @return the column number of the specified tile.
*
* @exception NSInvalidArgumentException if the specified delta is less than or equal to 0 or the specified longitude
* is not within the range --180, 180.
*/
+ (int) computeColumn:(double)delta longitude:(double)longitude;

/// @name Initializing Tiles

/**
* Initialize a tile.
*
* @param sector The sector the tile spans.
* @param level The tile's level.
* @param row The row number of the tile within the specified level.
* @param column The column number of the tile withing the specified level.
*
* @return The initialized tile.
*
* @exception NSInvalidArgumentException If the sector or level are nil or the row or column number are less than 0.
*/
- (WWTile*) initWithSector:(WWSector*)sector level:(WWLevel*)level row:(int)row column:(int)column;

/// @name Creating Tiles

/**
* Create all the tiles for a specified level.
*
* @param level The level to create tiles for.
* @param tileFactory The tile factory to use for creating tiles. This is typically implemented by the calling class.
* @param tilesOut An array in which to return the created tiles.
*
* @exception NSInvalidArgumentException if the specified level, tile factory or output array are nil.
*/
+ (void) createTilesForLevel:(WWLevel*)level
                 tileFactory:(id <WWTileFactory>)tileFactory
                    tilesOut:(NSMutableArray*)tilesOut;

@end
