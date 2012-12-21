/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>

@class WWGlobe;

@interface WWMatrix : NSObject
{
@public
    double m[16];
}

- (WWMatrix*) initWithIdentity;

- (WWMatrix*) initWithTranslation:(double)x y:(double)y z:(double)z;

- (WWMatrix*) initWithMatrix:(WWMatrix*)matrix;

- (WWMatrix*) initWithMultiply:(WWMatrix*)matrixA matrixB:(WWMatrix*)matrixB;

- (WWMatrix*) set:(double)m00 m01:(double)m01 m02:(double)m02 m03:(double)m03
              m10:(double)m10 m11:(double)m11 m12:(double)m12 m13:(double)m13
              m20:(double)m20 m21:(double)m21 m22:(double)m22 m23:(double)m23
              m30:(double)m30 m31:(double)m31 m32:(double)m32 m33:(double)m33;

- (WWMatrix*) setIdentity;

- (WWMatrix*) setTranslation:(double)x y:(double)y z:(double) z;

- (WWMatrix*) setUnitYFlip;

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

- (WWMatrix*) setLookAt:(WWGlobe*)globe
         centerLatitude:(double)latitude
        centerLongitude:(double)longitude
         centerAltitude:(double)altitude
          rangeInMeters:(double)range;

- (WWMatrix*) multiply:(WWMatrix*)matrix;

- (WWMatrix*) multiply:(double)m00 m01:(double)m01 m02:(double)m02 m03:(double)m03
                   m10:(double)m10 m11:(double)m11 m12:(double)m12 m13:(double)m13
                   m20:(double)m20 m21:(double)m21 m22:(double)m22 m23:(double)m23
                   m30:(double)m30 m31:(double)m31 m32:(double)m32 m33:(double)m33;

- (WWMatrix*) multiply:(WWMatrix*)matrixA matrixB:(WWMatrix*)matrixB;

/*!
    Inverts the specified matrix and stores the result in this matrix. The specified matrix is assumed to represent an
    orthonormal transform matrix. This matrix's upper 3x3 is transposed, then its fourth column is transformed by the
    transposed upper 3x3 and negated. The result of this method is undefined if this matrix is passed in as the matrix
    to invert.

    @param matrix
        The matrix who's inverse is computed. This matrix is assumed to represent an orthonormal transform matrix.
    @result
        A pointer to this Matrix.
    @throws
        NSInvalidArgumentException if the matrix is nil.
 */
- (WWMatrix*) invertTransformMatrix:(WWMatrix*)matrix;

@end