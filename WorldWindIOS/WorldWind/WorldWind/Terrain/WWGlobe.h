/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

@class WWDrawContext;
@class WWLine;
@class WWPosition;
@class WWTerrainTileList;
@class WWTessellator;
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
{
@protected
    WWPosition* tmpPos;
}

/// @name Globe Attributes

/// The globe's equatorial radius.
@property(readonly, nonatomic) double equatorialRadius;

/// The globe's polar radius.
@property(readonly, nonatomic) double polarRadius;

// The square of the globe's eccentricity.
@property(readonly, nonatomic) double es;

/// The WWTessellator used to generate the globe's terrain geometry.
@property(readonly, nonatomic) WWTessellator* tessellator;

/**
* The elevation model used to provide the globe with elevation data.
*
* The elevation model is used by the methods elevationForLatitude:longitude:,
* elevationsForSector:numLat:numLon:targetResolution:verticalExaggeration:result:, and
* minAndMaxElevationsForSector:result:. Additionally, the elevation model is used indirectly used by the tessellator
* to supply the terrain geometry with elevations at each tessellated location. Initialized to WWEarthElevationModel.
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
* @param result The WWVec4 instance in which to store the result.
*
* @exception NSInvalidArgumentException If the specified result instance is nil.
*/
- (void) computePointFromPosition:(double)latitude
                        longitude:(double)longitude
                         altitude:(double)altitude
                      outputPoint:(WWVec4*)result;

/**
* Computes a grid of Cartesian points within a specified sector and relative to a specified Cartesian offset.
*
* This method is used to compute a collection of points within a sector. It is used by tessellators to efficiently
* generate a tile's interior points. The number of points to generate is indicated by the numLat and numLon
* parameters, which specify respectively the number of points to generate in the latitudinal and longitudinal
* directions. In addition to the specified numLat and numLon points, this method generates an additional row and column
* of points along the sector's outer edges. These border points have the same latitude and longitude as the points on
* the sector's outer edges, but use the constant borderElevation instead of values from the array of elevations.
*
* For each implied position within the sector, an elevation value is specified via an array of elevations. The
* calculation at each position incorporates the associated elevation. The array of elevations need not supply elevations
* for the border points, which use the constant borderElevation.
*
* @param sector The sector over which to generate the points.
* @param numLat The number of points to generate latitudinally.
* @param numLon The number of points to generate longitudinally.
* @param metersElevation An array of elevations to incorporate in the point calculations. There must be one elevation
* value in the array for each generated point - ignoring border points - so there must be numLat x numLon elements in
* the array.
* @param borderElevation The constant elevation assigned to border points.
* @param offset The X, Y and Z Cartesian coordinates to subtract from the computed coordinates. This makes the computed
* coordinates relative to the specified offset.
* @param result An array to hold the computed coordinates. It must be at least of size
* ((numLat + 2) x (numLon + 2) x stride) floats.
* The positions are returned in row major order, beginning with the row of minimum latitude.
* @param stride The number of floats between successive points in the output array. Specifying a stride of 3 indicates
* that the points are tightly packed in the output array.
* @param resultElevations An array to hold the elevation for each computed point. This elevation has vertical
* exaggeration applied.
*
* @exception NSInvalidArgumentException If any argument is nil, or if numLat or numLon are less than or equal to zero,
* or if stride is less than 3.
*/
- (void) computePointsFromPositions:(WWSector*)sector
                             numLat:(int)numLat
                             numLon:(int)numLon
                    metersElevation:(double[])metersElevation
                    borderElevation:(double)borderElevation
                             offset:(WWVec4*)offset
                        outputArray:(float[])result
                       outputStride:(int)stride
                   outputElevations:(float[])resultElevations;

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

/**
* Computes a unit length vector that is normal to the globe's surface at a specified geographic position.
*
* @param latitude The latitude at which to compute the surface normal.
* @param longitude The longitude at which to compute the surface normal.
* @param result A WWVec4 instance in which to return the surface normal.
*
* @exception NSInvalidArgumentException If the result is nil.
*/
- (void) surfaceNormalAtLatitude:(double)latitude longitude:(double)longitude result:(WWVec4*)result;

/**
* Computes a unit length vector that is normal to this globe's surface at a specified point in model coordinates.
*
* @param x The x coordinate of the point.
* @param y The y coordinate of the point.
* @param z The z coordinate of the point.
* @param result A WWVec4 instance in which to return the surface normal.
*
* @exception NSInvalidArgumentException If either argument is nil.
*/
- (void) surfaceNormalAtPoint:(double)x y:(double)y z:(double)z result:(WWVec4*)result;

/**
* Computes a unit length vector that points north and is tangent to this globe's surface at a specified geographic
* position.
*
* @param latitude The latitude at which to compute the north tangent.
* @param longitude The longitude at which to compute the north tangent.
* @param result A WWVec4 instance in which to return the north tangent.
*
* @exception NSInvalidArgumentException If the result is nil.
*/
- (void) northTangentAtLatitude:(double)latitude longitude:(double)longitude result:(WWVec4*)result;

/**
* Computes a unit length vector that points north and is tangent to this globe's surface at a specified point in model
* coordinates.
*
* @param x The x coordinate of the point.
* @param y The y coordinate of the point.
* @param z The z coordinate of the point.
* @param result A WWVec4 instance in which to return the north tangent.
*
* @exception NSInvalidArgumentException If either argument is nil.
*/
- (void) northTangentAtPoint:(double)x y:(double)y z:(double)z result:(WWVec4*)result;

/// @name Computing Globe-Ray Intersections

/**
* Computes the first intersection of this globe with the specified ray, returning whether the ray intersects this globe.
*
* This interprets the specified line as a ray; intersection points behind the line's origin are ignored.
*
* @param ray The ray to intersect with this globe.
* @param result A WWVec4 instance in which to return the intersection point.
*
* @return YES if the ray intersects this globe, otherwise NO.
*
* @exception NSInvalidArgumentException If either argument is nil.
*/
- (BOOL) intersectWithRay:(WWLine*)ray result:(WWVec4*)result;

/// @name Retrieving Globe Elevations

/**
* Indicates the date and time at which any elevations associated with the globe last changed.
*
* The returned NSTimeInterval indicates the time since the reference date that the elevations last changed. See
* `NSDate timeIntervalSinceReferenceDate` for more information. This can be used to invalidate cached computations based
* on the globe's elevations.
*
* @return The globe's elevation timestamp as an NSTimeInterval since the reference date.
*/
- (NSTimeInterval) elevationTimestamp;

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
* Returns the globe's minimum elevation, which is typically negative.
*
* @return The globe's minimum elevation, in model coordinates.
*/
- (double) minElevation;

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