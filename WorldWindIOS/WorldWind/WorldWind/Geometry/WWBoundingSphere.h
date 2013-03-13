/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WorldWind/Geometry/WWExtent.h"

@class WWVec4;

/**
* Represents a sphere bounding a collection of points or other shape(s).
*/
@interface WWBoundingSphere : NSObject <WWExtent>

/// @name Bounding Sphere Attributes

/// The spheres Cartesian center point.
@property (nonatomic, readonly) WWVec4* center;


/// The sphere's radius, in meters.
@property (nonatomic, readonly) double radius;

/// @name Initializing Bounding Spheres

/**
* Initializes this bounding sphere to encompass a specified list of points.
*
* @param points The points to bound.
*
* @return The bounding sphere set to encompass the specified points.
*
* @exception NSInvalidArgumentException If the points list is nil.
*/
- (WWBoundingSphere*) initWithPoints:(NSArray*)points;

/**
* Initializes this bounding sphere to a specified center point and radius.
*
* @param point The sphere's center point.
* @param radius The sphere's radius, in meters.
*
* @return The bounding sphere set to the specified center point and radius.
*
* @exception NSInvalidArgumentException If the specified point is nil or the radius is less than or equal to 0.
*/
- (WWBoundingSphere*) initWithPoint:(WWVec4*)point radius:(double)radius;

@end