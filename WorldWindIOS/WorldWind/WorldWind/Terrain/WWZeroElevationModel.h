/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WorldWind/Terrain/WWElevationModel.h"

/**
* An elevation model that always returns zero elevations.
*
* Zero elevation model covers the full extent of the globe, and therefore provides a zero value for all geographic
* locations.
*/
@interface WWZeroElevationModel : NSObject <WWElevationModel>

/// @name Attributes

/// Indicates the date and time at which the elevation model last changed.
/// Since a zero elevation model never changes, this always returns the date and time at which the elevation model was
/// initialized.
@property(readonly) NSDate* timestamp;

/// Indicates the elevation model's minimum elevation for all values in the model. This property is always zero.
@property(nonatomic, readonly) double minElevation;

/// Indicates the elevation model's maximum elevation for all values in the model. This property is always zero.
@property(nonatomic, readonly) double maxElevation;

/// @name Retrieving Elevations

/**
* Return the elevation at a specified location. The returned value is always zero.
*
* @param latitude The location's latitude.
* @param longitude The location's longitude.
*
* @return The elevation at the specified location. The returned value is always zero.
*/
- (double) elevationForLatitude:(double)latitude longitude:(double)longitude;

/**
* Return a grid of elevations within a specified sector. The first numLat x numLon floats in the result array are filled
* with zero.
*
* @param sector The sector over which to generate the grid of elevations.
* @param numLat The number of elevations to generate in the latitudinal direction.
* @param numLon The number of elevations to generate in the longitudinal direction.
* @param targetResolution The desired horizontal resolution, in radians, of the raster or other elevation sample from
* which elevations are drawn. This parameter is ignored by zero elevation model.
* @param verticalExaggeration Elevation values are multiplied by this value prior to being returned. This parameter is
* ignored by zero elevation model.
* @param result The array of floats in which the elevations are returned. The array must be pre-allocated and
* contain space for numLat x numLon floats.
*
* @return The horizontal resolution achieved. This returns 1 since zero elevation model has no defined resolution, but
* must return a value indicating that elevations can be determined for the locations and that the sector is within the
* model's coverage area.
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
* Returns the minimum and maximum elevations for a specified sector. The first two floats in the result array are filled
* with zero.
*
* @param sector The sector whose minimum and maximum are to be found.
* @param result An array in which to hold the returned minimum (index 0) and maximum (index 1).
*
* @exception NSInvalidArgumentException If either the sector or the result is nil.
*/
- (void) minAndMaxElevationsForSector:(WWSector*)sector result:(double[])result;

@end