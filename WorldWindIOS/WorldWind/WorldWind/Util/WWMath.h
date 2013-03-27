/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>
#import <CoreGraphics/CGGeometry.h>

@class WWPosition;
@class WWGlobe;

/**
* Convert degrees to radians.
*/
#define RADIANS(a) (a * M_PI / 180.0)

/**
* Convert radians to degrees.
*/
#define DEGREES(a) (a * 180.0 / M_PI)

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
+ (double) clampValue:(double)value min:(double)min max:(double)max;

/**
* Clamps a specified angle to the range [-90, 90].
*
* @param degrees The angle to clamp, in degrees.
*
* @return The clamped angle, in the range [-90, 90].
*/
extern double NormalizedDegreesLatitude(double degrees);

/**
* Clamps a specified angle to the range [-180, 180].
*
* @param degrees The angle to clamp, in degrees.
*
* @return The clamped angle, in the range [-180, 180].
*/
extern double NormalizedDegreesLongitude(double degrees);

/**
* Clamps a specified heading angle to the range [-180, 180].
*
* @param degrees The angle to clamp, in degrees.
*
* @return The clamped angle, in the range [-180, 180].
*/
extern double NormalizedDegreesHeading(double degrees);

/**
* TODO
*
* @param value TODO
* @param min TODO
* @param max TODO
*
* @return TODO
*/
+ (double) stepValue:(double)value min:(double)min max:(double)max;

/**
* TODO
*
* @param value TODO
* @param min TODO
* @param max TODO
*
* @return TODO
*/
+ (double) smoothStepValue:(double)value min:(double)min max:(double)max;

/**
* TODO
*
* @param value1 TODO
* @param value2 TODO
* @param amount TODO
*
* @return TODO
*/
+ (double) interpolateValue1:(double)value1 value2:(double)value2 amount:(double)amount;

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
* @exception NSInvalidArgumentException If the specified list of points is nil.
*/
+ (NSArray*) principalAxesFromPoints:(NSArray*)points;

/// @name Computing Viewing and Navigation Information

/**
* Returns the minimum distance between the eye point and an object with the specified size needed to make the object
* completely visible in the specified viewport.
*
* @param radius The radius of the object to fit in the viewport, in meters.
* @param viewport The viewport rectangle, in screen coordinates.
*
* @return The minimum eye distance, in meters.
*
* @exception NSInvalidArgumentException If the radius is negative.
*/
+ (double) eyeDistanceToFitObjectWithRadius:(double)radius inViewport:(CGRect)viewport;

/**
* Returns the minimum distance between the eye point needed to keep the two positions completely visible with the
* specified globe and viewport.
*
* This assumes that the viewport is placed at the center of the two positions.
*
* @param posA The first position to fit in the viewport.
* @param posB The second position to fit in the viewport.
* @param globe The globe the two positions are associated with.
* @param viewport The viewport rectangle, in screen coordinate.
*
* @return The minimum eye distance, in meters.
*/
+ (double) eyeDistanceToFitPositionA:(WWPosition*)posA
                           positionB:(WWPosition*)posB
                             onGlobe:(WWGlobe*)globe
                          inViewport:(CGRect)viewport;

/**
* Returns the distance between a globe's horizon and a viewer at the specified elevation.
*
* Only the globe's ellipsoid is considered; elevations are not incorporated. This returns zero if the globeRadius is
* zero, or if the elevation is less than or equal to zero.
*
* @param globeRadius The globe's radius, in meters.
* @param elevation The viewer's elevation, in meters relative to mean sea level.
*
* @return The distance to the horizon, in meters.
*
* @exception NSInvalidArgumentException If the globeRadius is negative.
*/
+ (double) horizonDistance:(double)globeRadius elevation:(double)elevation;

/**
* Returns a recommended duration for a navigator animation between the specified positions as an NSTimeInterval.
*
* This returns a duration between 1.0 and 5.0 seconds corresponding to the distance between the two positions. These
* durations and the distances they are associated with are a recommendation based on observation with common World Wind
* navigator use cases, such as animating from the current position to the result of a location search.
*
* @param posA The animation's begin position.
* @param posB The animation's end position.
* @param globe The globe the two positions are associated with.
*
* @return The animation duration, in seconds.
*/
+ (NSTimeInterval) durationForAnimationWithBeginPosition:(WWPosition*)posA
                                           endPosition:(WWPosition*)posB
                                               onGlobe:(WWGlobe*)globe;

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