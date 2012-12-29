/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

/**
* Represents a geographic location as a latitude/longitude pair and provides operations on and between location
* coordinates.
*
* @warning WWLocation instances are mutable. Most methods of this class modify the instance, itself.
*/

@interface WWLocation : NSObject <NSCopying>

/// @name Location Attributes

/**
* This location's latitude in degrees.
*/
@property (nonatomic) double latitude;
/**
* This location's longitude in degrees.
*/
@property (nonatomic) double longitude;

/// @name Initializing Locations

/**
* Initializes a location to specified latitude and longitude.
*
* @param latitude The location's latitude in degrees.
* @param longitude The location's longitude in degrees.
*
* @return The initialized location.
*/
- (WWLocation*) initWithDegreesLatitude:(double)latitude longitude:(double)longitude;

/// @name Setting the Contents of Locations

/**
* Specifies a location's latitude and longitude.
*
* @param latitude The location's latitude.
* @param longitude The location's longitude.
*
* @return This location with the specified latitude and longitude.
*/
- (WWLocation*) setDegreesLatitude:(double)latitude longitude:(double)longitude;

/**
* Sets a location to the latitude and longitude of a specified location.
*
* @param location The location containing the new latitude and longitude.
*
* @return This location with the specified latitude and longitude.
*
* @exception NSInvalidArgumentException If the specified location is nil.
*/
- (WWLocation*) setLocation:(WWLocation*)location;

/**
* Sets this location to the end of a great circle path specified by an azimuth and distance.
*
* @param startLocation The beginning location of the great circle path.
* @param azimuth The direction, in degrees clockwise from north, of the great circle path.
* @param distance The angular distance, in degrees, between the start location of the path and its end location.
*
* @return This instance set to the end position of the specified great circle path.
*
* @exception NSInvalidArgumentException If the specified start location is nil.
*/
- (WWLocation*) setGreatCircleEndLocation:(WWLocation*)startLocation azimuth:(double)azimuth distance:(double)distance;

/**
* Sets this location to the end of a rhumb path specified by an azimuth and distance.
*
* @param startLocation The beginning location of the rhumb path.
* @param azimuth The direction, in degrees clockwise from north, of the rhumb path.
* @param distance The angular distance, in degrees, between the start location of the path and its end location.
*
* @return This instance set to the end position of the specified rhumb path.
*
* @exception NSInvalidArgumentException If the specified start location is nil.
*/
- (WWLocation*) setRhumbEndLocation:(WWLocation*)startLocation azimuth:(double)azimuth distance:(double)distance;

/// @name Operations on Locations

/**
* Adds a specified location's latitude and longitude to this location's latitude and longitude.
*
* @param location The location whose latitude and longitude are to be added.
*
* @return This location with the specified location added to it.
*
* @exception NSInvalidArgumentException If the specified location is nil.
*/
- (WWLocation*) addLocation:(WWLocation*)location;

/**
* Subtracts a specified location's latitude and longitude from this location's latitude and longitude.
*
* @param location The location whose latitude and longitude are to be subtracted from this location.
*
* @return This location with the specified location subtracted from it.
*
* @exception NSInvalidArgumentException If the specified location is nil.
*/
- (WWLocation*) subtractLocation:(WWLocation*)location;

@end
