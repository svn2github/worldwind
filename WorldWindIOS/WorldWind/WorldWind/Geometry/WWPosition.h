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

/**
* Initializes a position to the latitude, longitude and altitude of a specified CLLocation and altitude.
*
* The position's latitude and longitude are taken directly from the specified CLLocation's coordinate property.
*
* @param location The position containing the latitude and longitude.
* @param metersAltitude The altitude, in meters.
*
* @return The initialized position.
*
* @exception NSInvalidArgumentException If the specified location is nil.
*/
- (WWPosition*) initWithCLLocation:(CLLocation*)location altitude:(double)metersAltitude;

/**
* Initializes a position to the latitude, longitude and altitude of a specified CLLocation.
*
* The position's latitude and longitude are taken directly from the specified CLLocation's coordinate property. The
* position's altitude is taken from the CLLocation's altitude property.
*
* @param location The position containing the latitude, longitude and altitude.
*
* @return The initialized position.
*
* @exception NSInvalidArgumentException If the specified location is nil.
*/
- (WWPosition*) initWithCLPosition:(CLLocation*)location;

/**
* Initializes a position to the latitude, longitude and altitude of a specified CLLocation and altitude.
*
* The location's latitude and longitude are taken directly from the specified CLLocationCoordinate2D's latitude
* and longitude fields.
*
* @param locationCoordinate The location coordinate containing the latitude and longitude.
* @param metersAltitude The altitude, in meters.
*
* @return The initialized position.
*/
- (WWPosition*) initWithCLCoordinate:(CLLocationCoordinate2D)locationCoordinate altitude:(double)metersAltitude;

/**
* Initializes a position with its latitude, longitude and altitude set to 0.
*
* @return The initialized position.
*/
- (WWPosition*) initWithZeroPosition;

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

/**
* Sets a position to the latitude, longitude and altitude of a specified CLLocation and altitude.
*
* The position's latitude and longitude are taken directly from the specified CLLocation's coordinate property.
*
* @param location The position containing the new latitude and longitude.
* @param metersAltitude The altitude, in meters.
*
* @return  This position with the specified latitude, longitude and altitude.
*
* @exception NSInvalidArgumentException If the specified location is nil.
*/
- (WWPosition*) setCLLocation:(CLLocation*)location altitude:(double)metersAltitude;

/**
* Sets a position to the latitude, longitude and altitude of a specified CLLocation.
*
* The position's latitude and longitude are taken directly from the specified CLLocation's coordinate property. The
* position's altitude is taken from the CLLocation's altitude property.
*
* @param location The location containing the new latitude, longitude and altitude.
*
* @return This position with the specified latitude, longitude and altitude.
*
* @exception NSInvalidArgumentException If the specified location is nil.
*/
- (WWPosition*) setCLPosition:(CLLocation*)location;

/**
* Sets a position to the latitude, longitude and altitude of a specified CLLocationCoordinate2D and altitude.
*
* The location's latitude and longitude are taken directly from the specified CLLocationCoordinate2D's latitude
* and longitude fields.
*
* @param locationCoordinate The location coordinate containing the latitude and longitude.
* @param metersAltitude The altitude, in meters.
*
* @return This position with the specified latitude, longitude and altitude.
*/
- (WWPosition*) setCLCoordinate:(CLLocationCoordinate2D)locationCoordinate altitude:(double)metersAltitude;

/// @name Common Geographic Operations

/**
* TODO
*
* @param beginPosition TODO
* @param endPosition TODO
* @param amount TODO
* @param result TODO
*
* @exception TODO
*/
+ (void) greatCircleInterpolate:(WWPosition*)beginPosition
                    endPosition:(WWPosition*)endPosition
                         amount:(double)amount
                 outputPosition:(WWPosition*)result;

/**
* TODO
*
* @param beginPosition TODO
* @param endPosition TODO
* @param amount TODO
* @param result TODO
*
* @exception TODO
*/
+ (void) rhumbInterpolate:(WWPosition*)beginPosition
              endPosition:(WWPosition*)endPosition
                   amount:(double)amount
           outputPosition:(WWPosition*)result;

/**
* TODO
*
* @param beginPosition TODO
* @param endPosition TODO
* @param amount TODO
* @param result TODO
*
* @exception TODO
*/
+ (void) linearInterpolate:(WWPosition*)beginPosition
               endPosition:(WWPosition*)endPosition
                    amount:(double)amount
            outputPosition:(WWPosition*)result;

/**
* TODO
*
* @param location TODO
* @param date TODO
* @param globe TODO
* @param result TODO
*
* @exception TODO
*/
+ (void) forecastPosition:(CLLocation*)location
                  forDate:(NSDate*)date
                  onGlobe:(WWGlobe*)globe
           outputPosition:(WWPosition*)result;
@end