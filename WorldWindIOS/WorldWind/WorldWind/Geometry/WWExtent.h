/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

@class WWVec4;
@class WWFrustum;
@class WWPlane;

/**
* Provides an interface for working with bounding volumes.
*/
@protocol WWExtent

/// @name Extent Attributes

/**
* The bounding volume's center.
*
* @return The bounding volume's center.
*/
- (WWVec4*) center;

/**
* The bounding volumes radius.
*
* @return The bounding volume's radius.
*/
- (double) radius;

/// Operations on Extents

/**
* Computes the distance between this box and a specified point.
*
* For this calculation the box is considered a sphere.
*
* @param point The point to consider.
*
* @return The distance between the point and this box.
*
* @exception NSInvalidArgumentException If the specified point is nil.
*/
- (double) distanceTo:(WWVec4*)point;

/**
* Computes the effective radius of this box relative to a specified plane.
*
* @param The plane to consider.
*
* @return The effective radius.
*
* @exception NSInvalidArgumentException If the specified plane is nil.
*/
- (double) effectiveRadius:(WWPlane*)plane;

/**
* Indicates whether this box intersects a specified frustum.
*
* @param frustum The frustum of interest.
*
* @return YES if this box and the frustum intersect, otherwise NO.
*
* @exception NSInvalidArgumentException if the specified frustum is nil.
*/
- (BOOL) intersects:(WWFrustum*)frustum;

@end