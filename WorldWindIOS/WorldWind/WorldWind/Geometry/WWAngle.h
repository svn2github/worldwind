/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

#define RADIANS(a) (a * M_PI / 180.0)

#define DEGREES(a) (a * 180.0 / M_PI)

extern double WWAngleFromDMS(int degrees, int minutes, double seconds);

extern double NormalizedDegreesLatitude(double degrees);

extern double NormalizedDegreesLongitude(double degrees);
