/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

@class WWMatrix;
@class WWVec4;

/**
* Represents a 3D plane.
*/
@interface WWPlane : NSObject

/// The plane normal and proportional distance. The vector is not necessarily a unit vector.
@property (nonatomic) WWVec4* vector;

/// @name Initializing Planes

/**
* Initializes this plane to the values of a specified plane vector.
*
* @param vector The plane vector. The X, Y and Z components indicate the plane's normal vector. The W component
* indicates the negative of the plane's distance from the origin. The vector is considered to be normalized. It's
* values are copied to this plane; the vector is not retained.
*
* @return This plane initialized to the specified vector.
*
* @exception NSInvalidArgumentException If the specified vector is nil.
*/
- (WWPlane*) initWithNormal:(WWVec4*)vector;

/**
* Initializes this plane to the specified coordinates.
*
* @param x The X coordinate of the plane's unit normal vector.
* @param y The Y coordinate of the plane's unit normal vector.
* @param z The Z coordinate of the plane's unit normal vector.
* @param distance The negative of the plane's distance from the origin.
*
* @return This plane initialized as specified.
*/
- (WWPlane*) initWithCoordinates:(double)x y:(double)y z:(double)z distance:(double)distance;

/// @name Operations on Planes

/**
* Computes the full dot product (X, Y, Z, W) of this plane's normal vector with a specified vector.
*
* @param vector The vector to dot with this plane's normal vector.
*
* @return The dot product.
*
* @exception NSInvalidArgumentException if the specified vector is nil.
*/
- (double) dot:(WWVec4*)vector;

/**
* Transforms this plane by a specified matrix.
*
* @param matrix The matrix to apply to this plane.
*
* @exception NSInvalidArgumentException if the specified matrix is nil.
*/
- (void) transformByMatrix:(WWMatrix*)matrix;

/**
* Normalizes this planes vector by dividing all four of the vector's components by the X, Y, Z length of the vector.
*/
- (void) normalize;

@end