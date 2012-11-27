/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Geometry/WWVec4.h"
#import "WorldWind/WWLog.h"

@implementation WWVec4

+(void)initialize
{
    // Create the class constants.
    
    WWVEC4_ZERO = [[WWVec4 alloc] initWithCoordinates:0 y:0 z:0];
    WWVEC4_ONE = [[WWVec4 alloc] initWithCoordinates:1 y:1 z:1];
    WWVEC4_UNIT_X = [[WWVec4 alloc] initWithCoordinates:1 y:0 z:0];
    WWVEC4_UNIT_Y = [[WWVec4 alloc] initWithCoordinates:0 y:1 z:0];
    WWVEC4_UNIT_Z = [[WWVec4 alloc] initWithCoordinates:0 y:0 z:1];
}

- (WWVec4*) initWithCoordinates:(double)x y:(double)y z:(double)z
{
    self = [super self];
    
    _x = x;
    _y = y;
    _z = z;
    _w = 1;
    
    return self;
}

- (WWVec4*) initWithCoordinates:(double)x y:(double)y z:(double)z w:(double)w
{
    self = [super self];
    
    _x = x;
    _y = y;
    _z = z;
    _w = w;
    
    return self;
}

- (id) copyWithZone:(NSZone *)zone
{
    return [[[self class] alloc] initWithCoordinates:_x y:_y z:_z w:_w];
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
