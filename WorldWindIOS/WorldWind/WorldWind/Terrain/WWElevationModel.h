/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>

@class WWSector;

/**
* Provides the elevations to a WWGlobe or other object holding elevations.
*
* An elevation model may store its backing data in memory or may retrieve it on demand from an external source. The
* methods elevationForLatitude:longitude: and minAndMaxElevationsForSector:result: operate on the elevation data
* currently in memory, and therefore are not guaranteed to provide meaningful results until after
* elevationsForSector:numLat:numLon:targetResolution:verticalExaggeration:result: has been called.
*
* An elevation model often approximates elevations at multiple levels of spatial resolution. A target resolution may not
* be immediately achievable, however, because the corresponding elevation data might not be locally available and must
* be retrieved from a remote location.  When this is the case, the value returned by
* elevationsForSector:numLat:numLon:targetResolution:verticalExaggeration:result: identifies the resolution achievable
* with the data currently available. That resolution may not be the same as the target resolution.
*/
@protocol WWElevationModel <NSObject>

/// @name Elevation Model Attributes

/**
* Indicates the date and time at which the elevation model last changed.
*
* This can be used to invalidate cached computations based on the elevation model's values.
*
* @return The elevation model's timestamp as an NSDate.
*/
- (NSDate*) timestamp;

/// @name Retrieving Elevations

/**
* Return the elevation at a specified location.
*
* The elevation returned is that determined from the set of elevations currently in memory, which may not reflect the
* highest resolution the elevation model is capable of.
*
* @param latitude The location's latitude.
* @param longitude The location's longitude.
*
* @return The elevation at the specified location, or 0 if the location is outside the elevation model's coverage area.
*/
- (double) elevationForLatitude:(double)latitude longitude:(double)longitude;

/**
* Return a grid of elevations within a specified sector.
*
* If a location within the elevation model's coverage area cannot currently be determined, the elevation model's minimum
* extreme elevation is returned for that location. If a location is outside the elevation model's coverage area, the
* output array for that location is not modified; it retains the array's original value.
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
* for all of the locations. Returns 0 the sector is outside the elevation model's coverage area.
*
* @exception NSInvalidArgumentException If the sector is nil, the result is nil, or numLat or numLon are not positive.
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
* If the sector is outside the elevation model's coverage area, the result array is not modified; it retains the
* array's original values.
*
* @param sector The sector whose minimum and maximum are to be found.
* @param result An array in which to hold the returned minimum (index 0) and maximum (index 1). These elevations are
* taken from those currently in memory, which may not reflect the highest resolution the elevation model is capable of.
*
* @exception NSInvalidArgumentException If either the sector or the result is nil.
*/
- (void) minAndMaxElevationsForSector:(WWSector*)sector result:(double[])result;

@end