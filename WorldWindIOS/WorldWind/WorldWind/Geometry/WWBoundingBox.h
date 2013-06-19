/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WorldWind/Geometry/WWExtent.h"

@class WWVec4;
@class WWPlane;
@class WWFrustum;

/**
* Provides box geometry for use as a bounding volume.
*/
@interface WWBoundingBox : NSObject <WWExtent>
{
@protected
    // Temporary variables used in the high-frequency intersects method to avoid constant Vec4 allocations.
    WWVec4* tmp1;
    WWVec4* tmp2;
    WWVec4* tmp3;
}

/// @name Bounding Box Attributes

/// The center point of the box's bottom. (The origin of the R axis.)
@property(nonatomic, readonly) WWVec4* bottomCenter;

/// The center point of the box's top. (The end of the R axis.)
@property(nonatomic, readonly) WWVec4* topCenter;

/// The box's center.
@property(nonatomic, readonly) WWVec4* center;

/// The R axis, the box's longest axis.
@property(nonatomic, readonly) WWVec4* r;

/// The S axis, the box's mid-length axis.
@property(nonatomic, readonly) WWVec4* s;

// The T axis, the box's shortest axis.
@property(nonatomic, readonly) WWVec4* t;

/// The unit length R axis.
@property(nonatomic, readonly) WWVec4* ru;

/// The unit length S axis.
@property(nonatomic, readonly) WWVec4* su;

/// The unit length T axis.
@property(nonatomic, readonly) WWVec4* tu;

/// The length in meters of the box's longest axis.
@property(nonatomic, readonly) double rLength;

/// The length in meters of the box's mid-length axis.
@property(nonatomic, readonly) double sLength;

/// The length in meters of the box's shortest axis.
@property(nonatomic, readonly) double tLength;

/// The six planes that bound the box.
@property(nonatomic, readonly) NSArray* planes;

/// This bounding box's radius.
@property (nonatomic, readonly) double radius;

/// @name Initializing Bounding Boxes

/**
* Initializes this bounding box such that it contains a specified list of points.
*
* @param points The points to contain.
*
* @return The bounding box initialized to contain the specified points.
*
* @exception NSInvalidArgumentException If the list of points is nil or empty.
*/
- (WWBoundingBox*) initWithPoints:(NSArray*)points;

/// @name Operations on Bounding Boxes

/**
* Translates this box by a specified translation vector.
*
* @param translation The translation vector.
*
* @exception NSInvalidArgumentException If the translation vector is nil.
*/
- (void) translate:(WWVec4*)translation;

/// @name Operations on Bounding Boxes

/**
* Computes the approximate distance between this bounding box and a specified point.
*
* This calculation treats the bounding box as a sphere of radius.
*
* @param point The point to compute the distance to.
*
* @return the distance from the edge of this bounding box to the specified point.
*
* @exception NSInvalidArgumentException If the point is nil.
*/
- (double) distanceTo:(WWVec4*)point;

/**
* Computes the effective radius of this bounding box relative to a specified plane.
*
* @param plane The plane of interest.
*
* @return The effective radius of this bounding box to the specified plane.
*
* @exception NSInvalidArgumentException If the plane is nil.
*/
- (double) effectiveRadius:(WWPlane*)plane;

/**
* Indicates whether this bounding box intersects a specified frustum.
*
* @param frustum The frustum of interest.
*
* @return YES if this bounding box intersects the specified frustum, otherwise NO.
*
* @exception NSInvalidArgumentException if the frustum is nil.
*/
- (BOOL) intersects:(WWFrustum*)frustum;

/// @name Methods of Interest Only to Subclasses

/**
* Computes the parametric location at which a specified line intersects a specified plane of this box.
*
* This method is used by this box's intersects method and is not intended for application use.
*
* This method accepts as an argument a line segment along the major axis of this box. Upon return,
* the line segment is truncated at the point that it intersects the specified plane.
*
* @param plane The plane to test.
* @param effRadius The effective radius of this box relative to the specified plane.
* @param endPoint1 The first end point of the line of interest. Potentially truncated on return
* @param endPoint2 The second end point of the line of interest. Potentially truncated on return.
*
* @return The parametric position along the point at which the line intersects the plane. If less than 0 the endpoints
* are more distant from the plane than the effective radius and the line is on the negative side of the plane.
*/
- (double) intersectsAt:(WWPlane*)plane
              effRadius:(double)effRadius
              endPoint1:(WWVec4*)endPoint1
              endPoint2:(WWVec4*)endPoint2;

@end