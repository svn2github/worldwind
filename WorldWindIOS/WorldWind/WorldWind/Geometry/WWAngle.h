/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

/**
* Convert degrees to radians.
*/
#define RADIANS(a) (a * M_PI / 180.0)

/**
* Convert radians to degrees.
*/
#define DEGREES(a) (a * 180.0 / M_PI)

/**
* Compute a decimal angle from specified degrees, minutes and seconds.
*/
extern double WWAngleFromDMS(int degrees, int minutes, double seconds);

/**
* Clamps a specified angle to the range [-90, 90].
*/
extern double NormalizedDegreesLatitude(double degrees);

/**
* Clamps a specified angle to the range [-180, 180].
*/
extern double NormalizedDegreesLongitude(double degrees);
