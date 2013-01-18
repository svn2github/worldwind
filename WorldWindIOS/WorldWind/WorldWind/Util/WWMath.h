/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>
#import <CoreGraphics/CGGeometry.h>

/**
* A collection of class methods for computing various values.
*/
@interface WWMath : NSObject

/// @name Commonly Used Math Operations

/**
* Adjusts a specified value to be within a specified minimum and maximum.
*
* @param value The value to clamp.
* @param min The minimum value to clamp to.
* @param max The maximum value to clamp to.
*
* @return The clamped value.
*/
+ (double) clamp:(double)value min:(double)min max:(double)max;

/// @name Computing Information About Shapes

/**
* Computes the principal axes of a specified list of points.
*
* @param points The list of points.
*
* @return An array containing three WWVec4 instances identifying the principal axes. The first vector in the array
* corresponds to the longest axis. The third vector in the array corresponds to the shortest axis. The second vector
* in the array correspond to the intermediate length axis. Returns nil if the principal axes could not be computed.
*
* @exception NSInvalidArgumentException if the specified list of points is nil.
*/
+ (NSArray*) principalAxesFromPoints:(NSArray*)points;

/// @name Computing Viewing and Navigation Information

/**
Returns the distance between a globe's horizon and a viewer at the specified elevation.

Only the globe's ellipsoid is considered; terrain elevations are not incorporated. This returns zero if the specified
elevation is less than or equal to zero.

@param globeRadius The globe's radius, in meters.
@param elevation The viewer's elevation, in meters relative to mean sea level.

@result The distance to the horizon, in meters.
 */
+ (double) horizonDistance:(double)globeRadius elevation:(double)elevation;

/**
* TODO
*
* @param horizontalFOV The horizontal field of view.
* @param viewportWidth The viewport width.
* @param viewportHeight The viewport height.
* @param zDistance TODO
*
* @return TODO
*/
+ (CGRect) perspectiveFieldOfViewFrustumRect:(double)horizontalFOV
                               viewportWidth:(double)viewportWidth
                              viewportHeight:(double)viewportHeight
                                   zDistance:(double)zDistance;

/**
* TODO
*
* @param viewportWidth The viewport width.
* @param viewportHeight The viewport height.
* @param zDistance TODO
*
* @return TODO
*/
+ (CGRect) perspectiveSizePreservingFrustumRect:(double)viewportWidth
                                 viewportHeight:(double)viewportHeight
                                      zDistance:(double)zDistance;

/**
* TODO
*
* @param viewportWidth The viewport width.
* @param viewportHeight The viewport height.
* @param distanceToObject TODO
*
* @return TODO
*/
+ (double) perspectiveSizePreservingMaxNearDistance:(double)viewportWidth
                                     viewportHeight:(double)viewportHeight
                                   distanceToObject:(double)distanceToObject;

/**
* TODO
*
* @param horizontalFOV The horizontal field of view.
* @param viewportWidth The viewport width.
* @param viewportHeight The viewport height.
* @param distanceToObject TODO
*
* @return TODO
*/
+ (double) perspectiveFieldOfViewMaxNearDistance:(double)horizontalFOV
                                   viewportWidth:(double)viewportWidth
                                  viewportHeight:(double)viewportHeight
                                distanceToObject:(double)distanceToObject;

/**
* TODO
*
* @param horizontalFOV The horizontal field of view.
* @param viewportWidth The viewport width.
* @param viewportHeight The viewport height.
* @param distanceToObject TODO
*
* @return TODO
*/
+ (double) perspectiveFieldOfViewMaxPixelSize:(double)horizontalFOV
                                   viewportWidth:(double)viewportWidth
                                  viewportHeight:(double)viewportHeight
                                distanceToObject:(double)distanceToObject;

/**
* TODO
*
* @param viewportWidth The viewport width.
* @param viewportHeight The viewport height.
* @param distanceToObject TODO
*
* @return TODO
*/
+ (double) perspectiveSizePreservingMaxPixelSize:(double)viewportWidth
                               viewportHeight:(double)viewportHeight
                             distanceToObject:(double)distanceToObject;

@end
