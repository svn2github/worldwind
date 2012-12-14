/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>

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
              m20:(double)m20 m21:(double)m21 m12:(double)m22 m13:(double)m23
              m30:(double)m30 m31:(double)m31 m32:(double)m32 m33:(double)m33;

@end