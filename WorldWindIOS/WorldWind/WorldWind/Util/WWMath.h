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

/// @name Computing Information for Viewing and Projection

/**
* Computes a recommended duration for a navigator animation between the specified positions as an NSTimeInterval.
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
*
* @exception NSInvalidArgumentException If any argument is nil.
*/
+ (NSTimeInterval) durationForAnimationWithBeginPosition:(WWPosition*)posA
                                             endPosition:(WWPosition*)posB
                                                 onGlobe:(WWGlobe*)globe;

/**
* Computes the distance to a globe's horizon from a viewer at a given altitude.
*
* Only the globe's ellipsoid is considered; terrain height is not incorporated. This returns zero if the radius is zero
* or if the altitude is less than or equal to zero.
*
* @param radius The globe's radius, in model coordinates.
* @param altitude The viewer's altitude above the globe, in model coordinates.
*
* @return The distance to the horizon, in model coordinates.
*
* @exception NSInvalidArgumentException If the radius is negative.
*/
+ (double) horizonDistanceForGlobeRadius:(double)radius eyeAltitude:(double)altitude;

/**
* Computes the coordinates of a rectangle carved out of a perspective projection's frustum at a given distance in model
* coordinates.
*
* This computes a frustum rectangle that preserves the scene's size relative to the viewport when the viewport width and
* height are swapped. This has the effect of maintaining the scene's size on screen when the device is rotated.
*
* @param viewport The viewport rectangle, in screen coordinates.
* @param distance The distance along the negative z axis, in model coordinates.
*
* @return The frustum rectangle coordinates, in model coordinates.
*
* @exception NSInvalidArgumentException If either the viewport width or the viewport height are zero.
*/
+ (CGRect) perspectiveFrustumRect:(CGRect)viewport atDistance:(double)distance;

/**
* Computes the approximate size of a pixel in model coordinates at a given distance from the eye point in a perspective
* projection.
*
* This method assumes the model of a screen composed of rectangular pixels, where pixel coordinates denote infinitely
* thin space between pixels. The units of the returned size are in model coordinates per pixel (usually meters per
* pixel). This returns 0 if the specified distance is zero. The returned size is undefined if the distance is less than zero.
*
* @param viewport The viewport rectangle, in screen coordinates.
* @param distance The distance from the perspective eye point at which to determine pixel size, in model coordinates.
*
* @return The approximate pixel size at the specified distance from the eye point, in model coordinates per pixel.
*
* @exception NSInvalidArgumentException If either the viewport width or the viewport height are zero.
*/
+ (double) perspectivePixelSize:(CGRect)viewport atDistance:(double)distance;

/**
* Computes the minimum distance between the eye point and an object with the specified size needed to make the object
* completely visible in a perspective projection.
*
* @param viewport The viewport rectangle, in screen coordinates.
* @param radius The radius of the object to fit in the viewport, in model coordinates.
*
* @return The minimum eye distance, in model coordinates.
*
* @exception NSInvalidArgumentException If either the viewport width or the viewport height are zero, or if the radius is negative.
*/
+ (double) perspectiveFitDistance:(CGRect)viewport forObjectWithRadius:(double)radius;

/**
* Computes the minimum distance between the eye point needed to keep the two positions completely visible in a
* perspective projection on the given globe.
*
* This method assumes that the viewport is placed at the center of the two positions.
*
* @param viewport The viewport rectangle, in screen coordinates.
* @param posA The first position to fit in the viewport.
* @param posB The second position to fit in the viewport.
* @param globe The globe the two positions are associated with.
*
* @return The minimum eye distance, in model coordinates.
*
* @exception NSInvalidArgumentException If either the viewport width or the viewport height are zero, or if any argument
* is nil.
*/
+ (double) perspectiveFitDistance:(CGRect)viewport
                     forPositionA:(WWPosition*)posA
                        positionB:(WWPosition*)posB
                          onGlobe:(WWGlobe*)globe;

/**
* Computes the maximum near clip distance for a perspective projection that avoids clipping an object at a given
* distance from the eye point.
*
* This computes a near clip distance appropriate for use in [WWMath perspectiveFrustumRect:atDistance:] and
* [WWMatrix setToPerspectiveProjection:nearDistance:farDistance:]. The given distance should specify the
* smallest distance between the eye and the object being viewed, but may be an approximation if an exact distance is not
* required.
*
* @param viewport The viewport rectangle, in screen coordinates.
* @param distance The distance from the perspective eye point to the nearest object, in model coordinates.
*
* @return The maximum near clip distance, in model coordinates.
*
* @exception NSInvalidArgumentException If either the viewport width or the viewport height are zero.
*/
+ (double) perspectiveNearDistance:(CGRect)viewport forObjectAtDistance:(double)distance;

@end