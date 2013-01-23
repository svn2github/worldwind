/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WorldWind/Util/WWCacheable.h"

/**
* Holds a list of tiles, typically the children of a subdivided tile.
*/
@interface WWTileList : NSObject <WWCacheable>

/// @name Tile List Attributes

/// The list of tiles.
@property (nonatomic, readonly) NSArray* tiles;

/// @name Initializing Tile Lists

/**
* Initializes a tile list with a specified list of tiles.
*
* @param tiles The tiles to place in the list. The specified array is retained in the list.
*
* @return The initialized tile list.
*
* @exception NSInvalidArgumentException If the array of tiles is nil.
*/
- (WWTileList*) initWithTiles:(NSArray*)tiles;

@end