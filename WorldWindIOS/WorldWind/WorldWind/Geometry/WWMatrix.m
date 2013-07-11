/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "WorldWind/Geometry/WWMatrix.h"
#import "WorldWind/Geometry/WWFrustum.h"
#import "WorldWind/Geometry/WWPlane.h"
#import "WorldWind/Geometry/WWPosition.h"
#import "WorldWind/Geometry/WWVec4.h"
#import "WorldWind/Render/WWTexture.h"
#import "WorldWind/Terrain/WWGlobe.h"
#import "WorldWind/Util/WWMath.h"
#import "WorldWind/WorldWindConstants.h"
#import "WorldWind/WWLog.h"

#define INDEX(i, j) (i) * 4 + (j)
#define NEAR_ZERO_THRESHOLD 1.0e-8
#define TINY_VALUE 1.0e-20

void WWMatrixSwapEigenvalues(double* a, double* b, int* ia, int* ib)
{
    double tmp = *a;
    *a = *b;
    *b = tmp;

    int itmp = *ia;
    *ia = *ib;
    *ib = itmp;
}

@implementation WWMatrix

//--------------------------------------------------------------------------------------------------------------------//
//-- Matrix Attributes --//
//--------------------------------------------------------------------------------------------------------------------//

- (void) columnMajorComponents:(float[])array
{
    if (!array)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Array is NULL");
    }

    // Column 1
    array[0] = (float) m[0];
    array[1] = (float) m[4];
    array[2] = (float) m[8];
    array[3] = (float) m[12];
    // Column 2
    array[4] = (float) m[1];
    array[5] = (float) m[5];
    array[6] = (float) m[9];
    array[7] = (float) m[13];
    // Column 3
    array[8] = (float) m[2];
    array[9] = (float) m[6];
    array[10] = (float) m[10];
    array[11] = (float) m[14];
    // Column 4
    array[12] = (float) m[3];
    array[13] = (float) m[7];
    array[14] = (float) m[11];
    array[15] = (float) m[15];
}

//--------------------------------------------------------------------------------------------------------------------//
//-- Initializing Matrices --//
//--------------------------------------------------------------------------------------------------------------------//

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

- (WWMatrix*) initWithMatrix:(WWMatrix* __unsafe_unretained)matrix
{
    if (matrix == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Matrix is nil");
    }

    self = [super init];

    memcpy(self->m, matrix->m, (size_t) (16 * sizeof(double)));

    return self;
}

- (WWMatrix*) initWithInverse:(WWMatrix* __unsafe_unretained)matrix
{
    if (matrix == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Matrix is nil");
    }

    self = [super init];

    [self invert:matrix];

    return self;
}

- (WWMatrix*) initWithTransformInverse:(WWMatrix* __unsafe_unretained)matrix
{
    if (matrix == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Matrix is nil");
    }

    self = [super init];

    [self invertTransformMatrix:matrix];

    return self;
}

- (WWMatrix*) initWithTranspose:(WWMatrix* __unsafe_unretained)matrix
{
    if (matrix == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Matrix is nil");
    }

    self = [super init];

    self->m[0] = matrix->m[0];
    self->m[1] = matrix->m[4];
    self->m[2] = matrix->m[8];
    self->m[3] = matrix->m[12];
    self->m[4] = matrix->m[1];
    self->m[5] = matrix->m[5];
    self->m[6] = matrix->m[9];
    self->m[7] = matrix->m[13];
    self->m[8] = matrix->m[2];
    self->m[9] = matrix->m[6];
    self->m[10] = matrix->m[10];
    self->m[11] = matrix->m[14];
    self->m[12] = matrix->m[3];
    self->m[13] = matrix->m[7];
    self->m[14] = matrix->m[11];
    self->m[15] = matrix->m[15];

    return self;
}

- (WWMatrix*) initWithMultiply:(WWMatrix* __unsafe_unretained)matrixA matrixB:(WWMatrix* __unsafe_unretained)matrixB
{
    self = [super init];

    if (matrixA == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"First matrix is nil");
    }

    if (matrixB == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Second matrix is nil");
    }

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

- (WWMatrix*) initWithCovarianceOfPoints:(NSArray* __unsafe_unretained)points
{
    if (points == nil || [points count] == 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Points is nil or empty");
    }
    
    self = [super init];

    WWVec4* mean = [[WWVec4 alloc] initWithAverageOfVectors:points];
    double mx = [mean x];
    double my = [mean y];
    double mz = [mean z];
    double dx;
    double dy;
    double dz;

    int count = 0;
    double c11 = 0;
    double c22 = 0;
    double c33 = 0;
    double c12 = 0;
    double c13 = 0;
    double c23 = 0;

    for (WWVec4* __unsafe_unretained vec in points) // no need to check for nil; NSArray does not permit nil elements
    {
        dx = [vec x] - mx;
        dy = [vec y] - my;
        dz = [vec z] - mz;

        ++count;
        c11 += dx * dx;
        c22 += dy * dy;
        c33 += dz * dz;
        c12 += dx * dy; // c12 = c21
        c13 += dx * dz; // c13 = c31
        c23 += dy * dz; // c23 = c32
    }

    // Row 1
    self->m[0] = c11 / (double) count;
    self->m[1] = c12 / (double) count;
    self->m[2] = c13 / (double) count;
    self->m[3] = 0;

    // Row 2
    self->m[4] = c12 / (double) count;
    self->m[5] = c22 / (double) count;
    self->m[6] = c23 / (double) count;
    self->m[7] = 0;

    // Row 3
    self->m[8] = c13 / (double) count;
    self->m[9] = c23 / (double) count;
    self->m[10] = c33 / (double) count;
    self->m[11] = 0;

    // Row 4
    self->m[12] = 0;
    self->m[13] = 0;
    self->m[14] = 0;
    self->m[15] = 0;

    return self;
}

- (BOOL) isEqual:(WWMatrix* __unsafe_unretained)n
{
    return self->m[0] == n->m[0]
            && self->m[1] == n->m[1]
            && self->m[2] == n->m[2]
            && self->m[3] == n->m[3]
            && self->m[4] == n->m[4]
            && self->m[5] == n->m[5]
            && self->m[6] == n->m[6]
            && self->m[7] == n->m[7]
            && self->m[8] == n->m[8]
            && self->m[9] == n->m[9]
            && self->m[10] == n->m[10]
            && self->m[11] == n->m[11]
            && self->m[12] == n->m[12]
            && self->m[13] == n->m[13]
            && self->m[14] == n->m[14]
            && self->m[15] == n->m[15];
}

- (id) copyWithZone:(NSZone*)zone
{
    return [[[self class] alloc] initWithMatrix:self];
}

//--------------------------------------------------------------------------------------------------------------------//
//-- Setting the Contents of Matrices --//
//--------------------------------------------------------------------------------------------------------------------//

- (void) setToIdentity
{
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
}

- (void) set:(double)m00 m01:(double)m01 m02:(double)m02 m03:(double)m03
         m10:(double)m10 m11:(double)m11 m12:(double)m12 m13:(double)m13
         m20:(double)m20 m21:(double)m21 m22:(double)m22 m23:(double)m23
         m30:(double)m30 m31:(double)m31 m32:(double)m32 m33:(double)m33
{
    self->m[0] = m00;
    self->m[1] = m01;
    self->m[2] = m02;
    self->m[3] = m03;
    self->m[4] = m10;
    self->m[5] = m11;
    self->m[6] = m12;
    self->m[7] = m13;
    self->m[8] = m20;
    self->m[9] = m21;
    self->m[10] = m22;
    self->m[11] = m23;
    self->m[12] = m30;
    self->m[13] = m31;
    self->m[14] = m32;
    self->m[15] = m33;
}

- (void) setToMatrix:(WWMatrix* __unsafe_unretained)matrix
{
    if (matrix == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Matrix is nil");
    }

    memcpy(self->m, matrix->m, (size_t) (16 * sizeof(double)));
}

//--------------------------------------------------------------------------------------------------------------------//
//-- Working With Transform Matrices --//
//--------------------------------------------------------------------------------------------------------------------//

- (void) setToTranslation:(double)x y:(double)y z:(double)z
{
    // Row 1
    self->m[0] = 1;
    self->m[1] = 0;
    self->m[2] = 0;
    self->m[3] = x;
    // Row 2
    self->m[4] = 0;
    self->m[5] = 1;
    self->m[6] = 0;
    self->m[7] = y;
    // Row 3
    self->m[8] = 0;
    self->m[9] = 0;
    self->m[10] = 1;
    self->m[11] = z;
    // Row 4
    self->m[12] = 0;
    self->m[13] = 0;
    self->m[14] = 0;
    self->m[15] = 1;
}

- (void) setTranslation:(double)x y:(double)y z:(double)z
{
    // Row 1
    self->m[3] = x;
    self->m[7] = y;
    self->m[11] = z;
}

- (void) multiplyByTranslation:(double)x y:(double)y z:(double)z
{
    [self multiply:1 m01:0 m02:0 m03:x
               m10:0 m11:1 m12:0 m13:y
               m20:0 m21:0 m22:1 m23:z
               m30:0 m31:0 m32:0 m33:1];
}

- (void) multiplyByRotationAxis:(double)x y:(double)y z:(double)z angleDegrees:(double)angle
{
    // Taken from Mathematics for 3D Game Programming and Computer Graphics, Second Edition, equation 3.22.

    double c = cos(RADIANS(angle));
    double s = sin(RADIANS(angle));

    [self multiply:c + (1 - c) * x * x     m01:(1 - c) * x * y - s * z m02:(1 - c) * x * z + s * y m03:0
               m10:(1 - c) * x * y + s * z m11:c + (1 - c) * y * y     m12:(1 - c) * y * z - s * x m13:0
               m20:(1 - c) * x * z - s * y m21:(1 - c) * y * z + s * x m22:c + (1 - c) * z * z     m23:0
               m30:0 m31:0 m32:0 m33:1];
}

- (void) multiplyByScale:(double)x y:(double)y z:(double)z
{
    [self multiply:x m01:0 m02:0 m03:0
               m10:0 m11:y m12:0 m13:0
               m20:0 m21:0 m22:z m23:0
               m30:0 m31:0 m32:0 m33:1];
}

- (void) setScale:(double)x y:(double)y z:(double)z
{
    // Row 1
    self->m[0] = x;
    self->m[5] = y;
    self->m[10] = z;
}

- (void) setToUnitYFlip
{
    self->m[0] = 1;
    self->m[1] = 0;
    self->m[2] = 0;
    self->m[3] = 0;
    self->m[4] = 0;
    self->m[5] = -1;
    self->m[6] = 0;
    self->m[7] = 1;
    self->m[8] = 0;
    self->m[9] = 0;
    self->m[10] = 1;
    self->m[11] = 0;
    self->m[12] = 0;
    self->m[13] = 0;
    self->m[14] = 0;
    self->m[15] = 1;
}

- (void) multiplyByLocalCoordinateTransform:(WWVec4* __unsafe_unretained)origin onGlobe:(WWGlobe* __unsafe_unretained)globe
{
    if (origin == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Origin is nil");
    }

    if (globe == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Globe is nil");
    }

    WWVec4* xaxis = [[WWVec4 alloc] initWithZeroVector];
    WWVec4* yaxis = [[WWVec4 alloc] initWithZeroVector];
    WWVec4* zaxis = [[WWVec4 alloc] initWithZeroVector];
    [WWMath localCoordinateAxesAtPoint:origin onGlobe:globe xaxis:xaxis yaxis:yaxis zaxis:zaxis];

    [self multiply:[xaxis x] m01:[yaxis x] m02:[zaxis x] m03:[origin x]
               m10:[xaxis y] m11:[yaxis y] m12:[zaxis y] m13:[origin y]
               m20:[xaxis z] m21:[yaxis z] m22:[zaxis z] m23:[origin z]
               m30:0 m31:0 m32:0 m33:1];
}

- (void) multiplyByTextureTransform:(WWTexture* __unsafe_unretained)texture
{
    if (texture == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Texture is nil")
    }

    // Compute the scale necessary to map the edge of the image data to the range [0,1]. When the texture contains
    // power-of-two image data the scale is 1 and has no effect. Otherwise, the scale is computed such that the portion
    // of the texture containing image data maps to the range [0,1].
    double sx = (double) [texture originalImageWidth] / (double) [texture imageWidth];
    double sy = (double) [texture originalImageHeight] / (double) [texture imageHeight];

    // Multiply this by a scaling matrix that maps the texture's image data to the range [0,1] and inverts the y axis.
    // We have precomputed the result here in order to avoid an unnecessary matrix multiplication.
    [self multiply:sx m01:0 m02:0 m03:0
               m10:0 m11:-sy m12:0 m13:sy
               m20:0 m21:0 m22:1 m23:0
               m30:0 m31:0 m32:0 m33:1];
}

- (WWVec4*) extractTranslation
{
    return [[WWVec4 alloc] initWithCoordinates:m[3] y:m[7] z:m[11]];
}

- (WWVec4*) extractRotation
{
    // Taken from Extracting Euler Angles from a Rotation Matrix by Mike Day, Insomniac Games.
    // http://www.insomniacgames.com/mike-day-extracting-euler-angles-from-a-rotation-matrix/

    double x = atan2(m[6], m[10]);
    double y = atan2(-m[2], sqrt(m[0] * m[0] + m[1] * m[1]));
    double cx = cos(x);
    double sx = sin(x);
    double z = atan2(sx * m[8] - cx * m[4], cx * m[5] - sx * m[9]);

    return [[WWVec4 alloc] initWithCoordinates:DEGREES(x) y:DEGREES(y) z:DEGREES(z)];
}

//--------------------------------------------------------------------------------------------------------------------//
//-- Working With Viewing and Perspective Matrices --//
//--------------------------------------------------------------------------------------------------------------------//

- (void) multiplyByFirstPersonModelview:(WWPosition* __unsafe_unretained)eyePosition
                         headingDegrees:(double)heading
                            tiltDegrees:(double)tilt
                            rollDegrees:(double)roll
                                onGlobe:(WWGlobe* __unsafe_unretained)globe
{
    if (eyePosition == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Eye position is nil");
    }

    if (globe == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Globe is nil");
    }

    // Roll. Rotate the eye point in a counter-clockwise direction about the z axis. Note that we invert the sines used
    // in the rotation matrix in order to produce the counter-clockwise rotation. We invert only the cosines since
    // sin(-a) = -sin(a) and cos(-a) = cos(a).
    double c = cos(RADIANS(roll));
    double s = sin(RADIANS(roll));
    [self multiply:c m01:s m02:0 m03:0
               m10:-s m11:c m12:0 m13:0
               m20:0 m21:0 m22:1 m23:0
               m30:0 m31:0 m32:0 m33:1];

    // Tilt. Rotate the eye point in a counter-clockwise direction about the x axis. Note that we invert the sines used
    // in the rotation matrix in order to produce the counter-clockwise rotation. We invert only the cosines since
    // sin(-a) = -sin(a) and cos(-a) = cos(a).
    c = cos(RADIANS(tilt));
    s = sin(RADIANS(tilt));
    [self multiply:1 m01:0 m02:0 m03:0
               m10:0 m11:c m12:s m13:0
               m20:0 m21:-s m22:c m23:0
               m30:0 m31:0 m32:0 m33:1];

    // Heading. Rotate the eye point in a clockwise direction about the z axis again. This has a different effect than
    // roll when tilt is non-zero because the viewer is no longer looking down the z axis.
    c = cos(RADIANS(heading));
    s = sin(RADIANS(heading));
    [self multiply:c m01:-s m02:0 m03:0
               m10:s m11:c m12:0 m13:0
               m20:0 m21:0 m22:1 m23:0
               m30:0 m31:0 m32:0 m33:1];

    // Store the eye position's latitude, longitude and altitude to reduce Objective-C method call overhead.
    double lat = [eyePosition latitude];
    double lon = [eyePosition longitude];
    double alt = [eyePosition altitude];

    // Compute the eye point in model coordinates. This point is mapped to the origin in the look at transform below.
    WWVec4* eyePoint = [[WWVec4 alloc] initWithZeroVector];
    [globe computePointFromPosition:lat longitude:lon altitude:alt outputPoint:eyePoint];
    double ex = [eyePoint x];
    double ey = [eyePoint y];
    double ez = [eyePoint z];

    // Transform the origin to the local coordinate system at the eye point.
    WWVec4* xaxis = [[WWVec4 alloc] initWithZeroVector];
    WWVec4* yaxis = [[WWVec4 alloc] initWithZeroVector];
    WWVec4* zaxis = [[WWVec4 alloc] initWithZeroVector];
    [WWMath localCoordinateAxesAtPoint:eyePoint onGlobe:globe xaxis:xaxis yaxis:yaxis zaxis:zaxis];
    double xx = [xaxis x];
    double xy = [xaxis y];
    double xz = [xaxis z];
    double yx = [yaxis x];
    double yy = [yaxis y];
    double yz = [yaxis z];
    double zx = [zaxis x];
    double zy = [zaxis y];
    double zz = [zaxis z];

    [self multiply:xx m01:xy m02:xz m03:-xx * ex - xy * ey - xz * ez
               m10:yx m11:yy m12:yz m13:-yx * ex - yy * ey - yz * ez
               m20:zx m21:zy m22:zz m23:-zx * ex - zy * ey - zz * ez
               m30:0 m31:0 m32:0 m33:1];
}

- (void) multiplyByLookAtModelview:(WWPosition* __unsafe_unretained)lookAtPosition
                             range:(double)range
                    headingDegrees:(double)heading
                       tiltDegrees:(double)tilt
                       rollDegrees:(double)roll
                           onGlobe:(WWGlobe* __unsafe_unretained)globe
{
    if (lookAtPosition == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Look at position is nil");
    }

    if (range < 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Range is invalid");
    }

    if (globe == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Globe is nil");
    }

    // Translate the eye point along the positive z axis while keeping the look at point in the center of the viewport.
    [self multiplyByTranslation:0 y:0 z:-range];

    // Transform the origin to the local coordinate system at the look at position, and rotate the viewer by the
    // specified heading, tilt and roll.
    [self multiplyByFirstPersonModelview:lookAtPosition
                          headingDegrees:heading
                             tiltDegrees:tilt
                             rollDegrees:roll
                                 onGlobe:globe];
}

- (void) setToPerspectiveProjection:(CGRect)viewport nearDistance:(double)near farDistance:(double)far
{
    if (CGRectGetWidth(viewport) == 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Viewport width is zero")
    }

    if (CGRectGetHeight(viewport) == 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Viewport height is zero")
    }

    if (near == far)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Near and far are equal")
    }

    if (near <= 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Near is not positive")
    }

    if (far <= 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Far is not positive")
    }

    // Compute the dimensions of the near clip rectangle corresponding to the specified viewport rectangle.
    CGRect nearRect = [WWMath perspectiveFrustumRect:viewport atDistance:near];
    double left = CGRectGetMinX(nearRect);
    double right = CGRectGetMaxX(nearRect);
    double bottom = CGRectGetMinY(nearRect);
    double top = CGRectGetMaxY(nearRect);

    // Taken from Mathematics for 3D Game Programming and Computer Graphics, Second Edition, equation 4.52.

    // Row 1
    self->m[0] = 2 * near / (right - left);
    self->m[1] = 0;
    self->m[2] = (right + left) / (right - left);
    self->m[3] = 0;
    // Row 2
    self->m[4] = 0;
    self->m[5] = 2 * near / (top - bottom);
    self->m[6] = (top + bottom) / (top - bottom);
    self->m[7] = 0;
    // Row 3
    self->m[8] = 0;
    self->m[9] = 0;
    self->m[10] = -(far + near) / (far - near);
    self->m[11] = -2 * near * far / (far - near);
    // Row 4
    self->m[12] = 0;
    self->m[13] = 0;
    self->m[14] = -1;
    self->m[15] = 0;
}

- (void) setToScreenProjection:(CGRect)viewport
{
    double left = CGRectGetMinX(viewport);
    double right = CGRectGetMaxX(viewport);
    double bottom = CGRectGetMinY(viewport);
    double top = CGRectGetMaxY(viewport);

    if (left == right)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Viewport width is zero")
    }

    if (bottom == top)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Viewport height is zero")
    }

    // Taken from Mathematics for 3D Game Programming and Computer Graphics, Second Edition, equation 4.57.
    //
    // The third row of this projection matrix is configured so that points with z coordinates representing depth values
    // ranging from 0 to 1 are not modified after transformation into window coordinates. This projection matrix maps z
    // values in the range [0, 1] to the range [-1, 1] by applying the following function to incoming z coordinates:
    //
    // zp = z0 * 2 - 1
    //
    // Where 'z0' is the point's z coordinate and 'zp' is the projected z coordinate. The GPU then maps the projected z
    // coordinate into window coordinates in the range [0, 1] by applying the following function:
    //
    // zw = zp * 0.5 + 0.5
    //
    // The result is that a point's z coordinate is effectively passed to the GPU without modification.

    // Row 1
    self->m[0] = 2 / (right - left);
    self->m[1] = 0;
    self->m[2] = 0;
    self->m[3] = - (right + left) / (right - left);
    // Row 2
    self->m[4] = 0;
    self->m[5] = 2 / (top - bottom);
    self->m[6] = 0;
    self->m[7] = - (top + bottom) / (top  - bottom);
    // Row 3
    self->m[8] = 0;
    self->m[9] = 0;
    self->m[10] = 2;
    self->m[11] = - 1;
    // Row 4
    self->m[12] = 0;
    self->m[13] = 0;
    self->m[14] = 0;
    self->m[15] = 1;
}

- (WWVec4*) extractEyePoint
{
    // The eye point of a modelview matrix is computed by transforming the origin (0, 0, 0, 1) by the matrix's inverse.
    // This is equivalent to transforming the inverse of this matrix's translation components in the rightmost column by
    // the transpose of its upper 3x3 components.
    double x = -(m[0] * m[3]) - (m[4] * m[7]) - (m[8] * m[11]);
    double y = -(m[1] * m[3]) - (m[5] * m[7]) - (m[9] * m[11]);
    double z = -(m[2] * m[3]) - (m[6] * m[7]) - (m[10] * m[11]);

    return [[WWVec4 alloc] initWithCoordinates:x y:y z:z];
}

- (WWVec4*) extractForwardVector
{
    // The forward vector of a modelview matrix is computed by transforming the negative Z axis (0, 0, -1, 0) by the
    // matrix's inverse. We have pre-computed the result inline here to simplify this computation.
    return [[WWVec4 alloc] initWithCoordinates:-m[8] y:-m[9] z:-m[10]];
}

- (NSDictionary*) extractViewingParameters:(WWVec4* __unsafe_unretained)origin forRollDegrees:(double)roll onGlobe:(WWGlobe* __unsafe_unretained)globe
{
    if (origin == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Origin is nil");
    }

    if (globe == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Globe is nil")
    }

    WWPosition* originPos = [[WWPosition alloc] initWithZeroPosition];
    [globe computePositionFromPoint:[origin x] y:[origin y] z:[origin z] outputPosition:originPos];

    // Transform the modelview matrix to a local coordinate system at the origin. This eliminates the geographic
    // transform contained in the modelview matrix while maintaining rotation and translation relative to the origin.
    WWMatrix* modelviewLocal = [[WWMatrix alloc] initWithMatrix:self];
    [modelviewLocal multiplyByLocalCoordinateTransform:origin onGlobe:globe];

    // Extract the viewing parameters from the transform in local coordinates.
    // TODO: Document how these parameters are extracted.

    double* ml = modelviewLocal->m;
    double range = -ml[11];

    double ct = ml[10];
    double st = sqrt(ml[2] * ml[2] + ml[6] * ml[6]);
    double tilt = atan2(st, ct);

    double cr = cos(RADIANS(roll));
    double sr = sin(RADIANS(roll));
    double ch = cr * ml[0] - sr * ml[4];
    double sh = sr * ml[5] - cr * ml[1];
    double heading = atan2(sh, ch);

    return [[NSDictionary alloc] initWithObjectsAndKeys:
            originPos, WW_ORIGIN,
            @(range), WW_RANGE,
            @(DEGREES(heading)), WW_HEADING,
            @(DEGREES(tilt)), WW_TILT,
            @(roll), WW_ROLL,
            nil];
}

- (WWFrustum*) extractFrustum
{
    double* m1 = self->m;
    double* m2 = &self->m[4];
    double* m3 = &self->m[8];
    double* m4 = &self->m[12];

    // Left Plane = row 4 + row 1:
    double x = m4[0] + m1[0];
    double y = m4[1] + m1[1];
    double z = m4[2] + m1[2];
    double w = m4[3] + m1[3];
    double d = sqrt(x * x + y * y + z * z); // for normalizing the coordinates
    WWPlane* left = [[WWPlane alloc] initWithCoordinates:x / d y:y / d z:z / d distance:w / d];

    // Right Plane = row 4 - row 1:
    x = m4[0] - m1[0];
    y = m4[1] - m1[1];
    z = m4[2] - m1[2];
    w = m4[3] - m1[3];
    d = sqrt(x * x + y * y + z * z); // for normalizing the coordinates
    WWPlane* right = [[WWPlane alloc] initWithCoordinates:x / d y:y / d z:z / d distance:w / d];

    // Bottom Plane = row 4 + row 2:
    x = m4[0] + m2[0];
    y = m4[1] + m2[1];
    z = m4[2] + m2[2];
    w = m4[3] + m2[3];
    d = sqrt(x * x + y * y + z * z); // for normalizing the coordinates
    WWPlane* bottom = [[WWPlane alloc] initWithCoordinates:x / d y:y / d z:z / d distance:w / d];

    // Top Plane = row 4 - row 2:
    x = m4[0] - m2[0];
    y = m4[1] - m2[1];
    z = m4[2] - m2[2];
    w = m4[3] - m2[3];
    d = sqrt(x * x + y * y + z * z); // for normalizing the coordinates
    WWPlane* top = [[WWPlane alloc] initWithCoordinates:x / d y:y / d z:z / d distance:w / d];

    // Near Plane = row 4 + row 3:
    x = m4[0] + m3[0];
    y = m4[1] + m3[1];
    z = m4[2] + m3[2];
    w = m4[3] + m3[3];
    d = sqrt(x * x + y * y + z * z); // for normalizing the coordinates
    WWPlane* near = [[WWPlane alloc] initWithCoordinates:x / d y:y / d z:z / d distance:w / d];

    // Far Plane = row 4 - row 3:
    x = m4[0] - m3[0];
    y = m4[1] - m3[1];
    z = m4[2] - m3[2];
    w = m4[3] - m3[3];
    d = sqrt(x * x + y * y + z * z); // for normalizing the coordinates
    WWPlane* far = [[WWPlane alloc] initWithCoordinates:x / d y:y / d z:z / d distance:w / d];

    return [[WWFrustum alloc] initWithPlanes:left right:right bottom:bottom top:top near:near far:far];
}

//--------------------------------------------------------------------------------------------------------------------//
//-- Matrix Operations --//
//--------------------------------------------------------------------------------------------------------------------//

- (void) multiplyMatrix:(WWMatrix* __unsafe_unretained)matrix
{
    if (matrix == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Matrix is nil");
    }

    double* ma = self->m;
    double* mb = matrix->m;

    // Row 1
    double ma0 = ma[0];
    double ma1 = ma[1];
    double ma2 = ma[2];
    double ma3 = ma[3];
    ma[0] = (ma0 * mb[0]) + (ma1 * mb[4]) + (ma2 * mb[8]) + (ma3 * mb[12]);
    ma[1] = (ma0 * mb[1]) + (ma1 * mb[5]) + (ma2 * mb[9]) + (ma3 * mb[13]);
    ma[2] = (ma0 * mb[2]) + (ma1 * mb[6]) + (ma2 * mb[10]) + (ma3 * mb[14]);
    ma[3] = (ma0 * mb[3]) + (ma1 * mb[7]) + (ma2 * mb[11]) + (ma3 * mb[15]);

    // Row 2
    ma0 = ma[4];
    ma1 = ma[5];
    ma2 = ma[6];
    ma3 = ma[7];
    ma[4] = (ma0 * mb[0]) + (ma1 * mb[4]) + (ma2 * mb[8]) + (ma3 * mb[12]);
    ma[5] = (ma0 * mb[1]) + (ma1 * mb[5]) + (ma2 * mb[9]) + (ma3 * mb[13]);
    ma[6] = (ma0 * mb[2]) + (ma1 * mb[6]) + (ma2 * mb[10]) + (ma3 * mb[14]);
    ma[7] = (ma0 * mb[3]) + (ma1 * mb[7]) + (ma2 * mb[11]) + (ma3 * mb[15]);

    // Row 3
    ma0 = ma[8];
    ma1 = ma[9];
    ma2 = ma[10];
    ma3 = ma[11];
    ma[8] = (ma0 * mb[0]) + (ma1 * mb[4]) + (ma2 * mb[8]) + (ma3 * mb[12]);
    ma[9] = (ma0 * mb[1]) + (ma1 * mb[5]) + (ma2 * mb[9]) + (ma3 * mb[13]);
    ma[10] = (ma0 * mb[2]) + (ma1 * mb[6]) + (ma2 * mb[10]) + (ma3 * mb[14]);
    ma[11] = (ma0 * mb[3]) + (ma1 * mb[7]) + (ma2 * mb[11]) + (ma3 * mb[15]);

    // Row 4
    ma0 = ma[12];
    ma1 = ma[13];
    ma2 = ma[14];
    ma3 = ma[15];
    ma[12] = (ma0 * mb[0]) + (ma1 * mb[4]) + (ma2 * mb[8]) + (ma3 * mb[12]);
    ma[13] = (ma0 * mb[1]) + (ma1 * mb[5]) + (ma2 * mb[9]) + (ma3 * mb[13]);
    ma[14] = (ma0 * mb[2]) + (ma1 * mb[6]) + (ma2 * mb[10]) + (ma3 * mb[14]);
    ma[15] = (ma0 * mb[3]) + (ma1 * mb[7]) + (ma2 * mb[11]) + (ma3 * mb[15]);
}

- (void) multiply:(double)m00 m01:(double)m01 m02:(double)m02 m03:(double)m03
              m10:(double)m10 m11:(double)m11 m12:(double)m12 m13:(double)m13
              m20:(double)m20 m21:(double)m21 m22:(double)m22 m23:(double)m23
              m30:(double)m30 m31:(double)m31 m32:(double)m32 m33:(double)m33
{
    double* ma = self->m;

    // Row 1
    double ma0 = ma[0];
    double ma1 = ma[1];
    double ma2 = ma[2];
    double ma3 = ma[3];
    ma[0] = (ma0 * m00) + (ma1 * m10) + (ma2 * m20) + (ma3 * m30);
    ma[1] = (ma0 * m01) + (ma1 * m11) + (ma2 * m21) + (ma3 * m31);
    ma[2] = (ma0 * m02) + (ma1 * m12) + (ma2 * m22) + (ma3 * m32);
    ma[3] = (ma0 * m03) + (ma1 * m13) + (ma2 * m23) + (ma3 * m33);

    // Row 2
    ma0 = ma[4];
    ma1 = ma[5];
    ma2 = ma[6];
    ma3 = ma[7];
    ma[4] = (ma0 * m00) + (ma1 * m10) + (ma2 * m20) + (ma3 * m30);
    ma[5] = (ma0 * m01) + (ma1 * m11) + (ma2 * m21) + (ma3 * m31);
    ma[6] = (ma0 * m02) + (ma1 * m12) + (ma2 * m22) + (ma3 * m32);
    ma[7] = (ma0 * m03) + (ma1 * m13) + (ma2 * m23) + (ma3 * m33);

    // Row 3
    ma0 = ma[8];
    ma1 = ma[9];
    ma2 = ma[10];
    ma3 = ma[11];
    ma[8] = (ma0 * m00) + (ma1 * m10) + (ma2 * m20) + (ma3 * m30);
    ma[9] = (ma0 * m01) + (ma1 * m11) + (ma2 * m21) + (ma3 * m31);
    ma[10] = (ma0 * m02) + (ma1 * m12) + (ma2 * m22) + (ma3 * m32);
    ma[11] = (ma0 * m03) + (ma1 * m13) + (ma2 * m23) + (ma3 * m33);

    // Row 4
    ma0 = ma[12];
    ma1 = ma[13];
    ma2 = ma[14];
    ma3 = ma[15];
    ma[12] = (ma0 * m00) + (ma1 * m10) + (ma2 * m20) + (ma3 * m30);
    ma[13] = (ma0 * m01) + (ma1 * m11) + (ma2 * m21) + (ma3 * m31);
    ma[14] = (ma0 * m02) + (ma1 * m12) + (ma2 * m22) + (ma3 * m32);
    ma[15] = (ma0 * m03) + (ma1 * m13) + (ma2 * m23) + (ma3 * m33);
}

- (void) invert:(WWMatrix* __unsafe_unretained)matrix
{
    if (matrix == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Matrix is nil");
    }

    double* ma = self->m;
    double mb[16];
    memcpy(mb, matrix->m, (size_t) (16 * sizeof(double)));

    int indx[4];
    double col[4];

    // Compute the matrix's determinant. The matrix is singular if its determinant is zero or very close to zero.
    double d = [self ludcmp:mb indx:indx] * mb[0] * mb[5] * mb[10] * mb[15];
    if (fabs(d) < NEAR_ZERO_THRESHOLD)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Matrix is singular");
    }

    for (int j = 0; j < 4; j++)
    {
        for (int i = 0; i < 4; i++)
        {
            col[i] = 0;
        }

        col[j] = 1;
        [self lubksb:mb indx:indx b:col];

        for (int i = 0; i < 4; i++)
        {
            ma[INDEX(i, j)] = col[i];
        }
    }
}

- (void) invertTransformMatrix:(WWMatrix* __unsafe_unretained)matrix
{
    if (matrix == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Matrix is nil");
    }

    double* ma = self->m;
    double* mb = matrix->m;

    // Compute the transpose of the specified matrix's upper 3x3 portion, and store the result in this matrix's upper
    // 3x3 portion.
    ma[0] = mb[0];
    ma[1] = mb[4];
    ma[2] = mb[8];
    ma[4] = mb[1];
    ma[5] = mb[5];
    ma[6] = mb[9];
    ma[8] = mb[2];
    ma[9] = mb[6];
    ma[10] = mb[10];

    // Multiply the translation vector of the specified matrix by the transpose of its upper 3x3 portion, and store the
    // negative of this vector in this matrix's translation component.
    ma[3] = -(mb[0] * mb[3]) - (mb[4] * mb[7]) - (mb[8] * mb[11]);
    ma[7] = -(mb[1] * mb[3]) - (mb[5] * mb[7]) - (mb[9] * mb[11]);
    ma[11] = -(mb[2] * mb[3]) - (mb[6] * mb[7]) - (mb[10] * mb[11]);

    // Copy the specified matrix's bottom row into this matrix's bottom row. Since we're assuming the matrix represents
    // an orthonormal transform matrix, the bottom row should always be (0, 0, 0, 1).
    ma[12] = mb[12];
    ma[13] = mb[13];
    ma[14] = mb[14];
    ma[15] = mb[15];
}

+ (void) eigensystemFromSymmetricMatrix:(WWMatrix* __unsafe_unretained)matrix
                                   vec1:(WWVec4* __unsafe_unretained)vec1
                                   vec2:(WWVec4* __unsafe_unretained)vec2
                                   vec3:(WWVec4* __unsafe_unretained)vec3
{
    if (matrix == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Matrix is nil")
    }

    if (matrix->m[1] != matrix->m[4] || matrix->m[2] != matrix->m[8] || matrix->m[6] != matrix->m[9])
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Matrix is not symmetric")
    }

    if (vec1 == nil || vec2 == nil || vec3 == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Result vector is nil")
    }

    // Taken from Mathematics for 3D Game Programming and Computer Graphics, Second Edition, listing 14.6.

    const double epsilon = 1.0e-10;

    // Since the matrix is symmetric m12=m21, m13=m31 and m23=m32, therefore we can ignore the values m21,
    // m32 and m32.
    double m11 = matrix->m[0];
    double m12 = matrix->m[1];
    double m13 = matrix->m[2];
    double m22 = matrix->m[5];
    double m23 = matrix->m[6];
    double m33 = matrix->m[10];

    double r[3][3];
    r[0][0] = r[1][1] = r[2][2] = 1;
    r[0][1] = r[0][2] = r[1][0] = r[1][2] = r[2][0] = r[2][1] = 0;

    int max_sweeps = 32;
    for (int a = 0; a < max_sweeps; a++)
    {
        // Exit if off-diagonal entries small enough
        if (fabs(m12) < epsilon && fabs(m13) < epsilon && fabs(m23) < epsilon)
            break;

        // Annihilate (1,2) entry.
        if (m12 != 0)
        {
            double u = (m22 - m11) * 0.5 / m12;
            double u2 = u * u;
            double u2p1 = u2 + 1;
            double t = (u2p1 != u2) ? ((u < 0) ? -1 : 1) * (sqrt(u2p1) - fabs(u)) : 0.5 / u;
            double c = 1 / sqrt(t * t + 1);
            double s = c * t;

            m11 -= t * m12;
            m22 += t * m12;
            m12 = 0;

            double temp = c * m13 - s * m23;
            m23 = s * m13 + c * m23;
            m13 = temp;

            for (int i = 0; i < 3; i++)
            {
                temp = c * r[i][0] - s * r[i][1];
                r[i][1] = s * r[i][0] + c * r[i][1];
                r[i][0] = temp;
            }
        }

        // Annihilate (1,3) entry.
        if (m13 != 0)
        {
            double u = (m33 - m11) * 0.5 / m13;
            double u2 = u * u;
            double u2p1 = u2 + 1;
            double t = (u2p1 != u2) ? ((u < 0) ? -1 : 1) * (sqrt(u2p1) - fabs(u)) : 0.5 / u;
            double c = 1 / sqrt(t * t + 1);
            double s = c * t;

            m11 -= t * m13;
            m33 += t * m13;
            m13 = 0;

            double temp = c * m12 - s * m23;
            m23 = s * m12 + c * m23;
            m12 = temp;

            for (int i = 0; i < 3; i++)
            {
                temp = c * r[i][0] - s * r[i][2];
                r[i][2] = s * r[i][0] + c * r[i][2];
                r[i][0] = temp;
            }
        }

        // Annihilate (2,3) entry.
        if (m23 != 0)
        {
            double u = (m33 - m22) * 0.5 / m23;
            double u2 = u * u;
            double u2p1 = u2 + 1;
            double t = (u2p1 != u2) ? ((u < 0) ? -1 : 1) * (sqrt(u2p1) - fabs(u)) : 0.5 / u;
            double c = 1 / sqrt(t * t + 1);
            double s = c * t;

            m22 -= t * m23;
            m33 += t * m23;
            m23 = 0;

            double temp = c * m12 - s * m13;
            m13 = s * m12 + c * m13;
            m12 = temp;

            for (int i = 0; i < 3; i++)
            {
                temp = c * r[i][1] - s * r[i][2];
                r[i][2] = s * r[i][1] + c * r[i][2];
                r[i][1] = temp;
            }
        }
    }

    int i1 = 0;
    int i2 = 1;
    int i3 = 2;

    if (m11 < m22) {WWMatrixSwapEigenvalues(&m11, &m22, &i1, &i2);}
    if (m22 < m33) {WWMatrixSwapEigenvalues(&m22, &m33, &i2, &i3);}
    if (m11 < m22) {WWMatrixSwapEigenvalues(&m11, &m22, &i1, &i2);}

    [vec1 set:r[0][i1] y:r[1][i1] z:r[2][i1]];
    [vec2 set:r[0][i2] y:r[1][i2] z:r[2][i2]];
    [vec3 set:r[0][i3] y:r[1][i3] z:r[2][i3]];

    [vec1 normalize3];
    [vec2 normalize3];
    [vec3 normalize3];

    [vec1 multiplyByScalar3:m11];
    [vec2 multiplyByScalar3:m22];
    [vec3 multiplyByScalar3:m33];
}

- (void) offsetProjectionDepth:(double)depthOffset
{
    // Taken from Mathematics for 3D Game Programming and Computer Graphics, Second Edition, section 9.1.
    self->m[10] *= 1 + depthOffset;
}

//--------------------------------------------------------------------------------------------------------------------//
//-- Methods for Internal Use --//
//--------------------------------------------------------------------------------------------------------------------//

// Method "lubksb" derived from "Numerical Recipes in C", Press et al., 1988
- (void) lubksb:(const double*)A indx:(const int*)indx b:(double*)b
{
    int ii = -1;
    for (int i = 0; i < 4; i++)
    {
        int ip = indx[i];
        double sum = b[ip];
        b[ip] = b[i];

        if (ii != -1)
        {
            for (int j = ii; j <= i - 1; j++)
            {
                sum -= A[INDEX(i, j)] * b[j];
            }
        }
        else if (sum != 0.0)
        {
            ii = i;
        }

        b[i] = sum;
    }

    for (int i = 3; i >= 0; i--)
    {
        double sum = b[i];
        for (int j = i + 1; j < 4; j++)
        {
            sum -= A[INDEX(i, j)] * b[j];
        }

        b[i] = sum / A[INDEX(i, i)];
    }
}

// Method "ludcmp" derived from "Numerical Recipes in C", Press et al., 1988
- (double) ludcmp:(double*)A indx:(int*)indx
{
    double vv[4];
    double d = 1.0;
    double temp;
    for (int i = 0; i < 4; i++)
    {
        double big = 0.0;
        for (int j = 0; j < 4; j++)
        {
            if ((temp = fabs(A[INDEX(i, j)])) > big)
                big = temp;
        }

        if (big == 0.0)
            return 0.0; // Matrix is singular if the entire row contains zero.
        else
            vv[i] = 1.0 / big;
    }

    double sum;
    for (int j = 0; j < 4; j++)
    {
        for (int i = 0; i < j; i++)
        {
            sum = A[INDEX(i, j)];
            for (int k = 0; k < i; k++)
            {
                sum -= A[INDEX(i, k)] * A[INDEX(k, j)];
            }

            A[INDEX(i, j)] = sum;
        }

        double big = 0.0;
        double dum;
        int imax = -1;
        for (int i = j; i < 4; i++)
        {
            sum = A[INDEX(i, j)];
            for (int k = 0; k < j; k++)
            {
                sum -= A[INDEX(i, k)] * A[INDEX(k, j)];
            }

            A[INDEX(i, j)] = sum;

            if ((dum = vv[i] * fabs(sum)) >= big)
            {
                big = dum;
                imax = i;
            }
        }

        if (j != imax)
        {
            for (int k = 0; k < 4; k++)
            {
                dum = A[INDEX(imax, k)];
                A[INDEX(imax, k)] = A[INDEX(j, k)];
                A[INDEX(j, k)] = dum;
            }

            d = -d;
            vv[imax] = vv[j];
        }

        indx[j] = imax;
        if (A[INDEX(j, j)] == 0.0)
            A[INDEX(j, j)] = TINY_VALUE;

        if (j != 3)
        {
            dum = 1.0 / A[INDEX(j, j)];
            for (int i = j + 1; i < 4; i++)
            {
                A[INDEX(i, j)] *= dum;
            }
        }
    }

    return d;
}

@end