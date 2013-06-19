/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Geometry/WWFrustum.h"
#import "WorldWind/Geometry/WWPlane.h"
#import "WorldWind/Geometry/WWMatrix.h"
#import "WorldWind/WWLog.h"

@implementation WWFrustum

- (WWFrustum*) initToCanonicalFrustum
{
    self = [super init];

    _left = [[WWPlane alloc] initWithCoordinates:1 y:0 z:0 distance:1];
    _right = [[WWPlane alloc] initWithCoordinates:-1 y:0 z:0 distance:1];
    _bottom = [[WWPlane alloc] initWithCoordinates:0 y:1 z:0 distance:1];
    _top = [[WWPlane alloc] initWithCoordinates:0 y:-1 z:0 distance:1];
    _near = [[WWPlane alloc] initWithCoordinates:0 y:0 z:-1 distance:1];
    _far = [[WWPlane alloc] initWithCoordinates:0 y:0 z:1 distance:1];

    return self;
}

- (WWFrustum*) initWithPlanes:(WWPlane*)left
                        right:(WWPlane*)right
                       bottom:(WWPlane*)bottom
                          top:(WWPlane*)top
                         near:(WWPlane*)near
                          far:(WWPlane*)far
{
    if (left == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Left plane is nil")
    }

    if (right == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Right plane is nil")
    }

    if (bottom == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Bottom plane is nil")
    }

    if (top == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Top plane is nil")
    }

    if (near == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Near plane is nil")
    }

    if (far == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Far plane is nil")
    }

    self = [super init];

    _left = left;
    _right = right;
    _bottom = bottom;
    _top = top;
    _near = near;
    _far = far;

    return self;
}

- (void) transformByMatrix:(WWMatrix* __unsafe_unretained)matrix
{
    if (matrix == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Matrix is nil")
    }

    [_left transformByMatrix:matrix];
    [_right transformByMatrix:matrix];
    [_bottom transformByMatrix:matrix];
    [_top transformByMatrix:matrix];
    [_near transformByMatrix:matrix];
    [_far transformByMatrix:matrix];
}

- (void) normalize
{
    [_left normalize];
    [_right normalize];
    [_bottom normalize];
    [_top normalize];
    [_near normalize];
    [_far normalize];
}

@end