/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "WorldWind/Geometry/WWMatrix.h"
#import "WorldWind/Geometry/WWAngle.h"
#import "WorldWind/Geometry/WWFrustum.h"
#import "WorldWind/Geometry/WWPlane.h"
#import "WorldWind/Geometry/WWVec4.h"
#import "WorldWind/Terrain/WWGlobe.h"
#import "WorldWind/Util/WWMath.h"
#import "WorldWind/WWLog.h"

#define INDEX(i, j) (i) * 4 + (j)
#define NEAR_ZERO_THRESHOLD 1.0e-8
#define TINY_VALUE 1.0e-20

@implementation WWMatrix

- (id) copyWithZone:(NSZone*)zone
{
    return [[[self class] alloc] initWithMatrix:self];
}

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
    if (matrix == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Matrix is nil");
    }


    self = [super init];

    memcpy(self->m, matrix->m, (size_t) (16 * sizeof(double)));

    return self;
}

- (WWMatrix*) initWithInverse:(WWMatrix*)matrix
{
    if (matrix == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Matrix is nil");
    }

    self = [super init];

    return [self invert:matrix];
}

- (WWMatrix*) initWithTransformInverse:(WWMatrix*)matrix
{
    if (matrix == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Matrix is nil");
    }

    self = [super init];

    return [self invertTransformMatrix:matrix];
}

- (WWMatrix*) initWithTranspose:(WWMatrix*)matrix
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

- (WWMatrix*) initWithMultiply:(WWMatrix*)matrixA matrixB:(WWMatrix*)matrixB
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

- (WWMatrix*) initWithCovarianceOfPoints:(NSArray*)points
{
    if (points == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Points is nil");
    }
    
    self = [super init];

    WWVec4* mean = [[WWVec4 alloc] initWithAverageOfVectors:points];

    int count = 0;
    double c11 = 0;
    double c22 = 0;
    double c33 = 0;
    double c12 = 0;
    double c13 = 0;
    double c23 = 0;

    for (NSUInteger i = 0; i < [points count]; i++)
    {
        WWVec4* vec = [points objectAtIndex:i];

        if (vec == nil)
            continue;

        ++count;
        c11 += ([vec x] - [mean x]) * ([vec x] - [mean x]);
        c22 += ([vec y] - [mean y]) * ([vec y] - [mean y]);
        c33 += ([vec z] - [mean z]) * ([vec z] - [mean z]);
        c12 += ([vec x] - [mean x]) * ([vec y] - [mean y]); // c12 = c21
        c13 += ([vec x] - [mean x]) * ([vec z] - [mean z]); // c13 = c31
        c23 += ([vec y] - [mean y]) * ([vec z] - [mean z]); // c23 = c32
    }

    if (count == 0)
        return nil;

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

- (WWMatrix*) set:(double)m00 m01:(double)m01 m02:(double)m02 m03:(double)m03
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

    return self;
}

- (WWMatrix*) setToIdentity
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

    return self;
}

- (WWMatrix*) setToTranslation:(double)x y:(double)y z:(double)z
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

    return self;
}

- (WWMatrix*) setTranslation:(double)x y:(double)y z:(double)z
{
    // Row 1
    self->m[3] = x;
    self->m[7] = y;
    self->m[11] = z;

    return self;
}

- (WWMatrix*) setScale:(double)x y:(double)y z:(double)z
{
    // Row 1
    self->m[0] = x;
    self->m[5] = y;
    self->m[10] = z;

    return self;
}

- (WWMatrix*) setToUnitYFlip
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

    return self;
}

- (WWMatrix*) setLookAt:(WWGlobe*)globe
         centerLatitude:(double)latitude
        centerLongitude:(double)longitude
         centerAltitude:(double)altitude
          rangeInMeters:(double)range
                heading:(double)heading
                   tilt:(double)tilt
{
    if (globe == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Globe is nil");
    }

    if (range < 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Range is invalid");
    }

    // Range transform. Moves the eye point along the positive z axis while keeping the center point in the center
    // of the viewport.
    [self setToTranslation:0 y:0 z:-range];

    // Tilt transform. Rotates the eye point in a counter-clockwise direction around the positive x axis. Note that we
    // invert the angle in order to produce the counter-clockwise rotation. We have pre-computed the resultant matrix
    // and stored the result inline here to avoid unnecessary matrix allocations.
    double c = cos(RADIANS(tilt)); // No need to invert cos(roll) to change the direction of rotation. cos(-a) = cos(a)
    double s = -sin(RADIANS(tilt)); // Invert sin(roll) in order to change the direction of rotation. sin(-a) = -sin(a)
    [self multiply:1 m01:0 m02:0 m03:0
               m10:0 m11:c m12:-s m13:0
               m20:0 m21:s m22:c m23:0
               m30:0 m31:0 m32:0 m33:1];

    // Heading transform. Rotates the eye point in a clockwise direction around the positive z axis. This has a
    // different effect than roll when tilt is non-zero because the view is no longer looking down the positive z axis.
    // We have pre-computed the resultant matrix and stored the result inline here to avoid unnecessary matrix
    // allocations.
    c = cos(RADIANS(heading));
    s = sin(RADIANS(heading));
    [self multiply:c m01:-s m02:0 m03:0
               m10:s m11:c m12:0 m13:0
               m20:0 m21:0 m22:1 m23:0
               m30:0 m31:0 m32:0 m33:1];

    // Compute the center point in model coordinates. This point is mapped to the eye point in the center position
    // transform below. By using the terrain and an altitude mode, we provide the ability for this transform to map the
    // eye point to either a point relative to the geoid or a point relative to the surface.
    WWVec4* point = [[WWVec4 alloc] init];
    [globe computePointFromPosition:latitude longitude:longitude altitude:altitude outputPoint:point];
    double cx = point.x;
    double cy = point.y;
    double cz = point.z;

    // Compute the surface normal in model coordinates. This normal is used as the inverse of the forward vector in the
    // center position transform below.
    [globe computeNormal:latitude longitude:longitude outputPoint:point];
    double nx = point.x;
    double ny = point.y;
    double nz = point.z;

    // Compute the north pointing tangent vector in model coordinates. This vector is used as the up vector in the
    // center position transform below.
    [globe computeNorthTangent:latitude longitude:longitude outputPoint:point];
    double ux = point.x;
    double uy = point.y;
    double uz = point.z;

    // Compute the side vector from the specified surface normal, and north pointing tangent. The side vector is
    // orthogonal to the surface normal and north pointing tangent.
    double sx = (uy * nz) - (uz * ny);
    double sy = (uz * nx) - (ux * nz);
    double sz = (ux * ny) - (uy * nx);

    double len = [[point set:sx y:sy z:sz] length3];
    if (len != 0)
    {
        sx /= len;
        sy /= len;
        sz /= len;
    }

    // Center position transform. Maps the eye point to the center position, the positive z axis to the surface
    // normal, and the positive y axis is mapped to the north pointing tangent. We have pre-computed the resultant
    // matrix and stored the result inline here to avoid unnecessary matrix allocations.
    [self multiply:sx m01:sy m02:sz m03:-sx * cx - sy * cy - sz * cz
               m10:ux m11:uy m12:uz m13:-ux * cx - uy * cy - uz * cz
               m20:nx m21:ny m22:nz m23:-nx * cx - ny * cy - nz * cz
               m30:0 m31:0 m32:0 m33:1];

    return self;
}

- (WWMatrix*) setOrthoFromLeft:(double)left
                         right:(double)right
                        bottom:(double)bottom
                           top:(double)top
                  nearDistance:(double)near
                   farDistance:(double)far
{
    if (left == right)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Left and right are equal");
    }

    if (bottom == top)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Bottom and top are equal");
    }

    if (near == far)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Near and far are equal");
    }

    // Taken from "Mathematics for 3D Game Programming and Computer Graphics, Second Edition", Equation (4.57).

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
    self->m[10] = -2 / (far - near);
    self->m[11] = - (far + near) / (far - near);
    // Row 4
    self->m[12] = 0;
    self->m[13] = 0;
    self->m[14] = 0;
    self->m[15] = 1;

    return self;
}

- (WWMatrix*) setOrthoFromWidth:(double)width
                         height:(double)height
{
    if (width <= 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Width is not positive");
    }

    if (height <= 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Height is not positive");
    }

    // Create an orthographic projection that maps X and Y coordinates in the range [0, viewportWidth] and
    // [0, viewportHeight] to [-1, 1], and maps Z coordinates in the range [0, 1] to [-1, 1]. This enables primitives
    // to be drawn in screen coordinates, while preserving Z values associated with a different projection.

    [self setOrthoFromLeft:0
                     right:width
                    bottom:0
                       top:height
              nearDistance:0
               farDistance:-1];

    return self;
}

- (WWMatrix*) setPerspective:(double)left
                       right:(double)right
                      bottom:(double)bottom
                         top:(double)top
                nearDistance:(double)near
                 farDistance:(double)far
{
    if (left == right)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Left and right are equal");
    }

    if (bottom == top)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Bottom and top are equal");
    }

    if (near == far)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Near and far are equal");
    }

    if (near <= 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Near is not positive");
    }

    if (far <= 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Far is not positive");
    }

    // Taken from "Mathematics for 3D Game Programming and Computer Graphics, Second Edition", Equation (4.52)..

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

    return self;
}

- (WWMatrix*) setPerspectiveFieldOfView:(double)horizontalFOV
                          viewportWidth:(double)width
                         viewportHeight:(double)height
                           nearDistance:(double)near
                            farDistance:(double)far
{
    if (horizontalFOV <= 0 || horizontalFOV > 180)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Field of view is invalid");
    }

    if (width <= 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Width is not positive");
    }

    if (height <= 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Height is not positive");
    }

    if (near == far)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Near and far are equal");
    }

    if (near <= 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Near is not positive");
    }

    if (far <= 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Far is not positive");
    }

    CGRect nearRect = [WWMath perspectiveFieldOfViewFrustumRect:horizontalFOV
                                                  viewportWidth:width
                                                 viewportHeight:height
                                                      zDistance:near];
    double left = CGRectGetMinX(nearRect);
    double right = CGRectGetMaxX(nearRect);
    double bottom = CGRectGetMinY(nearRect);
    double top = CGRectGetMaxY(nearRect);

    [self setPerspective:left
                   right:right
                  bottom:bottom
                     top:top
            nearDistance:near
             farDistance:far];

    return self;
}

- (WWMatrix*) setPerspectiveSizePreserving:(double)width
                            viewportHeight:(double)height
                              nearDistance:(double)near
                               farDistance:(double)far
{
    if (width <= 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Width is not positive");
    }

    if (height <= 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Height is not positive");
    }

    if (near == far)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Near and far are equal");
    }

    if (near <= 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Near is not positive");
    }

    if (far <= 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Far is not positive");
    }

    CGRect nearRect = [WWMath perspectiveSizePreservingFrustumRect:width viewportHeight:height zDistance:near];
    double left = CGRectGetMinX(nearRect);
    double right = CGRectGetMaxX(nearRect);
    double bottom = CGRectGetMinY(nearRect);
    double top = CGRectGetMaxY(nearRect);

    [self setPerspective:left
                   right:right
                  bottom:bottom
                     top:top
            nearDistance:near
             farDistance:far];

    return self;
}

- (WWMatrix*) multiplyMatrix:(WWMatrix*)matrix
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

    return self;
}

- (WWMatrix*) multiply:(double)m00 m01:(double)m01 m02:(double)m02 m03:(double)m03
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

    return self;
}

- (WWMatrix*) invert:(WWMatrix*)matrix
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

    return self;
}

- (WWMatrix*) invertTransformMatrix:(WWMatrix*)matrix
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

    // Transform the translation vector of the specified matrix by the transpose of its upper 3x3 portion, and store the
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

    return self;
}

+ (void) eigensystemFromSymmetricMatrix:(WWMatrix*)matrix
                      resultEigenvalues:(NSMutableArray*)resultEigenvalues
                     resultEigenvectors:(NSMutableArray*)resultEigenvectors
{
    if (matrix == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Matrix is nil");
    }

    if (resultEigenvalues == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Result eigenvalues array is nil");
    }

    if (matrix->m[1] != matrix->m[4] || matrix->m[2] != matrix->m[8] || matrix->m[6] != matrix->m[9])
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Matrix is not symmetric");
    }

    // Taken from "Mathematics for 3D Game Programming and Computer Graphics, Second Edition" by Eric Lengyel,
    // listing 14.6 (pages 441-444).

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

    [resultEigenvalues addObject:[NSNumber numberWithDouble:m11]];
    [resultEigenvalues addObject:[NSNumber numberWithDouble:m22]];
    [resultEigenvalues addObject:[NSNumber numberWithDouble:m33]];

    [resultEigenvectors addObject:[[WWVec4 alloc] initWithCoordinates:r[0][0] y:r[1][0] z:r[2][0]]];
    [resultEigenvectors addObject:[[WWVec4 alloc] initWithCoordinates:r[0][1] y:r[1][1] z:r[2][1]]];
    [resultEigenvectors addObject:[[WWVec4 alloc] initWithCoordinates:r[0][2] y:r[1][2] z:r[2][2]]];
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

- (void) offsetPerspectiveDepth:(double)depthOffset
{
    self->m[10] *= 1 + depthOffset;
}

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