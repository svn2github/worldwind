/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>

@class WWGlobe;

/**
* Represents a 4x4 double precision matrix and provides operations on and between matrices.
*
* @warning WWMatrix instances are mutable. Most methods of this class modify the instance, itself.
*/
@interface WWMatrix : NSObject <NSCopying>
{
@public
    double m[16];
}

/// @name Initializing Locations

/**
* Designated initializer
*
* Initializes a matrix to the identity.
*
* @return The initialized matrix.
*/
- (WWMatrix*) initWithIdentity;

/**
* Initializes a matrix to represent a specified translation.
*
* @param x The X component of the translation.
* @param y The Y component of the translation.
* @param z The Z component of the translation.
*
* @return The initialized matrix.
*/
- (WWMatrix*) initWithTranslation:(double)x y:(double)y z:(double)z;

/**
* Initializes a matrix to the values of a specified matrix.
*
* @param matrix The matrix containing the values for the returned matrix.
*
* @return The initialized matrix.
*/
- (WWMatrix*) initWithMatrix:(WWMatrix*)matrix;

/**
* Initializes a matrix with the product of two specified matrices.
*
* @param matrixA The first multiplicand.
* @param matrixB The second multiplicand.
*
* @return The initialized matrix.
*
* @exception NSInvalidArgumentException If either argument is nil.
*/
- (WWMatrix*) initWithMultiply:(WWMatrix*)matrixA matrixB:(WWMatrix*)matrixB;

/// @name Setting the Contents of Matrices

/**
* Sets all values of this matrix to specified values.
*
* @param m00 The value at row 0 column 0;
* @param m01 The value at row 0 column 1;
* @param m02 The value at row 0 column 2;
* @param m03 The value at row 0 column 3;
* @param m10 The value at row 1 column 0;
* @param m11 The value at row 1 column 1;
* @param m12 The value at row 1 column 2;
* @param m13 The value at row 1 column 3;
* @param m20 The value at row 2 column 0;
* @param m21 The value at row 2 column 1;
* @param m22 The value at row 2 column 2;
* @param m23 The value at row 2 column 3;
* @param m30 The value at row 3 column 0;
* @param m31 The value at row 3 column 1;
* @param m32 The value at row 3 column 2;
* @param m33 The value at row 3 column 3;
*
* @return This matrix with the specified values.
*/
- (WWMatrix*) set:(double)m00 m01:(double)m01 m02:(double)m02 m03:(double)m03
              m10:(double)m10 m11:(double)m11 m12:(double)m12 m13:(double)m13
              m20:(double)m20 m21:(double)m21 m22:(double)m22 m23:(double)m23
              m30:(double)m30 m31:(double)m31 m32:(double)m32 m33:(double)m33;

/**
* Sets this matrix to the identity matrix.
*
* @return This matrix set to the identity matrix.
*/
- (WWMatrix*) setIdentity;

/**
* Sets this matrix to the translation matrix for specified translation values. All existing values are overridden.
*
* @param x The X translation component.
* @param y The Y translation component.
* @param z The Z translation component.
*
* @return This matrix as a translation matrix for a translation of the specified values.
*/
- (WWMatrix*) setTranslation:(double)x y:(double)y z:(double) z;

/**
* Sets this matrix to one that flips and shifts the Y axis.
*
* All existing values are overwritten. This matrix is
* usually used to change the coordinate origin from an upper left coordinate origin to a lower left coordinate origin.
* This is typically necessary to align the coordinate system of images (upper left origin) with that of OpenGL (lower
* left origin).
*
* @return A matrix that maps Y=0 to Y = 1 and Y=1 to Y=0.
*/
- (WWMatrix*) setUnitYFlip;

/// @name Making Viewing and Perspective Matrices

- (WWMatrix*) setPerspective:(double)left
                       right:(double)right
                      bottom:(double)bottom
                         top:(double)top
                nearDistance:(double)near
                 farDistance:(double)far;

- (WWMatrix*) setPerspectiveFieldOfView:(double)horizontalFOV
                          viewportWidth:(double)width
                         viewportHeight:(double)height
                           nearDistance:(double)near
                            farDistance:(double)far;

- (WWMatrix*) setPerspectiveSizePreserving:(double)width
                            viewportHeight:(double)height
                              nearDistance:(double)near
                               farDistance:(double)far;

- (WWMatrix*) setLookAt:(WWGlobe*)globe
         centerLatitude:(double)latitude
        centerLongitude:(double)longitude
         centerAltitude:(double)altitude
          rangeInMeters:(double)range
                heading:(double)heading
                   tilt:(double)tilt;

/// @name Operations on Matrices

/**
* Multiplies this matrix by a specified matrix.
*
* @param matrix The matrix to multiply with this matrix.
*
* @return This matrix multiplied by the specified matrix: *this matrix X input matrix*.
*
* @exception NSInvalidArgumentException if the specified matrix is nil.
*/
- (WWMatrix*) multiplyMatrix:(WWMatrix*)matrix;

- (WWMatrix*) multiply:(double)m00 m01:(double)m01 m02:(double)m02 m03:(double)m03
                   m10:(double)m10 m11:(double)m11 m12:(double)m12 m13:(double)m13
                   m20:(double)m20 m21:(double)m21 m22:(double)m22 m23:(double)m23
                   m30:(double)m30 m31:(double)m31 m32:(double)m32 m33:(double)m33;

/**
* Inverts the specified matrix and stores the result in this matrix.
*
* The specified matrix is assumed to represent an orthonormal transform matrix. This matrix's upper 3x3 is transposed,
* then its fourth column is transformed by the transposed upper 3x3 and negated.
*
* The result of this method is undefined if this matrix is passed in as the matrix to invert.
*
* @param matrix The matrix whose inverse is computed. This matrix is assumed to represent an orthonormal transform
* matrix.
*
* @return This matrix with its values set to the inverse of the specified matrix.
*
* @exception NSInvalidArgumentException If the specified matrix is nil.
*/
- (WWMatrix*) invertTransformMatrix:(WWMatrix*)matrix;

@end