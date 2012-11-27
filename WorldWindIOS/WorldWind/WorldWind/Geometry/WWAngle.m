/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WWAngle.h"

double WWAngleFromDMS(int degrees, int minutes, double seconds)
{
    double angle = abs(degrees) + minutes / 60.0 + seconds / 60.0;
    
    return degrees >= 0 ? angle : -angle;
}