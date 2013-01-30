/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@class WWGlobe;

/**
* Represents a geographic location as a latitude longitude pair and provides operations on and between location
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
* Initializes a location to the specified latitude and longitude.
*
* @param latitude The location's latitude in degrees.
* @param longitude The location's longitude in degrees.
*
* @return The initialized location.
*/
- (WWLocation*) initWithDegreesLatitude:(double)latitude longitude:(double)longitude;

/**
* Initializes a location to the specified latitude and longitude.
*
* The location's longitude is derived from the specified time zone. The time zone is converted from a time offset
* relative to Greenwich Mean Time into a longitude offset relative to the prime meridian. For example, an offset of +12
* hours is converted into a longitude offset of +180 degrees, while an offset of -12 hours is converted into a longitude
* offset of -180 degrees. This conversion ignores differences in time zone offsets at different points in the year such
* as Daylight Savings Time.
*
* @param latitude The location's latitude in degrees.
* @param timeZone The time zone associated with the location's longitude.
*
* @return The initialized location.
*
* @exception NSInvalidArgumentException If the specified time zone is nil.
*/
- (WWLocation*) initWithDegreesLatitude:(double) latitude timeZoneForLongitude:(NSTimeZone*)timeZone;

/**
* Initializes a location to the latitude and longitude of a specified location.
*
* @param location The location containing the latitude and longitude.
*
* @return The initialized location.
*
* @exception NSInvalidArgumentException If the specified location is nil.
*/
- (WWLocation*) initWithLocation:(WWLocation*)location;

/**
* Initializes a location to the latitude and longitude of a specified CLLocation.
*
* The location's latitude and longitude are taken directly from the specified CLLocation's coordinate property.
*
* @param location The location containing the latitude and longitude.
*
* @return The initialized location.
*
* @exception NSInvalidArgumentException If the specified location is nil.
*/
- (WWLocation*) initWithCLLocation:(CLLocation*)location;

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
* Specifies a location's latitude and longitude.
*
* The location's longitude is derived from the specified time zone. The time zone is converted from a time offset
* relative to Greenwich Mean Time into a longitude offset relative to the prime meridian. For example, an offset of +12
* hours is converted into a longitude offset of +180 degrees, while an offset of -12 hours is converted into a longitude
* offset of -180 degrees. This conversion ignores differences in time zone offsets at different points in the year such
* as Daylight Savings Time.
*
* @param latitude The location's latitude in degrees.
* @param timeZone The time zone associated with the location's longitude.
*
* @return This location with the specified latitude and longitude.
*
* @exception NSInvalidArgumentException If the specified time zone is nil.
*/
- (WWLocation*) setDegreesLatitude:(double)latitude timeZoneForLongitude:(NSTimeZone*)timeZone;

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
* Sets a location to the latitude and longitude of a specified CLLocation.
*
* The location's latitude and longitude are taken directly from the specified CLLocation's coordinate property.
*
* @param location The location containing the new latitude and longitude.
*
* @return This location with the specified latitude and longitude.
*
* @exception NSInvalidArgumentException If the specified location is nil.
*/
- (WWLocation*) setCLLocation:(CLLocation*)location;

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

/// @name Common Geographic Operations

/**
* TODO
*
* @param beginLocation TODO
* @param endLocation TODO
*
* @return TODO
*
* @exception TODO
*/
+ (double) greatCircleAzimuth:(WWLocation*)beginLocation endLocation:(WWLocation*)endLocation;

/**
* TODO
*
* @param beginLocation TODO
* @param endLocation TODO
*
* @return TODO
*
* @exception TODO
*/
+ (double) greatCircleDistance:(WWLocation*)beginLocation endLocation:(WWLocation*)endLocation;

/**
* Computes a location on the great circle path specified by a beginning location, azimuth and distance.
*
* @param beginLocation The beginning location of the great circle path.
* @param azimuth The direction of the great circle path in degrees clockwise from north.
* @param distance The angular distance between the begin location of the path and the desired location, in degrees.
* @param result TODO
*
* @exception NSInvalidArgumentException If either the begin location or the result is nil.
*/
+ (void) greatCircleLocation:(WWLocation*)beginLocation
                     azimuth:(double)azimuth
                    distance:(double)distance
              outputLocation:(WWLocation*)result;

/**
* TODO
*
* @param beginLocation TODO
* @param endLocation TODO
* @param amount TODO
* @param result TODO
*
* @exception TODO
*/
+ (void) greatCircleInterpolate:(WWLocation*)beginLocation
                    endLocation:(WWLocation*)endLocation
                         amount:(double)amount
                 outputLocation:(WWLocation*)result;

/**
* TODO
*
* @param beginLocation TODO
* @param endLocation TODO
*
* @return TODO
*
* @exception TODO
*/
+ (double) rhumbAzimuth:(WWLocation*)beginLocation endLocation:(WWLocation*)endLocation;

/**
* TODO
*
* @param beginLocation TODO
* @param endLocation TODO
*
* @return TODO
*
* @exception TODO
*/
+ (double) rhumbDistance:(WWLocation*)beginLocation endLocation:(WWLocation*)endLocation;

/**
* Computes this location on the rhumb path specified by a beginning location, azimuth and distance.
*
* @param beginLocation The beginning location of the rhumb path.
* @param azimuth The direction of the rhumb path in degrees clockwise from north.
* @param distance The angular distance, between the begin location of the path and the desired location, in degrees.
* @param result TODO
*
* @exception NSInvalidArgumentException If either the begin location or the result is nil.
*/
+ (void) rhumbLocation:(WWLocation*)beginLocation
               azimuth:(double)azimuth
              distance:(double)distance
        outputLocation:(WWLocation*)result;

/**
* TODO
*
* @param beginLocation TODO
* @param endLocation TODO
* @param amount TODO
* @param result TODO
*
* @exception TODO
*/
+ (void) rhumbInterpolate:(WWLocation*)beginLocation
              endLocation:(WWLocation*)endLocation
                   amount:(double)amount
           outputLocation:(WWLocation*)result;

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
+ (void) forecastLocation:(CLLocation*)location
                  forDate:(NSDate*)date
                 withGobe:(WWGlobe*)globe
           outputLocation:(WWLocation*)result;

@end