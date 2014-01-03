/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>
#import <CoreGraphics/CGGeometry.h>

@class WWPosition;
@class WWGlobe;
@class WWMatrix;
@class WWPosition;
@class WWVec4;
@class WWLine;

/**
* Convert degrees to radians.
*/
#define RADIANS(a) (a * M_PI / 180.0)

/**
* Convert radians to degrees.
*/
#define DEGREES(a) (a * 180.0 / M_PI)

/**
* Adjusts a specified floating point value to be within a specified minimum and maximum.
*/
#define WWCLAMP(value, min, max) ((value) < (min) ? (min) : ((value) > (max) ? (max) : (value)))

/**
* A collection of class methods for computing various values.
*/
@interface WWMath : NSObject

/// @name Commonly Used Math Operations

/**
* Adjusts a specified floating point value to be within a specified minimum and maximum.
*
* The returned value is undefined if min > max. Otherwise, this method's return value is equivalent to the following:
*
* - min - If value < min
* - max - If value > max
* - value - If min <= value <= max
*
* @param value The value to clamp.
* @param min The minimum value to clamp to.
* @param max The maximum value to clamp to.
*
* @return The clamped value.
*/
+ (double) clampValue:(double)value min:(double)min max:(double)max;

/**
* Returns a number between 0.0 and 1.0 indicating whether a specified floating point value is before, between or after
* the specified min and max. Returns a linear interpolation of min and max when the value is between the two.
*
* The returned number is undefined if min > max. Otherwise, the returned number is equivalent to the following:
*
* - 0.0 - If value < min
* - 1.0 - If value > max
* - Linear interpolation of min and max - If min <= value <= max
*
* @param value The value to compare to the minimum and maximum.
* @param min The minimum value.
* @param max The maximum value.
*
* @return A floating point number between 0.0 and 1.0, inclusive.
*/
+ (double) stepValue:(double)value min:(double)min max:(double)max;

/**
* Returns a number between 0.0 and 1.0 indicating whether a specified floating point value is before, between or after
* the specified min and max. Returns a smooth interpolation of min and max when the value is between the two.
*
* This method's smooth interpolation is similar to the interpolation performed by stepValue:min:max, except that the
* first derivative of the returned number approaches zero as the value approaches the minimum or maximum. This causes
* the returned number to ease-in and ease-out as the value travels between the minimum and maximum.
*
* The returned number is undefined if min > max. Otherwise, the returned number is equivalent to the following:
*
* - 0.0 - If value < min
* - 1.0 - If value > max
* - Smooth interpolation of min and max - If min <= value <= max
*
* @param value The value to compare to the minimum and maximum.
* @param min The minimum value.
* @param max The maximum value.
*
* @return A floating point number between 0.0 and 1.0, inclusive.
*/
+ (double) smoothStepValue:(double)value min:(double)min max:(double)max;

/**
* Returns the linear interpolation of two floating point numbers.
*
* The amount indicates the percentage of the two values, and should be a number between 0.0 and 1.0, inclusive. The
* returned number is undefined if amount < 0.0 or if amount > 1.0. Otherwise, the returned number is a linear
* interpolation of value1 and value2 appropriate for the specified amount. For example, if amount is 0.5 this returns a
* number that is half way between value1 and value2.
*
* @param value1 The first value.
* @param value2 The second value.
* @param amount The amount to interpolate as a number between 0.0 and 1.0, inclusive.
*
* @return The linear interpolation of value1, and value2.
*/
+ (double) interpolateValue1:(double)value1 value2:(double)value2 amount:(double)amount;

/**
* Returns the linear interpolation of two floating point angles.
*
* The amount indicates the percentage of the two angles, and should be a number between 0.0 and 1.0, inclusive. The
* returned angles is undefined if amount < 0.0 or if amount > 1.0. Otherwise, the returned angles is a linear
* interpolation of angle1 and angle2 appropriate for the specified amount. For example, if amount is 0.5 this returns a
* number that is half way between angle1 and angle2.
*
* The two angles are assumed to represent angles and are interpolated along the shortest arc on the unit circle. For
* example, interpolating 50% between -135 degrees and +135 degrees produces a result of +180 degrees. The returned angle
* is normalized to the range from -180 to +180, inclusive.
*
* @param angle1 The first angle, in degrees.
* @param angle2 The second angle, in degrees.
* @param amount The amount to interpolate as a number between 0.0 and 1.0, inclusive.
*
* @return The linear interpolation of angle1, and angle2.
*/
+ (double) interpolateDegrees1:(double)angle1 degrees2:(double)angle2 amount:(double)amount;

/**
* Normalizes a specified angle to the range from -180 to +180, inclusive
*
* This returns the specified angle if it's already in the normalized range. Otherwise, this returns an number
* corresponding to the specified angle in the range from -180 to +180. For example, +181 degrees normalizes to -179, and
* -181 degrees normalizes to +179. The normalized range represents a continuous range of angles, where -180 and +180
* represent the same angle.
*
* @param angle The angle to normalize, in degrees.
*
* @return The normalized angle, in the range from -180 degrees to +180 degrees, inclusive.
*/
+ (double) normalizeDegrees:(double)angle;

/**
* Normalizes a specified latitude to the latitude range from -90 to +90, inclusive.
*
* This returns the specified latitude if it's already in the normalized range. Otherwise, this returns a number
* corresponding to the specified latitude in the range from -90 to +90. For example, +91 degrees normalizes to +89, and
* -91 degrees normalizes to -89. The normalized range represents a mirrored range of latitudes, where latitudes greater
* than +90 or less than -90 are treated as though they travel back towards 0.
*
* @param latitude The latitude to normalize, in degrees.
*
* @return The normalized latitude, in the range from -90 degrees to +90 degrees, inclusive.
*/
+ (double) normalizeDegreesLatitude:(double)latitude;

/**
* Normalizes a specified angle to the range from -180 to +180, inclusive
*
* This returns the specified longitude if it's already in the normalized range. Otherwise, this returns an number
* corresponding to the specified longitude in the range from -180 to +180. For example, +181 degrees normalizes to -179,
* and -181 degrees normalizes to +179. The normalized range represents a continuous range of longitudes, where -180 and
* +180 represent the same longitude.
*
* @param longitude The longitude to normalize, in degrees.
*
* @return The normalized longitude, in the range from -180 degrees to +180 degrees, inclusive.
*/
+ (double) normalizeDegreesLongitude:(double)longitude;

/**
* Returns the next power-of-two given the specified value.
*
* This returns the smallest power-of-two that is greater than or equal to than the specified value. This returns 0 if
* the specified value is zero.
*
* @param value The value to compute a power-of-two ceiling for.
*
* @return The next power-of-two given the specified value.
*/
+ (int) powerOfTwoCeiling:(int)value;

/// @name Computing Information About Shapes

/**
* Computes the principal axes of a specified list of points, placing the resultant axes in the specified _axisi_
* arguments.
*
* Upon returning the specified _axisi_ arguments contain three orthogonal axes identifying the principal axes. axis1
* corresponds to the longest axes, axis2 corresponds to the intermediate length axis, and axis3 corresponds to the
* shortest axis. Each axis has unit length.
*
* @param points The list of points.
* @param axis1 Contains the longest axis after this method returns.
* @param axis2 Contains the intermetiate length axis after this method returns.
* @param axis3 Contains the shortest axis after this method returns.
*
* @exception NSInvalidArgumentException If the list of points is nil or empty, or if any axis is nil.
*/
+ (void) principalAxesFromPoints:(NSArray*)points
                           axis1:(WWVec4*)axis1
                           axis2:(WWVec4*)axis2
                           axis3:(WWVec4*)axis3;

/**
* Computes the axes of a local coordinate system on the specified globe, placing the resultant axes in the specified
* _axis_ arguments.
*
* Upon returning the specified _axis_ arguments contain three orthogonal axes identifying the x- y- and z-axes. Each
* axis has unit length.
*
* The local coordinate system is defined such that the z-axis maps to the globe's surface normal at the point, the
* y-axis maps to the north pointing tangent, and the x-axis maps to the east pointing tangent.
*
* @param point The local coordinate system origin, in model coordinates.
* @param globe The globe the coordinate system is relative to.
* @param xaxis Contains the x-axis after this method returns.
* @param yaxis Contains the y-axis after this method returns.
* @param zaxis Contains the z-axis after this method returns.
*
* @exception NSInvalidArgumentException If any argument is nil.
*/
+ (void) localCoordinateAxesAtPoint:(WWVec4*)point
                            onGlobe:(WWGlobe*)globe
                              xaxis:(WWVec4*)xaxis
                              yaxis:(WWVec4*)yaxis
                              zaxis:(WWVec4*)zaxis;

/**
* Computes the rectangle bounding a unit quad transformed by the specified matrix.
*
* The computed rectangle is in the OpenGL screen coordinate system, with its origin in the bottom-left corner and axes
* that extend up and to the right from the origin point.
*
* The untransformed unit quad has its lower left coordinate at (0, 0) and its upper left coordinate at (1, 1). When the
* transform matrix is an identity matrix, the returned rectangle has coordinates (x, y, width, height) of (0, 0, 1, 1).
* Otherwise, the returned rectangle is an axis-aligned rectangle that bounds the transformed quad. For example, if the
* transform matrix has a scale of 2 and an x-translation of 10, the returned rectangle has coordinates (10, 0, 2, 2).
* Note that the transformed quad and the returned rectangle are not necessarily equivalent. For example, if the
* transform matrix contains any rotation or shearing then the returned rectangle covers an area larger than the quad.
*
* @param transformMatrix A homogeneous transform matrix used to transform the unit quad.
*
* @return An axis-aligned rectangle bounding the transformed unit quad, in OpenGL screen coordinates.
*
* @exception NSInvalidArgumentException If the transformMatrix is nil.
*/
+ (CGRect) boundingRectForUnitQuad:(WWMatrix*)transformMatrix;

/**
* Determines whether a line intersects a triangle and returns the intersection point.
*
* The ordering of the triangle vertices does not matter for the intersection test and does not affect the result.
*
* @param line The line to intersect.
* @param vax The X coordinate of the first triangle vertex.
* @param vay The Y coordinate of the first triangle vertex.
* @param vaz The Z coordinate of the first triangle vertex.
* @param vbx The X coordinate of the second triangle vertex.
* @param vby The Y coordinate of the second triangle vertex.
* @param vbz The Z coordinate of the second triangle vertex.
* @param vcx The X coordinate of the third triangle vertex.
* @param vcy The Y coordinate of the third triangle vertex.
* @param vcz The Z coordinate of the third triangle vertex.
* @param result A location to store the intersection point.
*
* @return YES if the line intersects the triangle, otherwise NO, which is also returned if the line is parallel to
* the triangle's plane.
*/
+ (BOOL) computeTriangleIntersection:(WWLine*)line
                                 vax:(double)vax
                                 vay:(double)vay
                                 vaz:(double)vaz
                                 vbx:(double)vbx
                                 vby:(double)vby
                                 vbz:(double)vbz
                                 vcx:(double)vcx
                                 vcy:(double)vcy
                                 vcz:(double)vcz
                              result:(WWVec4*)result;

/// @name Computing Information for Viewing and Projection

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
* The viewport is in the OpenGL screen coordinate system, with its origin in the bottom-left corner and axes that extend
* up and to the right from the origin point.
*
* @param viewport The viewport rectangle, in OpenGL screen coordinates.
* @param distance The distance along the negative z axis, in model coordinates.
*
* @return The frustum rectangle coordinates, in model coordinates.
*
* @exception NSInvalidArgumentException If either the viewport width or the viewport height are zero, or if the distance
* is negative.
*/
+ (CGRect) perspectiveFrustumRect:(CGRect)viewport atDistance:(double)distance;

/**
* Computes the approximate size of a pixel in model coordinates at a given distance from the eye point in a perspective
* projection.
*
* This method assumes the model of a screen composed of rectangular pixels, where pixel coordinates denote infinitely
* thin space between pixels. The units of the returned size are in model coordinates per pixel (usually meters per
* pixel). This returns 0 if the specified distance is zero. The returned size is undefined if the distance is less than
* zero.
*
* The viewport is in the OpenGL screen coordinate system, with its origin in the bottom-left corner and axes that extend
* up and to the right from the origin point.
*
* @param viewport The viewport rectangle, in OpenGL screen coordinates.
* @param distance The distance from the perspective eye point at which to determine pixel size, in model coordinates.
*
* @return The approximate pixel size at the specified distance from the eye point, in model coordinates per pixel.
*
* @exception NSInvalidArgumentException If either the viewport width or the viewport height are zero, or if the distance
* is negative.
*/
+ (double) perspectivePixelSize:(CGRect)viewport atDistance:(double)distance;

/**
* Computes the minimum distance between the eye point and an object with the specified size needed to make the object
* completely visible in a perspective projection.
*
* The viewport is in the OpenGL screen coordinate system, with its origin in the bottom-left corner and axes that extend
* up and to the right from the origin point. This method assumes that the scene is situated such that the center of the
* object appears in the center of the viewport.
*
* @param viewport The viewport rectangle, in OpenGL screen coordinates.
* @param radius The radius of the object to fit in the viewport, in model coordinates.
*
* @return The minimum eye distance, in model coordinates.
*
* @exception NSInvalidArgumentException If either the viewport width or the viewport height are zero, or if the radius
* is negative.
*/
+ (double) perspectiveFitDistance:(CGRect)viewport forObjectWithRadius:(double)radius;

/**
* Computes the minimum distance between the eye point needed to keep the two positions completely visible in a
* perspective projection on the given globe.
*
* The viewport is in the OpenGL screen coordinate system, with its origin in the bottom-left corner and axes that extend
* up and to the right from the origin point. This method assumes that the scene is situated such that the center of the
* two positions appears in the center of the viewport.
*
* @param viewport The viewport rectangle, in OpenGL screen coordinates.
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
* Computes a recommended duration in seconds for an animation between the two positions in a perspective projection on
* the given globe.
*
* This returns a duration typically between 0 seconds and 3 seconds corresponding to the distance between the two
* positions in OpenGL screen coordinates. This considers both the distance between the two geographic locations and the
* distance between the two altitudes.
*
* The viewport is in the OpenGL screen coordinate system, with its origin in the bottom-left corner and axes that extend
* up and to the right from the origin point.
*
* @param viewport The viewport rectangle, in OpenGL screen coordinates.
* @param posA The animation's begin position.
* @param posB The animation's end position.
* @param globe The globe the two positions are associated with.
*
* @return The animation duration, in seconds.
*
* @exception NSInvalidArgumentException If either the viewport width or the viewport height are zero, or if any argument
* is nil.
*/
+ (NSTimeInterval) perspectiveAnimationDuration:(CGRect)viewport
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
* The viewport is in the OpenGL screen coordinate system, with its origin in the bottom-left corner and axes that extend
* up and to the right from the origin point.
*
* @param viewport The viewport rectangle, in OpenGL screen coordinates.
* @param distance The distance from the perspective eye point to the nearest object, in model coordinates.
*
* @return The maximum near clip distance, in model coordinates.
*
* @exception NSInvalidArgumentException If either the viewport width or the viewport height are zero, or if the distance
* is negative.
*/
+ (double) perspectiveNearDistance:(CGRect)viewport forObjectAtDistance:(double)distance;

/**
* Computes the near clip distance that corresponds to a specified far clip distance and resolution at the far clip
* plane.
*
* This computes a near clip distance appropriate for use in [WWMath perspectiveFrustumRect:atDistance:] and
* [WWMatrix setToPerspectiveProjection:nearDistance:farDistance:]. This returns zero if either the distance or the
* resolution are zero.
*
* @param distance The far clip distance, in model coordinates.
* @param resolution The depth resolution at the far clip plane, in model coordinates.
* @param depthBits The number of bitplanes in the depth buffer. This is typically 16, 24, or 32 for OpenGL ES depth
* buffers.
*
* @return The near clip distance, in model coordinates.
*
* @exception NSInvalidArgumentException If either the distance or the resolution are negative, or if the depthBits is
* less than one.
*/
+ (double) perspectiveNearDistanceForFarDistance:(double)distance
                                   farResolution:(double)resolution
                                       depthBits:(int)depthBits;
@end