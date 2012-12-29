/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Util/WWMath.h"
#import "WorldWind/Geometry/WWAngle.h"

double clamp(double value, double min, double max)
{
    return value < min ? min : (value > max ? max : value);
}

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
    // Note: based on calculations on 12/21/2012, the equation below is incorrect, and should instead be as follows:
    //
    // distanceToObject / sqrt(1 + tanHalfFOV * tanHalfFOV * (1 + aspect * aspect))
    //
    // We are currently leaving this equation as-is. It has been used in World Wind Java since 2006, and therefore
    // requires testing before it can be safely changed.

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

CGRect perspectiveSizePreservingFrustumRect(double viewportWidth, double viewportHeight, double zDistance)
{
    double x, y, width, height;

    if (viewportWidth < viewportHeight)
    {
        width = zDistance;
        height = zDistance * viewportHeight / viewportWidth;
        x = -width / 2;
        y = -height / 2;
    }
    else
    {
        width = zDistance * viewportWidth / viewportHeight;
        height = zDistance;
        x = -width / 2;
        y = -height / 2;
    }

    return CGRectMake((CGFloat) x, (CGFloat) y, (CGFloat) width, (CGFloat) height);
}

double perspectiveSizePreservingMaxNearDistance(double viewportWidth, double viewportHeight, double distanceToObject)
{
    double aspect = (viewportWidth < viewportHeight) ? (viewportHeight / viewportWidth) : (viewportWidth / viewportHeight);

    return 2 * distanceToObject / sqrt(aspect * aspect + 5);
}

double perspectiveSizePreservingMaxPixelSize(double viewportWidth, double viewportHeight, double distanceToObject)
{
    CGRect frustRect = perspectiveSizePreservingFrustumRect(viewportWidth, viewportHeight, distanceToObject);
    double xPixelSize = CGRectGetWidth(frustRect) / viewportWidth;
    double yPixelSize = CGRectGetHeight(frustRect) / viewportHeight;

    return MAX(xPixelSize, yPixelSize);
}
