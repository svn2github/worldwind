/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

@class WWLocation;
@class WWGlobe;
@class WWBoundingBox;
@class WWBoundingSphere;

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
* Initializes a sector to the values of a specified sector.
*
* @param sector The sector whose values to copy.
*
* @return This sector initialized to the latitudes and longitudes of the specified sector.
*
* @exception NSInvalidArgumentException If the specified sector is nil.
*/
- (WWSector*) initWithSector:(WWSector*)sector;

/**
* Initializes a sector to the geographic bounds of the specified locations.
*
* The locations array must contain at least one element. The elements in the array may be of type WWLocation or
* WWPosition.
*
* @param locations The locations to bound.
*
* @return This sector initialized to the bounds of the specified locations.
*
* @exception NSInvalidArgumentException If locations is nil or empty.
*/
- (WWSector*) initWithLocations:(NSArray*)locations;

/**
* Initializes a sector defining the full extent of the globe: minimum and maximum latitudes of -90 and 90, and minimum
* and maximum longitudes of -180 and 180.
*
* @return This sector initialized to the full sphere.
*/
- (WWSector*) initWithFullSphere;

/// @name Changing Sector Values

/**
* Sets this sector to the values of a specified sector.
*
* @param sector The sector whose values should be used.
*
* @return This sector with its values set to the latitudes and longitudes of the specified sector.
*
* @exception NSInvalidArgumentException If the specified sector is nil.
*/
- (WWSector*) set:(WWSector*)sector;

/// @name Intersection and Inclusion Operations

/**
* Indicates whether this sector is empty.
*
* A sector is considered empty when its latitudinal span and longitudinal span are zero, regardless of the location of
* its coordinates.
*
* @return YES if this sector is empty, otherwise NO.
*/
- (BOOL) isEmpty;

/**
* Indicates whether this sector intersects a specified sector.
*
* @param sector The sector to test intersection with. May by nil, in which case this method returns NO.
*
* @return YES if the sectors intersect, otherwise NO.
*/
- (BOOL) intersects:(WWSector*)sector;

/**
* Indicates whether this sector contains a specified geographic location.
*
* @param latitude The latitude to test.
* @param longitude The longitude to test.
*
* @return YES if the sector contains the location, otherwise NO.
*/
- (BOOL) contains:(double)latitude longitude:(double)longitude;

/// @name Operations on Sectors

/**
* Sets this sector to the intersection of this sector and a specified sector.
*
* If the two sectors are disjoint this sector is considered empty and isEmpty returns YES.
*
* @param sector The sector to intersect with this one.
*
* @exception NSInvalidArgumentException If the specified sector is nil.
*/
- (void) intersection:(WWSector*)sector;

/**
* Sets this sector to the union of this sector and a specified sector.
*
* @param sector The sector to union with this one.
*
* @exception NSInvalidArgumentException If the specified sector is nil.
*/
- (void) union:(WWSector*)sector;

/// @name Other Information About Sectors

/**
* Compute the model coordinate points of this sector's four corners and its center at the specified elevation.
*
* The elevation must have already been multiplied by the desired vertical exaggeration, if any.
*
* @param globe The globe used to compute the model coordinates of the reference points.
* @param elevation The elevation associated with the reference points.
* @param result A mutable array of points. The array and its points may not be nil. The points in the
* array are computed in the following order: southwest, southeast, northeast, northwest, center.
*
* @exception NSInvalidArgumentException if the globe or output array are nil.
*/
- (void) computeReferencePoints:(WWGlobe*)globe elevation:(double)elevation result:(NSMutableArray*)result;

/**
* Computes the extreme points of this sector, given a minimum and maximum elevation associated with this sector.
*
* These points are typically used to form a bounding volume for the sector.
*
* * To compute points of extreme latitude and longitude at mean sea level, specify zero for the minimum and maximum
* elevations.
* * To compute points of extreme latitude and longitude that contain the terrain surface, specify the actual minimum and
* maximum elevation values associated with this sector, multiplied by the scene's vertical exaggeration. These values
* can be determined by calling [WWGlobe minAndMaxElevationsForSector:result:] and [WWDrawContext verticalExaggeration].
* The extreme points must be recomputed whenever the globe's elevations or the vertical exaggeration changes. The method
* [WWGlobe elevationTimestamp] can be used to determine when the elevations change.
*
* @param globe The globe used to compute the model coordinates of the extreme points.
* @param minElevation The minimum elevation associated with this sector.
* @param maxElevation The maximum elevation associated with this sector.
* @param result An array in which to return the extreme points.
*
* @exception NSInvalidArgumentException if either the specified globe or result array is nil.
*/
- (void) computeExtremePoints:(WWGlobe*)globe
                 minElevation:(double)minElevation
                 maxElevation:(double)maxElevation
                       result:(NSMutableArray*)result;

/**
* Computes a bounding box for this sector, given a minimum and maximum elevation associated with this sector.
*
* * To compute a bounding box that contains the sector at mean sea level, specify zero for the minimum and maximum
* elevations.
* * To compute a bounding box that contains the terrain surface in this sector, specify the actual minimum and maximum
* elevation values associated with this sector, multiplied by the scene's vertical exaggeration. These values can be
* determined by calling [WWGlobe minAndMaxElevationsForSector:result:] and [WWDrawContext verticalExaggeration]. The
* returned bounding box must be recomputed whenever the globe's elevations or the vertical exaggeration changes. The
* method [WWGlobe elevationTimestamp] can be used to determine when the elevations change.
*
* @param globe The globe used to compute the model coordinates of the bounding box.
* @param minElevation The minimum elevation associated with this sector.
* @param maxElevation The maximum elevation associated with this sector.
*
* @return A bounding box for this sector.
*
* @exception NSInvalidArgumentException if the specified globe is nil.
*/
- (WWBoundingBox*) computeBoundingBox:(WWGlobe*)globe
                         minElevation:(double)minElevation
                         maxElevation:(double)maxElevation;

@end
