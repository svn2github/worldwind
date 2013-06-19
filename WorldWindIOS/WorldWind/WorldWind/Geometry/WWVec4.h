/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

@class WWMatrix;

/**
* Represents a 4D Cartesian coordinate or vector.
*
* @warning WWVec4 instances are mutable. Most methods of this class modify the instance, itself.
*/
@interface WWVec4 : NSObject <NSCopying>

/// @name Vector Attributes

/// The vector's X coordinate.
@property (nonatomic) double x;
/// The vector's Y coordinate.
@property (nonatomic) double y;
/// The vector's Z coordinate.
@property (nonatomic) double z;
/// The vector's W coordinate.
@property (nonatomic) double w;

/**
* The Cartesian length of the vector, not including the W component.
*
* @return The vector's length considering only the X, Y and Z components.
*/
- (double) length3;

/**
* The square of the Cartesian vector length, not including the W component.
*
* This operation avoids the overhead of computing the square root.
*
* @return The vector's length squared.
*/
- (double) lengthSquared3;

/// @name Initializing Vectors

/**
* Initializes a vector with specified X, Y and Z coordinates. The W coordinate is set to 1.
*
* @param x The vector's X coordinate.
* @param y The vector's Y coordinate.
* @param z The vector's Z coordinate.
*
* @return This vector initialized to the specified values.
*/
- (WWVec4*) initWithCoordinates:(double)x y:(double)y z:(double)z;

/**
* Initializes a vector with specified X, Y, Z and W coordinates.
*
* @param x The vector's X coordinate.
* @param y The vector's Y coordinate.
* @param z The vector's Z coordinate.
* @param w The vector's W coordinate.
*
* @return This vector initialized to the specified values.
*/
- (WWVec4*) initWithCoordinates:(double)x y:(double)y z:(double)z w:(double)w;

/**
* Initialize this vector to the values of a specified vector.
*
* @param vector The vector whose values to assign this instance's.
*
* @result This vector initialized to the values in the specified vector.
*
* @exception NSInvalidArgumentException If the vector is nil.
*/
- (WWVec4*) initWithVector:(WWVec4*)vector;

/**
* Initialize this vector with the average of a specified list of vectors.
*
* @param vectors The vectors to average.
*
* @result This vector initialized to the average of the specified vectors.
*
* @exception NSInvalidArgumentException If the specified list is nil or empty.
*/
- (WWVec4*) initWithAverageOfVectors:(NSArray*) vectors;

/**
* Initializes this vector to the zero vector, with X, Y and Z set to 0 and W set to 1.
*
* @return This vector initialized to the zero vector.
*/
- (WWVec4*) initWithZeroVector;

/// @name Changing Vector Values

/**
* Sets this vector's X and Y coordinates to specified values.
*
* @param x The vector's X coordinate.
* @param y The vector's Y coordinate.
*/
- (void) set:(double)x y:(double)y;

/**
* Sets this vector's X, Y and Z coordinates to specified values.
*
* @param x The vector's X coordinate.
* @param y The vector's Y coordinate.
* @param z The vector's Z coordinate.
*/
- (void) set:(double)x y:(double)y z:(double)z;

/**
* Sets this vector's coordinates to specified values.
*
* @param x The vector's X coordinate.
* @param y The vector's Y coordinate.
* @param z The vector's Z coordinate.
* @param w The vector's W coordinate.
*/
- (void) set:(double)x y:(double)y z:(double)z w:(double)w;

/**
* Sets this vector's coordinates to the coordinates of the specified vector.
*
* @param vector The vector whose values are assigned to this instance's.
*
* @exception NSInvalidArgumentException If the vector is nil.
*/
- (void) set:(WWVec4*)vector;

/**
* Sets this vector to the zero vector, with X, Y and Z set to 0 and W set to 1.
*/
- (void) setToZeroVector;

/// @name Operating on Vectors

/**
* Normalize this vector to a unit vector in X, Y and Z.
*
* If the vector prior to invoking this method is the zero vector, this vector is not changed.
*/
- (void) normalize3;

/**
* Add the X, Y and Z coordinates of a specified vector to this vector.
*
* @param vector The vector to add to this vector.
*
* @exception NSInvalidArgumentException If the vector is nil.
*/
- (void) add3:(WWVec4*)vector;

/**
* Subtract the X, Y and Z coordinates of a specified vector from this vector.
*
* @param vector The vector to subtract from this vector.
*
* @exception NSInvalidArgumentException If the vector is nil.
*/
- (void) subtract3:(WWVec4*)vector;

/**
* Multiplies the X, Y and Z components of this vector by a specified scalar.
*
* @param scalar The scalar to multiply.
*/
- (void) multiplyByScalar3:(double)scalar;

/**
* Multiplies all four components of this vector by a specified scalar.
*
* @param scalar The scalar to multiply.
*/
- (void) multiplyByScalar:(double)scalar;

/**
* Multiplies all four components of this vector by a specified matrix.
*
* @param matrix The matrix to multiply.
*
* @exception NSInvalidArgumentException If the specified matrix is nil.
*/
- (void) multiplyByMatrix:(WWMatrix*)matrix;

- (void) divideByScalar3:(double)scalar;

- (void) divideByScalar:(double)scalar;

/**
* Computes the Cartesian distance between points represented by this vector and a specified vector.
*
* @param vector The vector identifying the distant point.
*
* @return The Cartesian distance between the two points.
*
* @exception NSInvalidArgumentException If the vector is nil.
*/
- (double) distanceTo3:(WWVec4*)vector;

/**
* Computes the square of the Cartesian distance between points represented by this vector and a specified vector.
*
* This method avoids computing the square root that would produce the actual distance between the two points.
*
* @param vector The vector identifying the distant point.
*
* @return The square of the Cartesian distance between the two points.
*
* @exception NSInvalidArgumentException If the vector is nil.
*/
- (double) distanceSquared3:(WWVec4*)vector;

/**
* Computes the X, Y, Z dot product of this vector with a specified vector.
*
* @param vector The vector to dot with this vector.
*
* @return The dot product.
*
* @exception NSInvalidArgumentException If the vector is nil.
*/
- (double) dot3:(WWVec4*)vector;

/**
* Computes the cross product of this vector and a specified vector, then stores the result in this vector.
*
* The cross product computed by this method is equivalent to va = va x vb, where 'va' is this vector and 'vb' is the
* specified vector.
*
* @param vector The vector to cross with this vector.
*
* @exception NSInvalidArgumentException If the vector is nil.
*/
- (void) cross3:(WWVec4*)vector;

/**
* Computes a point on a specified line.
*
* @param origin The origin of the line.
* @param direction The direction of the line.
* @param t The distance in meters along the line at which to select the point.
* @param result A WWVec4 instance in which to return the result.
*
* @exception NSInvalidArgumentException If any argument is nil.
*/
+ (void) pointOnLine:(WWVec4*)origin direction:(WWVec4*)direction t:(double)t result:(WWVec4*)result;

@end
