/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>
#import <CoreGraphics/CGGeometry.h>

/*!
    Returns the distance between a globe's horizon and a viewer at the specified elevation. Only the globe's ellipsoid
    is considered; terrain elevations are not incorporated. This returns zero if the specified elevation is less than or
    equal to zero.

    @param globeRadius
        The globe's radius, in meters.
    @param elevation
        The viewer's elevation, in meters relative to mean sea level.
    @result
        The distance to the horizon, in meters.
 */
extern double horizonDistance(double globeRadius, double elevation);

extern CGRect perspectiveFieldOfViewFrustumRect(double horizontalFOV, double viewportWidth, double viewportHeight, double zDistance);

extern double perspectiveFieldOfViewMaxNearDistance(double horizontalFOV, double viewportWidth, double viewportHeight, double distanceToObject);

extern double perspectiveFieldOfViewMaxPixelSize(double horizontalFOV, double viewportWidth, double viewportHeight, double distanceToObject);

extern CGRect perspectiveSizePreservingFrustumRect(double viewportWidth, double viewportHeight, double zDistance);

extern double perspectiveSizePreservingMaxNearDistance(double viewportWidth, double viewportHeight, double distanceToObject);

extern double perspectiveSizePreservingMaxPixelSize(double viewportWidth, double viewportHeight, double distanceToObject);
