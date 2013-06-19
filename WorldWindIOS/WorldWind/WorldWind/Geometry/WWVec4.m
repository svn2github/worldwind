/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Geometry/WWVec4.h"
#import "WorldWind/Geometry/WWMatrix.h"
#import "WorldWind/WWLog.h"

@implementation WWVec4

- (WWVec4*) initWithCoordinates:(double)x y:(double)y z:(double)z
{
    self = [super init];

    _x = x;
    _y = y;
    _z = z;
    _w = 1;

    return self;
}

- (WWVec4*) initWithCoordinates:(double)x y:(double)y z:(double)z w:(double)w
{
    self = [super init];

    _x = x;
    _y = y;
    _z = z;
    _w = w;

    return self;
}

- (WWVec4*) initWithVector:(WWVec4* __unsafe_unretained)vector
{
    if (vector == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Vector is nil")
    }

    self = [super init];

    _x = vector->_x;
    _y = vector->_y;
    _z = vector->_z;
    _w = vector->_w;

    return self;
}

- (WWVec4*) initWithZeroVector
{
    self = [super init];

    _x = 0;
    _y = 0;
    _z = 0;
    _w = 1;

    return self;
}

- (WWVec4*) initWithAverageOfVectors:(NSArray* __unsafe_unretained)vectors
{
    if (vectors == nil || [vectors count] == 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Vectors is nil or empty")
    }

    self = [super init];

    int count = 0;
    _x = 0;
    _y = 0;
    _z = 0;
    _w = 0;

    for (WWVec4* __unsafe_unretained vec in vectors) // no need to check for nil; NSArray does not permit nil elements
    {
        ++count;
        _x += vec->_x;
        _y += vec->_y;
        _z += vec->_z;
        _w += vec->_w;
    }

    _x /= count;
    _y /= count;
    _z /= count;
    _w /= count;

    return self;
}

+ (void) pointOnLine:(WWVec4* __unsafe_unretained)origin direction:(WWVec4* __unsafe_unretained)direction t:(double)t result:(WWVec4* __unsafe_unretained)result
{
    if (origin == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Origin is nil")
    }

    if (direction == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Direction is nil")
    }

    if (result == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Result is nil")
    }

    result->_x = origin->_x + direction->_x * t;
    result->_y = origin->_y + direction->_y * t;
    result->_z = origin->_z + direction->_z * t;
}

- (id) copyWithZone:(NSZone*)zone
{
    return [[[self class] alloc] initWithCoordinates:_x y:_y z:_z w:_w];
}

- (void) set:(double)x y:(double)y
{
    _x = x;
    _y = y;
    _z = 0;
    _w = 1;
}

- (void) set:(double)x y:(double)y z:(double)z
{
    _x = x;
    _y = y;
    _z = z;
    _w = 1;
}

- (void) set:(double)x y:(double)y z:(double)z w:(double)w
{
    _x = x;
    _y = y;
    _z = z;
    _w = w;
}

- (void) set:(WWVec4* __unsafe_unretained)vector
{
    if (vector == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Vector is nil")
    }

    _x = vector->_x;
    _y = vector->_y;
    _z = vector->_z;
    _w = vector->_w;
}

- (void) setToZeroVector
{
    _x = 0;
    _y = 0;
    _z = 0;
    _w = 1;
}

- (double) length3
{
    return sqrt(_x * _x + _y * _y + _z * _z);
}

- (double) lengthSquared3
{
    return _x * _x + _y * _y + _z * _z;
}

- (void) normalize3
{
    double length = [self length3];
    if (length == 0)
    {
        return; // Vector has zero length.
    }

    _x /= length;
    _y /= length;
    _z /= length;
}

- (void) add3:(WWVec4* __unsafe_unretained)vector
{
    if (vector == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Vector is nil")
    }

    _x += vector->_x;
    _y += vector->_y;
    _z += vector->_z;
}

- (void) subtract3:(WWVec4* __unsafe_unretained)vector
{
    if (vector == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Vector is nil")
    }

    _x -= vector->_x;
    _y -= vector->_y;
    _z -= vector->_z;
}

- (void) multiplyByScalar3:(double)scalar
{
    _x *= scalar;
    _y *= scalar;
    _z *= scalar;
}

- (void) multiplyByScalar:(double)scalar
{
    _x *= scalar;
    _y *= scalar;
    _z *= scalar;
    _w *= scalar;
}

- (void) multiplyByMatrix:(WWMatrix* __unsafe_unretained)matrix
{
    if (matrix == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Matrix is nil");
    }

    double* m = matrix->m;

    double x = m[0] * _x + m[1] * _y + m[2] * _z + m[3] * _w;
    double y = m[4] * _x + m[5] * _y + m[6] * _z + m[7] * _w;
    double z = m[8] * _x + m[9] * _y + m[10] * _z + m[11] * _w;
    double w = m[12] * _x + m[13] * _y + m[14] * _z + m[15] * _w;

    _x = x;
    _y = y;
    _z = z;
    _w = w;
}

- (void) divideByScalar3:(double)scalar
{
    if (scalar == 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Scalar is zero")
    }

    _x /= scalar;
    _y /= scalar;
    _z /= scalar;
}

- (void) divideByScalar:(double)scalar
{
    if (scalar == 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Scalar is zero")
    }

    _x /= scalar;
    _y /= scalar;
    _z /= scalar;
    _w /= scalar;
}

- (double) distanceTo3:(WWVec4* __unsafe_unretained)vector
{
    if (vector == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Vector is nil")
    }

    double dx = vector->_x - _x;
    double dy = vector->_y - _y;
    double dz = vector->_z - _z;

    return sqrt(dx * dx + dy * dy + dz * dz);
}

- (double) distanceSquared3:(WWVec4* __unsafe_unretained)vector
{
    if (vector == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Vector is nil")
    }

    double dx = vector->_x - _x;
    double dy = vector->_y - _y;
    double dz = vector->_z - _z;

    return dx * dx + dy * dy + dz * dz;
}

- (double) dot3:(WWVec4* __unsafe_unretained)vector
{
    if (vector == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Vector is nil")
    }

    return _x * vector->_x + _y * vector->_y + _z * vector->_z;
}

- (double) dot4:(WWVec4* __unsafe_unretained)vector
{
    if (vector == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Vector is nil")
    }

    return _x * vector->_x + _y * vector->_y + _z * vector->_z + _w * vector->_w;
}

- (void) cross3:(WWVec4* __unsafe_unretained)vector
{
    if (vector == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Vector is nil")
    }

    double x = _x;
    double y = _y;
    double z = _z;

    _x = (y * vector->_z) - (z * vector->_y);
    _y = (z * vector->_x) - (x * vector->_z);
    _z = (x * vector->_y) - (y * vector->_x);
}

@end