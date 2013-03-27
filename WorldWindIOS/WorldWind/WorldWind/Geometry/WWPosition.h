/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WorldWind/Geometry/WWLocation.h"

/**
* Represents a geographic positions as a latitude, longitude, altitude triple and provides operations on and between
* positions.
*
* Often within World Wind the altitude field is considered an elevation.
*
* @warning WWPosition instances are mutable. Most methods of this class modify the instance, itself.
*/

@interface WWPosition : WWLocation

/// @name Position Attributes

/**
* The position's altitude, in meters.
*/
@property (nonatomic) double altitude;

/// @name Initializing Positions

/**
* Initializes a position to a specified latitude, longitude and altitude.
*
* @param latitude The position's latitude, in degrees.
* @param longitude The position's longitude, in degrees.
* @param metersAltitude The position's altitude, in meters.
*
* @return The initialized position.
*/
- (WWPosition*) initWithDegreesLatitude:(double)latitude longitude:(double)longitude altitude:(double)metersAltitude;

/**
* Initializes a position to the latitude, longitude and altitude of a specified location and altitude.
*
* @param location The location containing the latitude and longitude.
* @param metersAltitude The altitude, in meters.
*
* @return The initialized position.
*
* @exception NSInvalidArgumentException If the specified location is nil.
*/
- (WWPosition*) initWithLocation:(WWLocation*)location altitude:(double)metersAltitude;

/**
* Initializes a position to the latitude, longitude and altitude of a specified position.
*
* @param position The position containing the latitude, longitude and altitude.
*
* @return The initialized position.
*
* @exception NSInvalidArgumentException If the specified position is nil.
*/
- (WWPosition*) initWithPosition:(WWPosition*)position;

/// @name Setting the Contents of Positions

/**
* Sets the position's latitude, longitude and altitude to specified values.
*
* @param latitude The new latitude, in degrees.
* @param longitude The new longitude, in degrees.
* @param metersAltitude The new altitude, in meters.
*
* @return This position with the specified latitude, longitude and altitude.
*/
- (WWPosition*) setDegreesLatitude:(double)latitude longitude:(double)longitude altitude:(double)metersAltitude;

/**
* Sets a position to the latitude, longitude and altitude of a specified location and altitude.
*
* @param location The location containing the new latitude and longitude.
* @param metersAltitude The new altitude, in meters.
*
* @return This position with the specified latitude, longitude and altitude.
*
* @exception NSInvalidArgumentException If the specified location is nil.
*/
- (WWPosition*) setLocation:(WWLocation*)location altitude:(double)metersAltitude;

/**
* Sets a position to the latitude, longitude and altitude of a specified position.
*
* @param position The position containing the new latitude, longitude and altitude.
*
* @return This position with the specified latitude, longitude and altitude.
*
* @exception NSInvalidArgumentException If the specified position is nil.
*/
- (WWPosition*) setPosition:(WWPosition*)position;

@end