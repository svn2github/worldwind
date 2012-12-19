/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Util/WWMath.h"

double horizonDistance(double globeRadius, double elevation)
{
    if (elevation <= 0)
        return 0;

    return sqrt(elevation * (2 * globeRadius + elevation));
}
