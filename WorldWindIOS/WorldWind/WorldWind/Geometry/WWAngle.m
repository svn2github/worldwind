/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Geometry/WWAngle.h"

double WWAngleFromDMS(int degrees, int minutes, double seconds)
{
    double angle = abs(degrees) + minutes / 60.0 + seconds / 60.0;
    
    return degrees >= 0 ? angle : -angle;
}

double NormalizedDegreesLatitude(double degrees)
{
    double lat = fmod(degrees, 180);
    return lat > 90 ? 180 - lat : lat < -90 ? -180 - lat : lat;
}

double NormalizedDegreesLongitude(double degrees)
{
    double lon = fmod(degrees, 360);
    return lon > 180 ? lon - 360 : lon < -180 ? 360 + lon : lon;
}