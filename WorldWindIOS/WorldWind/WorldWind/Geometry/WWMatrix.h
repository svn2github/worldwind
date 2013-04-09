/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>
#import <CoreGraphics/CGGeometry.h>

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

/// @name Working With Transform Matrices

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
* A local origin transform maps a local coordinate space to the local tangent plane on the globe at the specified
* origin. The local origin (0, 0, 0) is mapped to the specified point on the globe, the z axis is mapped to the globe's
* normal vector at the point, the y axis is mapped to the north pointing tangent vector at the point, and the x axis
* is mapped to the east pointing tangent vector at the point.
*
* @param origin The origin of the local coordinate system, relative to the globe.
* @param globe The globe the transform is relative to.
*
* @return This matrix set to a local origin transform matrix.
*
* @exception NSInvalidArgumentException If either argument is nil.
*/
- (WWMatrix*) setToLocalOriginTransform:(WWVec4*)origin onGlobe:(WWGlobe*)globe;

/**
* Extracts this transform matrix's rotation components.
*
* This method assumes that this matrix represents an orthonormal transform matrix, and that successive rotations have
* been applied in the order x, y, z. If this matrix does not represent an orthonormal transform matrix the results are
* undefined.
*
* The rotation angles corresponding to this transform matrix's x, y and z rotations are returned in the result vector's
* x, y and z components, respectively.
*
* @return This transform matrix's rotation angles, in degrees.
*/
- (WWVec4*) extractRotation;

/**
* Extracts this transform matrix's translation components.
*
* This method assumes that this matrix represents an orthonormal transform matrix. If this matrix does not represent an
* orthonormal transform matrix the results are undefined.
*
* The translation vector corresponding to this transform matrix's x, y and z translation is returned in the result
* vector's x, y and z components, respectively.
*
* @return This transform matrix's translation, in model coordinates.
*/
- (WWVec4*) extractTranslation;

/// @name Working With Viewing and Projection Matrices

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
* @exception NSInvalidArgumentException If any argument is nil.
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
* real number. A range of 0 places the eye point at the look at point, while a positive range moves the eye point away
* from but still looking at the look at point.
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
* @param range The distance between the eye point and the look at point, in model coordinates.
* @param heading The viewer's angle relative to north, in degrees.
* @param tilt The viewer's angle relative to the surface, in degrees.
* @param globe The globe the viewer is looking at.
*
* @return This matrix set to a look at person viewing matrix.
*
* @exception NSInvalidArgumentException If any argument is nil.
*/
- (WWMatrix*) setToLookAtModelview:(WWPosition*)lookAtPosition
                             range:(double)range
                    headingDegrees:(double)heading
                       tiltDegrees:(double)tilt
                           onGlobe:(WWGlobe*)globe;

/**
* Sets this matrix to a perspective projection matrix for the specified viewport and clip distances.
*
* A perspective projection matrix maps points in model coordinates into screen coordinates in a way that causes distant
* objects to appear smaller, and preserves the appropriate depth information for each point. In model coordinates, a
* perspective projection is defined by frustum originating at the eye position and extending outward in the viewer's
* direction. The near distance and the far distance identify the minimum and maximum distance, respectively, at which an
* object in the scene is visible. Near and far distances must be positive and may not be equal.
*
* The resultant projection matrix preserves the scene's size on screen when the viewport width and height are swapped.
* This has the effect of maintaining the scene's size when the device is rotated.
*
* @param viewport The viewport rectangle, in screen coordinates.
* @param near The near clip plane distance, in model coordinates.
* @param far The far clip plane distance, in model coordinates.
*
* @return This matrix set to a perspective projection matrix.
*
* @exception NSInvalidArgumentException If either the viewport width or the viewport height are zero, if near and far
* are equivalent, or if either near or far ar not positive.
*/
- (WWMatrix*) setToPerspectiveProjection:(CGRect)viewport nearDistance:(double)near farDistance:(double)far;

/**
* Sets this matrix to an screen projection matrix for the specified viewport.
*
* A screen projection matrix is an orthographic projection that assumes that points in model coordinates represent
* screen coordinates and screen depth values. Screen projection matrices therefore map model coordinates directly into
* screen coordinates without modification. A point's xy coordinates are interpreted as literal screen coordinates and
* must be in the viewport rectangle to be visible. A point's z coordinate is interpreted as a depth value that ranges
* from 0 to 1.
*
* The resultant projection matrix has the effect of preserving coordinates that have already been projected using
* [WWNavigatorState project:result:].
*
* @param viewport The viewport rectangle, in screen coordinates.
*
* @return This matrix set to a screen projection matrix.
*
* @exception NSInvalidArgumentException If either the viewport width or the viewport height are zero.
*/
- (WWMatrix*) setToScreenProjection:(CGRect)viewport;

/**
* Extracts this viewing matrix's eye point.
*
* This method assumes that this matrix represents a viewing matrix. If this does not represent a viewing matrix the
* results are undefined.
*
* In model coordinates, a viewing matrix's eye point is the point the viewer is looking from and maps to the center of
* the screen.
*
* @return This viewing matrix's eye point, in model coordinates.
*/
- (WWVec4*) extractEyePoint;

/**
* Extracts this viewing matrix's forward vector.
*
* This method assumes that this matrix represents a viewing matrix. If this does not represent a viewing matrix the
* results are undefined.
*
* In model coordinates, a viewing matrix's forward vector is the direction the viewer is looking and maps to a vector
* going into the screen.
*
* @return This viewing matrix's forward vector, in model coordinates.
*/
- (WWVec4*) extractForwardVector;

/**
* Extracts this projection matrix's view frustum.
*
* This method assumes that this matrix represents a projection matrix. If this does not represent a projection matrix
* the results are undefined.
*
* A projection matrix's view frustum is a volume of space that contains everything that is visible in a scene displayed
* using the projection matrix. See the Wikipedia [Viewing Frustum page](http://en.wikipedia.org/wiki/Viewing_frustum)
* for an illustration of a viewing frustum. In eye coordinates, a viewing frustum originates at the origin and extends
* outward along the negative z axis. The near distance and the far distance used to initialize a projection matrix
* identify the minimum and maximum distance, respectively, at which an object in the scene is visible.
*
* @return This projection matrix's view frustum, in eye coordinates.
*/
- (WWFrustum*) extractFrustum;

/**
* Applies a specified depth offset to this perspective projection matrix.
*
* This method assumes that this matrix represents a perspective projection matrix. If this does not represent a
* perspective projection matrix the results are undefined. Perspective projection matrices can be created by calling
* [WWMatrix setToPerspectiveProjection:nearDistance:farDistance:].
*
* The offset may be any real number and is typically used to draw subsequent shapes slightly closer to the user's eye in
* order to give those shapes visual priority over terrain or surface shapes. An offset of zero has no effect on the
* scene. An offset less than zero brings depth values closer to the eye, while an offset greater than zero pushes depth
* values away from the eye.
*
* @param depthOffset The amount of offset to apply.
*/
- (void) offsetPerspectiveDepth:(double)depthOffset;

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

/// @name Methods for Internal Use

- (void) lubksb:(const double*)A indx:(const int*)indx b:(double*)b;

- (double) ludcmp:(double*)A indx:(int*)indx;

@end