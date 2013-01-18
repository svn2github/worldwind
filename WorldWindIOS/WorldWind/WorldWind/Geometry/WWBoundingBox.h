/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WorldWind/Geometry/WWExtent.h"

@class WWVec4;
@class WWPlane;

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

/// @name Initializing Bounding Boxes

/**
* Initializes this bounding box to one meter on each axis and centered on a specified point.
*
* @param point The point to contain.
*
* @return This bounding box initialized to contain the specified point.
*
* @exception NSInvalidArgumentException If the specified point is nil.
*/
- (WWBoundingBox*) initWithPoint:(WWVec4*)point;

/**
* Initializes this bounding box such that it contains a specified list of points.
*
* @param points The points to contain.
*
* @return The bounding box initialized to contain the specified points.
*
* @exception NSInvalidArgumentException if the specified list of points is nil.
*/
- (WWBoundingBox*) initWithPoints:(NSArray*)points;

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