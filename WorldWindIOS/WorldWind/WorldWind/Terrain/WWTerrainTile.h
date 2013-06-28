/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WorldWind/Util/WWTile.h"

@class WWTessellator;
@class WWDrawContext;
@class WWMatrix;
@class WWLevel;
@class WWVec4;

/**
* Provides an elevation tile class for use within WWTessellator. Applications typically do not interact with this
* class.
*/
@interface WWTerrainTile : WWTile

/// @name Attributes

/// The tessellator this tile is used by.
///
/// The tessellator property is weak because the tessellator can point to the tile,
/// thereby creating a cycle. A strong reference to the tessellator is always held by the Globe.
@property (nonatomic, readonly, weak) WWTessellator* tessellator;

/// The GPU resource cache ID for this tile's Cartesian coordinates VBO.
@property (nonatomic) NSString* cacheKey;

/// The origin point that the terrain tile's model coordinate points are relative to.
@property (nonatomic) WWVec4* referenceCenter;

/// The transform matrix that maps tile local coordinate to model coordinates.
@property (nonatomic) WWMatrix* transformationMatrix;

/// The number of model coordinate points this tile contains.
@property (nonatomic) int numPoints;

/// Pointer to the terrain tile's model coordinate points.
///
/// The memory referenced by this pointer contains 3 * numPoints 32-bit floating point values. This memory is owned by
/// the terrain tile and is released when the tile is deallocated.
@property (nonatomic) float* points;

/// Indicates the date and time at which this tile's terrain geometry was computed.
///
/// This is used to invalidate the
/// terrain geometry when the globe's elevations change.
@property (nonatomic) NSTimeInterval timestamp;

/// @name Initializing Terrain Tiles

/**
* Initializes a terrain tile.
*
* @param sector The sector this tile covers.
* @param level The level this tile is associated with.
* @param row This tile's row in the associated level.
* @param column This tile's column in the associated level.
* @param tessellator The tessellator containing this tile.
*
* @return This terrain tile, initialized.
*
* @exception NSInvalidArgumentException if the specified sector, level or tessellator are nil,
* or the row and column numbers are less than zero.
*/
- (WWTerrainTile*) initWithSector:(WWSector*)sector
                            level:(WWLevel*)level
                              row:(int)row
                           column:(int)column
                      tessellator:(WWTessellator*)tessellator;

/// @name Operations on Terrain Tiles

/**
* Computes a point on the terrain at a specified latitude and longitude.
*
* @param latitude The point's latitude.
* @param longitude The point's longitude.
* @param offset An offset in meters from the terrain surface at which to place the point. The returned point is
* displaced by this amount along the normal vector _to the globe_.
* @param result A pointer to a vector in which to store the result.
*
* @exception NSInvalidArgumentException If the result pointer is nil.
*/
- (void) surfacePoint:(double)latitude longitude:(double)longitude offset:(double)offset result:(WWVec4*)result;

@end