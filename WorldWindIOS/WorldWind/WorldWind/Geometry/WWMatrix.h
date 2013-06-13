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
@class WWTexture;
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
* Sets this matrix to the identity matrix.
*
* @return This matrix set to the identity matrix.
*/
- (WWMatrix*) setToIdentity;

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
* Sets this matrix to the values of a specified matrix.
*
* @param matrix The matrix whose values are assigned to this instance's.
*
* @return This matrix with its values set to those of the specified matrix.
*
* @exception NSInvalidArgumentException If the matrix is nil.
*/
- (WWMatrix*) setToMatrix:(WWMatrix*)matrix;

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
* Multiplies this matrix by a translation matrix with the specified translation values.
*
* @param x The X translation component.
* @param y The Y translation component.
* @param z The Z translation component.
*
* @return This matrix multiplied by a translation matrix.
*/
- (WWMatrix*) multiplyByTranslation:(double)x y:(double)y z:(double)z;

/**
* Multiplies this matrix by a rotation matrix about the specified axis and angle.
*
* The x-, y-, and z-coordinates indicate the axis' direction in model coordinates, and the angle indicates the rotation
* about the axis in degrees. Rotation is performed counter-clockwise when the axis is pointed toward the viewer.
*
* @param x The rotation axis' X component.
* @param y The rotation axis' Y component.
* @param z The rotation axis' Z component.
* @param angle The rotation angle, in degrees.
*
* @return This matrix multiplied by a rotation matrix.
*/
- (WWMatrix*) multiplyByRotationAxis:(double)x y:(double)y z:(double)z angleDegrees:(double)angle;

/**
* Multiplies this matrix by a scaling matrix with the specified values.
*
* @param x The X scaling component.
* @param y The Y scaling component.
* @param z The Z scaling component.
*
* @return This matrix multiplied by a scaling matrix.
*/
- (WWMatrix*) multiplyByScale:(double)x y:(double)y z:(double)z;

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
* Sets this matrix to one that flips and shifts the y-axis.
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
* Multiplies this matrix by a local coordinate system transform for the specified globe.
*
* The local coordinate system is defined such that the local origin (0, 0, 0) maps to the specified origin point, the z
* axis maps to the globe's surface normal at the point, the y-axis maps to the north pointing tangent, and the x-axis
* maps to the east pointing tangent.
*
* @param origin The local coordinate system origin, in model coordinates.
* @param globe The globe the coordinate system is relative to.
*
* @return This matrix multiplied by a local coordinate system transform matrix.
*
* @exception NSInvalidArgumentException If either argument is nil.
*/
- (WWMatrix*) multiplyByLocalCoordinateTransform:(WWVec4*)origin onGlobe:(WWGlobe*)globe;

/**
* Multiplies this matrix by a texture image transform for the specified texture.
*
* A texture image transform maps the bottom-left corner of the texture's image data to coordinate [0,0] and maps the
* top-right of the texture's image data to coordinate [1,1]. This correctly handles textures whose image data has
* non-power-of-two dimensions, and correctly orients textures whose image data has its origin in the upper-left corner.
*
* @param texture The texture to multiply a transform for.
*
* @return This matrix multiplied by a texture transform matrix.
*
* @exception NSInvalidArgumentException If the texture is nil.
*/
- (WWMatrix*) multiplyByTextureTransform:(WWTexture*)texture;

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

/// @name Working With Viewing and Projection Matrices

/**
* Multiplies this matrix by a first person viewing matrix for the specified globe.
*
* A first person viewing matrix places the viewer's eye at the specified eyePosition. By default the viewer is looking
* straight down at the globe's surface from the eye position, with the globe's normal vector coming out of the screen
* and north pointing toward the top of the screen.
*
* Heading specifies the viewer's azimuth, or its angle relative to North. Heading values range from -180 degrees to 180
* degrees. A heading of 0 degrees looks North, 90 degrees looks East, +-180 degrees looks South, and -90 degrees looks
* West.
*
* Tilt specifies the viewer's angle relative to the surface. Tilt values range from -180 degrees to 180 degrees. A tilt
* of 0 degrees looks straight down at the globe's surface, 90 degrees looks at the horizon, and 180 degrees looks
* straight up. Tilt values greater than 180 degrees cause the viewer to turn upside down, and are therefore rarely used.
*
* Roll specifies the viewer's angle relative to the horizon. Roll values range from -180 degrees to 180 degrees. A roll
* of 0 degrees orients the viewer so that up is pointing to the top of the screen, at 90 degrees up is pointing to the
* right, at +-180 degrees up is pointing to the bottom, and at -90 up is pointing to the left.
*
* @param eyePosition The viewer's geographic eye position relative to the specified globe.
* @param heading The viewer's angle relative to north, in degrees.
* @param tilt The viewer's angle relative to the surface, in degrees.
* @param roll The viewer's angle relative to the horizon, in degrees.
* @param globe The globe the viewer is looking at.
*
* @return This matrix multiplied by a first person viewing matrix.
*
* @exception NSInvalidArgumentException If any argument is nil.
*/
- (WWMatrix*) multiplyByFirstPersonModelview:(WWPosition*)eyePosition
                              headingDegrees:(double)heading
                                 tiltDegrees:(double)tilt
                                 rollDegrees:(double)roll
                                     onGlobe:(WWGlobe*)globe;
/**
* Multiplies this matrix by a look at viewing matrix for the specified globe.
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
* Tilt specifies the viewer's angle relative to the surface. Tilt values range from -180 degrees to 180 degrees. A tilt
* of 0 degrees looks straight down at the globe's surface, 90 degrees looks at the horizon, and 180 degrees looks
* straight up. Tilt values greater than 180 degrees cause the viewer to turn upside down, and are therefore rarely used.
*
* Roll specifies the viewer's angle relative to the horizon. Roll values range from -180 degrees to 180 degrees. A roll
* of 0 degrees orients the viewer so that up is pointing to the top of the screen, at 90 degrees up is pointing to the
* right, at +-180 degrees up is pointing to the bottom, and at -90 up is pointing to the left.
*
* @param lookAtPosition The viewer's geographic look at position relative to the specified globe.
* @param range The distance between the eye point and the look at point, in model coordinates.
* @param heading The viewer's angle relative to north, in degrees.
* @param tilt The viewer's angle relative to the surface, in degrees.
* @param roll The viewer's angle relative to the horizon, in degrees.
* @param globe The globe the viewer is looking at.
*
* @return This matrix multiplied by a look at viewing matrix.
*
* @exception NSInvalidArgumentException If any argument is nil.
*/
- (WWMatrix*) multiplyByLookAtModelview:(WWPosition*)lookAtPosition
                                  range:(double)range
                         headingDegrees:(double)heading
                            tiltDegrees:(double)tilt
                            rollDegrees:(double)roll
                                onGlobe:(WWGlobe*)globe;

/**
* Sets this matrix to a perspective projection matrix for the specified viewport and clip distances.
*
* A perspective projection matrix maps points in eye coordinates into clip coordinates in a way that causes distant
* objects to appear smaller, and preserves the appropriate depth information for each point. In model coordinates, a
* perspective projection is defined by frustum originating at the eye position and extending outward in the viewer's
* direction. The near distance and the far distance identify the minimum and maximum distance, respectively, at which an
* object in the scene is visible. Near and far distances must be positive and may not be equal.
*
* The viewport is in the OpenGL screen coordinate system, with its origin in the bottom-left corner and axes that extend
* up and to the right from the origin point. The resultant projection matrix preserves the scene's size on screen when
* the viewport width and height are swapped. This has the effect of maintaining the scene's size when the device is
* rotated.
*
* @param viewport The viewport rectangle, in OpenGL screen coordinates.
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
* The viewport is in the OpenGL screen coordinate system, with its origin in the bottom-left corner and axes that extend
* up and to the right from the origin point.
*
* @param viewport The viewport rectangle, in OpenGL screen coordinates.
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
* Extracts this viewing matrix's parameters.
*
* This method assumes that this matrix represents a viewing matrix. If this does not represent a viewing matrix the
* results are undefined. For details on viewing matrices, see
* [WWMatrix multiplyByFirstPersonModelview:headingDegrees:tiltDegrees:rollDegrees:onGlobe:]
* [WWMatrix multiplyByLookAtModelview:range:headingDegrees:tiltDegrees:rollDegrees:onGlobe:].
*
* TODO: Provide an overloaded version that does not require a known roll.
*
* TODO: Outline what is returned.
*
* TODO: Outline why the origin and roll parameters are required.
* TODO: Outline that origin must be ether the eye point or a point on the line from the eye point along the forward vector.
*
* @param origin TODO
* @param roll TODO
* @param globe The globe the viewer is looking at.
*
* @return TODO
*
* @exception NSInvalidArgumentException If either argument is nil.
*/
- (NSDictionary*) extractViewingParameters:(WWVec4*)origin forRollDegrees:(double)roll onGlobe:(WWGlobe*)globe;

/**
* Extracts this projection matrix's view frustum.
*
* This method assumes that this matrix represents a projection matrix. If this does not represent a projection matrix
* the results are undefined.
*
* A projection matrix's view frustum is a volume of space that contains everything that is visible in a scene displayed
* using the projection matrix. See the Wikipedia [Viewing Frustum page](http://en.wikipedia.org/wiki/Viewing_frustum)
* for an illustration of a viewing frustum. In eye coordinates, a viewing frustum originates at the origin and extends
* outward along the negative z-axis. The near distance and the far distance used to initialize a projection matrix
* identify the minimum and maximum distance, respectively, at which an object in the scene is visible.
*
* @return This projection matrix's view frustum, in eye coordinates.
*/
- (WWFrustum*) extractFrustum;

/**
* Applies a specified depth offset to this projection matrix.
*
* This method assumes that this matrix represents a projection matrix. If this does not represent a projection matrix
* the results are undefined. Projection matrices can be created by calling
* setToPerspectiveProjection:nearDistance:farDistance: or setToScreenProjection:.
*
* The depth offset may be any real number and is typically used to draw geometry slightly closer to the user's eye in
* order to give those shapes visual priority over nearby or geometry. An offset of zero has no effect. An offset less
* than zero brings depth values closer to the eye, while an offset greater than zero pushes depth values away from the
* eye.
*
* Depth offset may be applied to both perspective and orthographic projection matrices. The effect on each projection
* type is outlined here:
*
* *Perspective Projection*
*
* The effect of depth offset on a perspective projection increases exponentially with distance from the eye. This
* has the effect of adjusting the offset for the loss in depth precision with geometry drawn further from the eye.
* Distant geometry requires a greater offset to differentiate itself from nearby geometry, while close geometry does
* not.
*
* *Orthographic Projection*
*
* The effect of depth offset on an orthographic projection increases linearly with distance from the eye. While it is
* reasonable to apply a depth offset to an orthographic projection, the effect is most appropriate when applied to the
* projection used to draw the scene. For example, when an object's coordinates are projected by a perspective projection
* into screen coordinates then drawn using an orthographic projection, it is best to apply the offset to the original
* perspective projection. The method [WWNavigatorState project:result:depthOffset:] performs the correct behavior
* for the projection type used to draw the scene.
*
* @param depthOffset The amount of offset to apply.
*/
- (void) offsetProjectionDepth:(double)depthOffset;

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