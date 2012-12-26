/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Geometry/WWVec4.h"
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

- (WWVec4*) initWithZeroVector
{
    self = [super init];

    _x = 0;
    _y = 0;
    _z = 0;
    _w = 1;

    return self;
}

- (id) copyWithZone:(NSZone *)zone
{
    return [[[self class] alloc] initWithCoordinates:_x y:_y z:_z w:_w];
}

- (WWVec4*) set:(double)x y:(double)y
{
    _x = x;
    _y = y;
    _z = 0;
    _w = 1;

    return self;
}

- (WWVec4*) set:(double)x y:(double)y z:(double)z
{
    _x = x;
    _y = y;
    _z = z;
    _w = 1;

    return self;
}

- (WWVec4*) set:(double)x y:(double)y z:(double)z w:(double)w
{
    _x = x;
    _y = y;
    _z = z;
    _w = w;

    return self;
}

- (double) length3
{
    return sqrt(_x * _x + _y * _y + _z * _z);
}

- (WWVec4*) normalize3
{
    double length = [self length3];
    if (length == 0)
        return self; // Vector has zero length.

    _x /= length;
    _y /= length;
    _z /= length;

    return self;
}

-(WWVec4*) add3:(WWVec4 *)vector
{
    if (vector == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Vector is nil")
    }

    _x += vector.x;
    _y += vector.y;
    _z += vector.z;

    return self;
}

-(WWVec4*) subtract3:(WWVec4 *)vector
{
    if (vector == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Vector is nil")
    }

    _x -= vector.x;
    _y -= vector.y;
    _z -= vector.z;

    return self;
}

@end
