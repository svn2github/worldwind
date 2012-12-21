/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Util/WWMath.h"
#import "WorldWind/Geometry/WWAngle.h"

double horizonDistance(double globeRadius, double elevation)
{
    if (elevation <= 0)
        return 0;

    return sqrt(elevation * (2 * globeRadius + elevation));
}

CGRect perspectiveFieldOfViewFrustumRect(double horizontalFOV, double viewportWidth, double viewportHeight, double zDistance)
{
    // Based on http://www.opengl.org/resources/faq/technical/transformations.htm#tran0085.
    // This method uses horizontal field-of-view here to describe the perspective viewing angle. This results in a
    // different set of clip plane distances than documented in sources using vertical field-of-view.

    double tanHalfFOV = tan(RADIANS(horizontalFOV / 2));
    double width = 2 * zDistance * tanHalfFOV;
    double height = width * viewportHeight / viewportWidth;
    double x = -width / 2;
    double y = -height / 2;

    return CGRectMake((CGFloat) x, (CGFloat) y, (CGFloat) width, (CGFloat) height);
}

double perspectiveFieldOfViewMaxNearDistance(double horizontalFOV, double viewportWidth, double viewportHeight, double distanceToObject)
{
    double tanHalfFOV = tan(RADIANS(horizontalFOV / 2));

    return distanceToObject / (2 * sqrt(2 * tanHalfFOV * tanHalfFOV + 1));
}

double perspectiveFieldOfViewMaxPixelSize(double horizontalFOV, double viewportWidth, double viewportHeight, double distanceToObject)
{
    CGRect frustRect = perspectiveFieldOfViewFrustumRect(horizontalFOV, viewportWidth, viewportHeight, distanceToObject);
    double xPixelSize = CGRectGetWidth(frustRect) / viewportWidth;
    double yPixelSize = CGRectGetHeight(frustRect) / viewportHeight;

    return MAX(xPixelSize, yPixelSize);
}
