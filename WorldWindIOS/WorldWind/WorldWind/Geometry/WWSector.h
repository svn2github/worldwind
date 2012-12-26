/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

@class WWLocation;

/**
* Represents a geographic region defined by a rectangle in degrees latitude and longitude. Sectors are used extensively
 * in World Wind to define region boundaries, especially for tiling of imagery and elevations and for declaring shape
 * and image extents.
*
* @warning WWSector instances are mutable. Most methods of this class modify the instance, itself.
*/
@interface WWSector : NSObject <NSCopying>

/// @name Sector Attributes

/// This sector's minimum latitude, in degrees.
@property(nonatomic) double minLatitude;
/// This sector's maximum latitude, in degrees.
@property(nonatomic) double maxLatitude;
/// This sector's minimum longitude, in degrees.
@property(nonatomic) double minLongitude;
/// This sector's maximum longitude, in degrees.
@property(nonatomic) double maxLongitude;

/**
* Compute this sector's latitudinal span.
*
* @return This sector's latitudinal span, in degrees.
*/
- (double) deltaLat;

/**
* Compute this sector's longitudinal span.
*
* @return This sector's longitudinal span, in degrees.
*/
- (double) deltaLon;

/**
* Returns this sector's minimum latitude in radians.
*
* @return This sector's minimum latitude in radians.
*/
- (double) minLatitudeRadians;

/**
* Returns this sector's maximum latitude in radians.
*
* @return This sector's maximum latitude in radians.
*/
- (double) maxLatitudeRadians;

/**
* Returns this sector's minimum longitude in radians.
*
* @return This sector's minimum longitude in radians.
*/
- (double) minLongitudeRadians;

/**
* Returns this sector's maximum longitude in radians.
*
* @return This sector's maximum longitude in radians.
*/
- (double) maxLongitudeRadians;

/**
* Computes and returns the center of the sector in latitude and longitude.
*
* @param result The location in which to store the computed centroid location. May not be nil. Upon return,
* the specified location instance contains this sector's centroid.
*
* @exception NSInvalidArgumentException if the result parameter is nil.
*/
- (void) centroidLocation:(WWLocation*)result;

/// @name Initializing Sectors

/**
* Initializes a sector with specified minimum and maximum latitudes and longitudes.
*
* @param minLatitude The sector's minimum latitude.
* @param maxLatitude The sector's maximum latitude.
* @param minLongitude The sector's minimum longitude.
* @param maxLongitude The sector's maximum longitude.
*
* @return This sector initialized to the specified latitudes and longitudes.
*/
- (WWSector*) initWithDegreesMinLatitude:(double)minLatitude
                             maxLatitude:(double)maxLatitude
                            minLongitude:(double)minLongitude
                            maxLongitude:(double)maxLongitude;

/**
* Initializes a sector defining the full extent of the globe: minumum and maximum latitudes of -90 and 90,
* and minimum and maximum longitudes of -180 and 180..
*
* @return This sector initialized to the full sphere.
*/
- (WWSector*) initWithFullSphere;

/// @name Intersection and inclusion operations

/**
* Indicates whether this sector intersects a specified sector.
*
* @param sector The sector to test intersection with. May by nil, in which case this method returns NO.
*
* @return YES if the sectors intersect, otherwise NO.
*/
- (BOOL) intersects:(WWSector*)sector;

@end
