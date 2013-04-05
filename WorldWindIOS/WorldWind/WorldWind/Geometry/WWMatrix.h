/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>

@class WWFrustum;
@class WWPosition;
@class WWGlobe;
@class WWVec4;

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

/// @name Initializing Matrices

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

/**
* Initializes a matrix to the inverse of a specified matrix.
*
* This throws an exception if the specified matrix is singular.
*
* @param matrix The matrix whose inverse is to initialize this matrix.
*
* @return The initialized matrix.
*
* @exception NSInvalidArgumentException if the specified matrix is nil or cannot be inverted.
*/
- (WWMatrix*) initWithInverse:(WWMatrix*)matrix;

/**
* Initializes a matrix to the inverse of a specified matrix.
*
* @param matrix The matrix whose inverse is to initialize this matrix. The specified matrix is assumed to be
* orthonormal. (See invertTransformMatrix.)
*
* @return The initialized matrix.
*
* @exception NSInvalidArgumentException if the specified matrix is nil.
*/
- (WWMatrix*) initWithTransformInverse:(WWMatrix*)matrix;

/**
* Initializes this matrix to the transpose of a specified matrix.
*
* @param matrix The matrix whose transposed is used to initialize this matrix.
*
* @return This matrix initialized to the transpose of the specified matrix.
*
* @exception NSInvalidArgumentException if the specified matrix is nil.
*/
- (WWMatrix*) initWithTranspose:(WWMatrix*)matrix;

/**
* Initializes this matrix with the covariance matrix for a specified list of points.
*
* @param points The points to consider.
*
* @return This matrix initialized to the covariant matrix for the specified list of points.
*
* @exception NSInvalidArgumentException if the specified list of points is nil.
*/
- (WWMatrix*) initWithCovarianceOfPoints:(NSArray*)points;

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
- (WWMatrix*) setToIdentity;

/// @name Making Transform Matrices

/**
* Sets this matrix to the translation matrix for specified translation values. All existing values are overridden.
*
* @param x The X translation component.
* @param y The Y translation component.
* @param z The Z translation component.
*
* @return This matrix as a translation matrix for a translation of the specified values.
*/
- (WWMatrix*) setToTranslation:(double)x y:(double)y z:(double)z;

/**
* Sets the translation components of this matrix to specified values, leaving the other components unmodified.
*
* @param x The X component of translation.
* @param y The Y component of translation.
* @param z The Z component of translation.
*
* @return This matrix with its translation components set to the specified values.
*/
- (WWMatrix*) setTranslation:(double)x y:(double)y z:(double)z;

/**
* Sets the scale components of this matrix to specified values, leaving the other components unmodified.
*
* @param x The X component of scale.
* @param y The Y component of scale.
* @param z The Z component of scale.
*
* @return This matrix with its scale components set to the specified values.
*/
- (WWMatrix*) setScale:(double)x y:(double)y z:(double)z;

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
- (WWMatrix*) setToUnitYFlip;

/**
* Sets this matrix to a local origin transform for the specified globe.
*
* A local origin transform maps a local coordinate space to a local tangent plane on the globe at the specified origin.
* The local origin (0, 0, 0) is mapped to the specified origin, the z axis is mapped to the globe's normal vector at
* the origin, the y axis is mapped to the north pointing tangent vector at the origin, and the x axis is mapped to
* the east pointing tangent vector at the origin.
*
* @param origin The origin of the local coordinate system, relative to the globe.
* @param globe The globe the transform is relative to.
*
* @return This matrix set to a local origin transform matrix.
*
* @exception If either argument is nil.
*/
- (WWMatrix*) setToLocalOriginTransform:(WWVec4*)origin onGlobe:(WWGlobe*)globe;

/**
* Computes a transform matrix's rotation angles in degrees.
*
* This assumes that this matrix represents a transform matrix, and that successive rotations have been applied in the
* order x, y, z. If this matrix does not represent an orthonormal transform matrix the results are undefined.
*
* The rotation angles corresponding to this transform matrix's x, y and z rotations are returned in the result vector's
* x, y and z components, respectively.
*
* @param result A WWVec4 instance in which to return the rotation angles.
*
* @exception NSInvalidArgumentException If the result is nil.
*/
- (void) transformRotationAngles:(WWVec4*)result;

/**
* Computes a transform matrix's translation in model coordinates.
*
* This assumes that this matrix represents a transform matrix. If this matrix does not represent an orthonormal
* transform matrix the results are undefined.
*
* The translation vector corresponding to this transform matrix's x, y and z translation is returned in the result
* vector's x, y and z components, respectively.
*
* @param result A WWVec4 instance in which to return the translation.
*
* @exception NSInvalidArgumentException If the result is nil.
*/
- (void) transformTranslation:(WWVec4*)result;

/// @name Making Viewing and Perspective Matrices

/**
* Sets this matrix to a first person viewing matrix for the specified globe.
*
* A first person viewing matrix places the viewer's eye at the specified eyePosition. By default the viewer is looking
* straight down at the globe's surface from the eye position, with the globe's normal vector coming out of the screen
* and north pointing toward the top of the screen.
*
* Heading specifies the viewer's azimuth, or its angle relative to North. Heading values range from -180 degrees to 180
* degrees. A heading of 0 degrees looks North, 90 degrees looks East, +-180 degrees looks South, and -90 degrees looks
* West.
*
* Tilt specifies the viewer's angle relative ot the surface. Tilt values range from -180 degrees to 180 degrees. A tilt
* of 0 degrees looks straight down at the globe's surface, 90 degrees looks at the horizon, and 180 degrees looks
* straight up. Tilt values greater than 180 degrees cause the viewer to turn upside down, and are therefore rarely used.
*
* @param eyePosition The viewer's geographic eye position relative to the specified globe.
* @param heading The viewer's angle relative to north, in degrees.
* @param tilt The viewer's angle relative to the surface, in degrees.
* @param globe The globe the viewer is looking at.
*
* @return This matrix set to a first person viewing matrix.
*
* @exception If any argument is nil.
*/
- (WWMatrix*) setToFirstPersonModelview:(WWPosition*)eyePosition
                         headingDegrees:(double)heading
                            tiltDegrees:(double)tilt
                                onGlobe:(WWGlobe*)globe;

/**
* Sets this matrix to a look at viewing matrix for the specified globe.
*
* A look at viewing matrix places the center of the screen at the specified lookAtPosition. By default the viewer is
* looking straight down at the look at position from the specified range, with the globe's normal vector coming out of
* the screen and north pointing toward the top of the screen.
*
* Range specifies the distance between the look at position and the viewer's eye point. Range values may be any positive
* real number. A range of 0 meters places the eye point at the look at point, while a positive range moves the eye point
* away from but still looking at the look at point.
*
* Heading specifies the viewer's azimuth, or its angle relative to North. Heading values range from -180 degrees to 180
* degrees. A heading of 0 degrees looks North, 90 degrees looks East, +-180 degrees looks South, and -90 degrees looks
* West.
*
* Tilt specifies the viewer's angle relative ot the surface. Tilt values range from -180 degrees to 180 degrees. A tilt
* of 0 degrees looks straight down at the globe's surface, 90 degrees looks at the horizon, and 180 degrees looks
* straight up. Tilt values greater than 180 degrees cause the viewer to turn upside down, and are therefore rarely used.
*
* @param lookAtPosition The viewer's geographic look at position relative to the specified globe.
* @param range The distance between the eye point and the look at point, in meters.
* @param heading The viewer's angle relative to north, in degrees.
* @param tilt The viewer's angle relative to the surface, in degrees.
* @param globe The globe the viewer is looking at.
*
* @return This matrix set to a look at person viewing matrix.
*
* @exception If any argument is nil.
*/
- (WWMatrix*) setToLookAtModelview:(WWPosition*)lookAtPosition
                     rangeInMeters:(double)range
                    headingDegrees:(double)heading
                       tiltDegrees:(double)tilt
                           onGlobe:(WWGlobe*)globe;

- (WWMatrix*) setOrthoFromLeft:(double)left
                         right:(double)right
                        bottom:(double)bottom
                           top:(double)top
                  nearDistance:(double)near
                   farDistance:(double)far;

- (WWMatrix*) setOrthoFromWidth:(double)width
                         height:(double)height;

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

/**
* Computes a modelview matrix's eye point in model coordinates.
*
* In model coordinates, a modelview matrix's eye point is the point the viewer is looking from. In eye coordinates the
* eye point maps to the center of the screen. If this does not represent a modelview matrix the results are undefined.
*
* The computed point is stored in the result parameter after this method returns.
*
* @param result A WWVec4 instance in which to return the eye point.
*
* @exception NSInvalidArgumentException If the result is nil.
*/
- (void) modelviewEyePoint:(WWVec4*)result;

/**
* Computes a modelview matrix's forward vector in model coordinates.
*
* In model coordinates, a modelview matrix's forward vector is the direction the viewer is looking. In eye coordinates
* the forward vector maps to a vector going into the screen. If this matrix does not represent a modelview matrix the
* results of this method are undefined.
*
* The computed point is stored in the result parameter after this method returns.
*
* @param result A WWVec4 instance in which to return the forward vector.
*
* @exception NSInvalidArgumentException If the result is nil.
*/
- (void) modelviewForward:(WWVec4*)result;

/// @name Matrix Operations

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

/**
* Multiplies this matrix by a matrix specified by individual components.
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
* @return This matrix multiplied by the matrix with the specified values.
*/
- (WWMatrix*) multiply:(double)m00 m01:(double)m01 m02:(double)m02 m03:(double)m03
                   m10:(double)m10 m11:(double)m11 m12:(double)m12 m13:(double)m13
                   m20:(double)m20 m21:(double)m21 m22:(double)m22 m23:(double)m23
                   m30:(double)m30 m31:(double)m31 m32:(double)m32 m33:(double)m33;

/**
* Inverts the specified matrix and stores the result in this matrix.
*
* This throws an exception if the specified matrix is singular.
*
* The result of this method is undefined if this matrix is passed in as the matrix to invert.
*
* @param matrix The matrix whose inverse is computed.
*
* @return This matrix with its values set to the inverse of the specified matrix.
*
* @exception NSInvalidArgumentException If the specified matrix is nil or cannot be inverted.
*/
- (WWMatrix*) invert:(WWMatrix*)matrix;

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

/**
* Computes the eigensystem of a specified matrix.
*
* @param matrix The matrix to consider.
* @param resultEigenvalues An array in which to return the three eigenvalues.
* @param resultEigenvectors An array in which to return the three eigenvectors.
*
* @exception NSInvalidArgumentException if any argument is nil.
*/
+ (void) eigensystemFromSymmetricMatrix:(WWMatrix*)matrix
                      resultEigenvalues:(NSMutableArray*)resultEigenvalues
                     resultEigenvectors:(NSMutableArray*)resultEigenvectors;

/**
* Extracts a frustum from this perspective matrix.
*
* @return The frustum represented by the specified perspective matrix.
*/
- (WWFrustum*) extractFrustum;

/**
* Applies a specified offset to this projection matrix.
*
* The offset is typically used to draw subsequent shapes slightly closer to the user's eye in order to give those
* shapes visual priority over terrain or surface shapes.
*
* @param depthOffset The amount of offset to apply.
*/
- (void) offsetPerspectiveDepth:(double)depthOffset;

/// @name Methods for Internal Use

- (void) lubksb:(const double*)A indx:(const int*)indx b:(double*)b;

- (double) ludcmp:(double*)A indx:(int*)indx;

@end