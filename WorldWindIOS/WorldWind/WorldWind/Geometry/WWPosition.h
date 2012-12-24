/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WorldWind/Geometry/WWLocation.h"

/**
* Represents a geographic positions as a latitude, longitude, altitude triple and provides operations on and between
* positions. Often within World Wind the altitude field is considered an elevation.
*
* @warning WWPosition instances are mutable. Most methods of this class modify the instance, itself.
*/

@interface WWPosition : WWLocation

/// @name Position Attributes

/**
* The position's altitude.
*/
@property (nonatomic) double altitude;

/// @name Initializing Positions

/**
* Initializes a position to a specified latitude, longitude and altitude.
*
* @param latitude The position's latitude.
* @param longitude The position's longitude.
* @param altitude The position's altitude.
*
* @return The initialized position.
*/
- (WWPosition*) initWithDegreesLatitude:(double)latitude longitude:(double)longitude altitude:(double)altitude;

/// @name Setting the Contents of Positions

/**
* Sets the values of this position to specified values.
*
* @param latitude The position's latitude.
* @param longitude The position's longitude.
* @param altitude The position's altitude.
*
* @return The initialized position.
*/
- (WWPosition*) setDegreesLatitude:(double)latitude longitude:(double)longitude altitude:(double)altitude;

@end
