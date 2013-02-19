/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

@class WWTessellator;
@class WWTerrainTile;
@class WWTerrainTileList;
@class WWDrawContext;
@class WWPosition;
@class WWSector;
@class WWVec4;
@protocol WWElevationModel;

/**
* Represents a globe. The default values represent Earth.
*
* A globe is used by the scene controller (WWSceneController) to generate terrain.
*
* The globe uses a Cartesian coordinate system in which the Y axis points to the north pole,
* the Z axis points to the intersection of the prime meridian and the equator,
* and the X axis completes a right-handed coordinate system, is in the equatorial plane and 90 degree east of the Z
* axis. The origin of the coordinate system lies at the center of the globe.
*/
@interface WWGlobe : NSObject

/// @name Globe Attributes

/// The globe's equatorial radius.
@property(readonly, nonatomic) double equatorialRadius;

/// The globe's polar radius.
@property(readonly, nonatomic) double polarRadius;

// The square of the globe's eccentricity.
@property(readonly, nonatomic) double es;

/// The globe's minimum elevation, which is typically negative.
@property(readonly, nonatomic) double minElevation;

/// The WWTessellator used to generate the globe's terrain geometry.
@property(readonly, nonatomic) WWTessellator* tessellator;

/**
* The elevation model used to provide the globe with elevation data.
*
* The elevation model is used by the methods elevationForLatitude:longitude:,
* elevationsForSector:numLat:numLon:targetResolution:verticalExaggeration:result:, and
* minAndMaxElevationsForSector:result:. Additionally, the elevation model is used indirectly used by the tessellator
* to supply the terrain geometry with elevations at each tessellated location. Initialized to WWZeroElevationModel.
*/
@property(nonatomic) id<WWElevationModel> elevationModel;

/// @name Initializing a Globe

/**
* Initializes a globe to represent Earth.
*
* @return This globe initialized with the radii and eccentricity of Earth.
*/
- (WWGlobe*) init;

/// @name Generating a Globe's Terrain

- (WWTerrainTileList*) tessellate:(WWDrawContext*)dc;

/// @name Computing Points and Other Information for the Globe

/**
* Compute a Cartesian point from a specified position.
*
* See this class' Overview section for a description of the Cartesian coordinate system used.
*
* @param latitude The position's latitude.
* @param longitude The position's longitude.
* @param altitude The position's altitude.
* @param result The Position instance in which to store the result.
*
* @exception NSInvalidArgumentException If the specified result instance is nil.
*/
- (void) computePointFromPosition:(double)latitude
                        longitude:(double)longitude
                         altitude:(double)altitude
                      outputPoint:(WWVec4*)result;

/**
* Compute a Cartesian point from a specified position and relative to a Cartesian offset.
*
* This method is typically used to compute points on the globe relative to a local reference point,
* such as the center of a terrain tile.
*
* See this class' Overview section for a description of the Cartesian coordinate system used.
*
* @param latitude The position's latitude.
* @param longitude The position's longitude.
* @param altitude The position's altitude.
* @param offset The X, Y and Z Cartesian coordinates to subtract from the computed coordinates. This makes the
* returned coordinates relative to the specified offset. This parameter may be nil,
* in which case the offset is assumed to be 0 in all three dimensions.
* @param result A three-element float array in which to store the Cartesian result.
*
* @exception NSInvalidArgumentException If the specified result instance is nil.
*/
- (void) computePointFromPosition:(double)latitude
                        longitude:(double)longitude
                         altitude:(double)altitude
                           offset:(WWVec4*)offset
                      outputArray:(float [])result;

/**
* Computes a grid of Cartesian points within a specified sector and relative to a specified Cartesian offset.
*
* This method is used to compute a collection of points within a sector. It is used by tessellators to efficiently
* generate a tile's interior points. The number of points to generate is indicated by the numLat and numLon
* parameters, which specify respectively the number of points to generate in the latitudinal and longitudinal
* directions.
*
* For each implied position within the sector, an elevation value may be specified via an array of elevations. The
* calculation at each position incorporates the associated elevation. If elevations are not specified,
* a constant elevation must be specified. That constant elevation is applied to all computed points.
*
* @param sector The sector over which to generate the points.
* @param numLat The number of points to generate latitudinally.
* @param numLon The number of points to generate longitudinally.
* @param metersElevation If not nil, specifies an array of elevations to incorporate in the point calculations. There
 * must be one elevation value in the array for each generated point, so there must be numLat x numLon elements in
 * the array.
 * @param constantElevation If metersElevation is nil, specifies a pointer to an elevation value that is applied
 * uniformly across the grid of points generated.
* @param offset The X, Y and Z Cartesian coordinates to subtract from the computed coordinates. This makes the
* returned coordinates relative to the specified offset. This parameter may be nil,
* in which case the offset is assumed to be 0 in all three dimensions.
* @param result An array to hold the computed coordinates. It must be at least of size numLat x numLon x 3 floats.
* The positions are returned in row major order, beginning with the row of minimum latitude.
*
* @exception NSInvalidArgumentException If the sector is nil, result is nil, numLat or numLon are less than or equal
* to 0, or both metersElevation and constantElevation are nil.
*/
- (void) computePointsFromPositions:(WWSector*)sector
                             numLat:(int)numLat
                             numLon:(int)numLon
                    metersElevation:(double [])metersElevation
                  constantElevation:(double*)constantElevation
                             offset:(WWVec4*)offset
                        outputArray:(float [])result;

/**
* Computes a position from a specified Cartesian point.
*
* See this class' Overview section for a description of the Cartesian coordinate system used.
*
* @param x The x coordinate of the point.
* @param y The y coordinate of the point.
* @param z The z coordinate of the point.
* @param result A WWPosition instance in which to return the computed position.
*
* @exception NSInvalidArgumentException If result is nil.
*/
- (void) computePositionFromPoint:(double)x
                                y:(double)y
                                z:(double)z
                   outputPosition:(WWPosition*)result;

- (void) computeNormal:(double)latitude
             longitude:(double)longitude
           outputPoint:(WWVec4*)result;

- (void) computeNorthTangent:(double)latitude
                   longitude:(double)longitude
                  outputPoint:(WWVec4*)result;

/**
* Computes the surface normal at a specified Cartesian point.
*
* @param point The point at which to compute the surface normal.
* @param result An WWVec4 instance in which to return the surface normal.
*
* @exception NSInvalidArgumentException If either argument is nil.
*/
- (void) surfaceNormalAtPoint:(WWVec4*)point result:(WWVec4*)result;

/// @name Retrieving Globe Elevations

/**
* Return the elevation at a specified location.
*
* The elevation returned is that determined from the set of elevations currently in memory. If the view is zoomed out
 * a significant distance from the globe, this elevation is likely to be higher than the actual elevation.
*
* @param latitude The location's latitude.
* @param longitude The location's longitude.
*
* @return The elevation at the specified location, or 0 if no elevation model is available at that location.
*/
- (double) elevationForLatitude:(double)latitude longitude:(double)longitude;

/**
* Return a grid of elevations within a specified sector.
*
* This method is used by tessellators to efficiently generate a sector's worth of elevations with one method call.
*
* If a location within the globe's elevation model's coverage area cannot currently be determined,
* the elevation model's minimum extreme elevation is returned for that location. If a location is outside the
* elevation model's coverage area, the output array for that location is not modified; it retains the array's
* original value.
*
* @param sector The sector over which to generate the grid of elevations.
* @param numLat The number of elevations to generate in the latitudinal direction.
* @param numLon The number of elevations to generate in the longitudinal direction.
* @param targetResolution The desired horizontal resolution, in radians, of the raster or other elevation sample from
* which elevations are drawn. (To compute radians from a distance, divide the distance by the radius of the globe,
* ensuring that both the distance and the radius are in the same units.)
* @param verticalExaggeration Elevation values are multiplied by this value prior to being returned.
* @param result The array of floats in which the elevations are returned. The array must be pre-allocated and
* contain space for numLat x numLon floats.
*
* @return The horizontal resolution achieved, in radians, or FLT_MAX if individual elevations cannot be determined
* for all of the locations. Returns 0 if an elevation model is not available.
*
* @exception NSInvalidArgumentException If the sector is nil, the result is nil or numLat or numLon are less than or
* equal to 0.
*/
- (double) elevationsForSector:(WWSector*)sector
                        numLat:(int)numLat
                        numLon:(int)numLon
              targetResolution:(double)targetResolution
          verticalExaggeration:(double)verticalExaggeration
                        result:(double[])result;

/**
* Returns the minimum and maximum elevations for a specified sector.
*
* @param sector The sector whose minimum and maximum are to be found.
* @param result An array in which to hold the returned minimum (index 0) and maximum (index 1). These elevations are
* taken from those currently in memory, which may not reflect the highest terrain resolution the globe is capable of.
*
* @exception NSInvalidArgumentException If either the sector or the result is nil.
*/
- (void) minAndMaxElevationsForSector:(WWSector*)sector result:(double[])result;

@end