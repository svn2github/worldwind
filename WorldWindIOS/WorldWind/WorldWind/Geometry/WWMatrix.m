/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "WWMatrix.h"

@implementation WWMatrix

- (WWMatrix*) initWithIdentity
{
    self = [super init];

    self->m[0] = 1;
    self->m[1] = 0;
    self->m[2] = 0;
    self->m[3] = 0;
    self->m[4] = 0;
    self->m[5] = 1;
    self->m[6] = 0;
    self->m[7] = 0;
    self->m[8] = 0;
    self->m[9] = 0;
    self->m[10] = 1;
    self->m[11] = 0;
    self->m[12] = 0;
    self->m[13] = 0;
    self->m[14] = 0;
    self->m[15] = 1;

    return self;
}

- (WWMatrix*) initWithTranslation:(double)x y:(double)y z:(double)z
{
    self = [super init];

    self->m[0] = 1;
    self->m[1] = 0;
    self->m[2] = 0;
    self->m[3] = x;
    self->m[4] = 0;
    self->m[5] = 1;
    self->m[6] = 0;
    self->m[7] = y;
    self->m[8] = 0;
    self->m[9] = 0;
    self->m[10] = 1;
    self->m[11] = z;
    self->m[12] = 0;
    self->m[13] = 0;
    self->m[14] = 0;
    self->m[15] = 1;

    return self;
}

- (WWMatrix*) initWithMatrix:(WWMatrix*)matrix
{
    self = [super init];

    self->m[0] = matrix->m[0];
    self->m[1] = matrix->m[1];
    self->m[2] = matrix->m[2];
    self->m[3] = matrix->m[3];
    self->m[4] = matrix->m[4];
    self->m[5] = matrix->m[5];
    self->m[6] = matrix->m[6];
    self->m[7] = matrix->m[7];
    self->m[8] = matrix->m[8];
    self->m[9] = matrix->m[9];
    self->m[10] = matrix->m[10];
    self->m[11] = matrix->m[11];
    self->m[12] = matrix->m[12];
    self->m[13] = matrix->m[13];
    self->m[14] = matrix->m[14];
    self->m[15] = matrix->m[15];

    return self;
}

- (WWMatrix*) initWithMultiply:(WWMatrix*)matrixA matrixB:(WWMatrix*)matrixB
{
    self = [super init];

    double* r = self->m;
    double* ma = matrixA->m;
    double* mb = matrixB->m;

    r[0] = ma[0] * mb[0] + ma[1] * mb[4] + ma[2] * mb[8] + ma[3] * mb[12];
    r[1] = ma[0] * mb[1] + ma[1] * mb[5] + ma[2] * mb[9] + ma[3] * mb[13];
    r[2] = ma[0] * mb[2] + ma[1] * mb[6] + ma[2] * mb[10] + ma[3] * mb[14];
    r[3] = ma[0] * mb[3] + ma[1] * mb[7] + ma[2] * mb[11] + ma[3] * mb[15];

    r[4] = ma[4] * mb[0] + ma[5] * mb[4] + ma[6] * mb[8] + ma[7] * mb[12];
    r[5] = ma[4] * mb[1] + ma[5] * mb[5] + ma[6] * mb[9] + ma[7] * mb[13];
    r[6] = ma[4] * mb[2] + ma[5] * mb[6] + ma[6] * mb[10] + ma[7] * mb[14];
    r[7] = ma[4] * mb[3] + ma[5] * mb[7] + ma[6] * mb[11] + ma[7] * mb[15];

    r[8] = ma[8] * mb[0] + ma[9] * mb[4] + ma[10] * mb[8] + ma[11] * mb[12];
    r[9] = ma[8] * mb[1] + ma[9] * mb[5] + ma[10] * mb[9] + ma[11] * mb[13];
    r[10] = ma[8] * mb[2] + ma[9] * mb[6] + ma[10] * mb[10] + ma[11] * mb[14];
    r[11] = ma[8] * mb[3] + ma[9] * mb[7] + ma[10] * mb[11] + ma[11] * mb[15];

    r[12] = ma[12] * mb[0] + ma[13] * mb[4] + ma[14] * mb[8] + ma[15] * mb[12];
    r[13] = ma[12] * mb[1] + ma[13] * mb[5] + ma[14] * mb[9] + ma[15] * mb[13];
    r[14] = ma[12] * mb[2] + ma[13] * mb[6] + ma[14] * mb[10] + ma[15] * mb[14];
    r[15] = ma[12] * mb[3] + ma[13] * mb[7] + ma[14] * mb[11] + ma[15] * mb[15];

    return self;
}

@end