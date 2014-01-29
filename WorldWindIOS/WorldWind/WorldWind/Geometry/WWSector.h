/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

@class WWBoundingBox;
@class WWBoundingSphere;
@class WWGlobe;
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
* Computes the center of this sector's latitudinal span.
*
* @return The center of this sector's latitudinal span, in degrees.
*/
- (double) centroidLat;

/**
* Computes the center of this sector's longitudinal span.
*
* @return The center of this sector's longitudinal span, in degrees.
*/
- (double) centroidLon;

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
* Returns the radius in degrees of a circle that circumscribes this sector.
*
* A circle centered at this sector's centroid and with the returned radius will circumscribe this sector's four corners
* in geographic coordinates. Note that if this sector's corners are projected into another coordinate system, such a
* circle would not circumscribe the projected four corners.
*
* The returned radius is zero when this sector's latitudinal span and longitudinal span are zero.
*
* @return The radius of a circle that circumscribes this sector, in degrees.
*/
- (double) circumscribingRadius;

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
* @exception NSInvalidArgumentException If the sector is nil.
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

- (WWSector*) initWithWorldFile:(NSString*)worldFilePath width:(int)width height:(int)height;

/// @name Changing Sector Values

/**
* Sets this sector to the latitudes and longitudes of a specified sector.
*
* @param sector The sector whose values should be used.
*
* @exception NSInvalidArgumentException If the sector is nil.
*/
- (void) set:(WWSector*)sector;

/**
* Sets this sector to the geographic bounds of the specified locations.
*
* The locations array must contain at least one element. The elements in the array may be of type WWLocation or
* WWPosition.
*
* @param locations The locations to bound.
*
* @exception NSInvalidArgumentException If locations is nil or empty.
*/
- (void) setToLocations:(NSArray*)locations;

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
* This sector intersects the specified sector when each of sector's boundaries either overlap with the specified
* sector or are adjacent to the specified sector.
*
* @param sector The sector to test intersection with. May by nil, in which case this method returns NO.
*
* @return YES if the sectors intersect, otherwise NO.
*/
- (BOOL) intersects:(WWSector*)sector;

/**
* Indicates whether this sector overlaps a specified sector.
*
* This sector overlaps the specified sector when the union of the two sectors defines a non-empty sector.
*
* @param sector The sector to test overlap with. May be nil, in which case this method returns NO.
*
* @return YES if the sectors overlap, otherwise NO.
*/
- (BOOL) overlaps:(WWSector*)sector;

/**
* Indicates whether this sector contains a specified sector.
*
* This sector contains the specified sector when the specified sector's boundaries are completely contained within this
* sector's boundaries, or are equal to this sector's boundaries.
*
* @param sector The sector to test containment with. May be nil, in which case this method returns NO.
*
* @return YES if this sector contains the specified sector, otherwise NO.
*/
- (BOOL) contains:(WWSector*)sector;

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
* @exception NSInvalidArgumentException If the sector is nil.
*/
- (void) intersection:(WWSector*)sector;

/**
* Sets this sector to the union of this sector and a specified sector.
*
* @param sector The sector to union with this one.
*
* @exception NSInvalidArgumentException If the sector is nil.
*/
- (void) union:(WWSector*)sector;

/**
* Sets this sector to the union of this sector and a specified location.
*
* @param location The location to union with this sector.
*
* @exception NSInvalidArgumentException If the location is nil.
*/
- (void) unionWithLocation:(WWLocation*)location;

@end