/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>

@class WWVec4;

/**
* Represents a line in model coordinates defined by an origin point and a direction vector.
*
* WWLine defines an infinite line that passes through a point in a given direction, and extends to infinity in both
* directions. WWLine may be interpreted as a ray with a single endpoint extending to infinity along its direction, or as
* a segment between two endpoints. Classes or methods that interpret WWLine as a ray or as a line segment are documented
* as doing so.
*
* @warning WWLine instances are mutable.
*/
@interface WWLine : NSObject

/// @name Line Attributes

/// The point this line passes through, in model coordinates.
@property(nonatomic) WWVec4* origin;

/// This line's direction vector, in model coordinates. The direction vector is not required to be a unit vector.
@property(nonatomic) WWVec4* direction;

/// @name Initializing Lines

/**
* Initializes a line with a specified origin point and direction vector.
*
* This method retains the specified origin and direction, and assigns them to its internal origin and direction
* properties.
*
* @param origin The point the passes through, in model coordinates.
* @param direction The line's direction vector, in model coordinates. This vector may have any non-zero length.
*
* @return The initialized line.
*
* @exception NSInvalidArgumentException If either argument is nil, or if the direction has zero length.
*/
- (WWLine*) initWithOrigin:(WWVec4*)origin direction:(WWVec4*)direction;

/// @name Operations on Lines

/**
* Computes a point on this line with a specified distance from the origin point.
*
* The distance may be any real value. Zero distance indicates the origin point, a negative distance indicates a point
* on the line opposite the direction vector, and a positive distance indicates a point along the direction vector. The
* computed point is stored in the result parameter after this method returns.
*
* @param distance The distance between the origin point and desired point on this line.
* @param result A WWVec4 instance in which to return the point on this line.
*
* @exception NSInvalidArgumentException If the result is nil.
*/
- (void) pointAt:(double)distance result:(WWVec4*)result;

/**
* Computes the point on this line that is nearest to a specified point.
*
* The computed point is stored in the result parameter after this method returns.
*
* @param point The point by which the nearest point on this line is determined.
* @param result A WWVec4 instance in which to return the nearest point.
*
* @exception NSInvalidArgumentException If either argument is nil.
*/
- (void) nearestPointTo:(WWVec4*)point result:(WWVec4*)result;

@end