/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Geometry/WWFrustum.h"
#import "WorldWind/Geometry/WWPlane.h"
#import "WorldWind/WWLog.h"
#import "WorldWind/Geometry/WWVec4.h"
#import "WorldWind/Geometry/WWMatrix.h"

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
//
//- (WWFrustum*) initWithViewportWidth:(double)viewportWidth
//                    viewportHeight:(double)viewportHeight
//                      nearDistance:(double)nearDistance
//                       farDistance:(double)farDistance
//{
//    double focalLength = viewportWidth / viewportHeight;
//    double aspect = viewportHeight/ viewportWidth;
//    double lrLen = sqrt(focalLength * focalLength + 1);
//    double btLen = sqrt(focalLength * focalLength + aspect * aspect);
//
//    _left = [[WWPlane alloc] initWithCoordinates:focalLength / lrLen y:0 z:-1 / lrLen distance:0];
//    _right = [[WWPlane alloc] initWithCoordinates:-focalLength / lrLen y:0 z:-1 / lrLen distance:0];
//
//    _bottom = [[WWPlane alloc] initWithCoordinates:0 y:focalLength / btLen z:-aspect / btLen distance:0];
//    _top = [[WWPlane alloc] initWithCoordinates:0 y:-focalLength / btLen z:-aspect / btLen distance:0];
//
//    _near = [[WWPlane alloc] initWithCoordinates:0 y:0 z:-1 distance:-nearDistance];
//    _far = [[WWPlane alloc] initWithCoordinates:0 y:0 z:1 distance:farDistance];
//
//    return self;
//}

- (WWFrustum*) initWithTransformedFrustum:(WWFrustum*)frustum matrix:(WWMatrix*)matrix
{
    if (frustum == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Frustum is nil")
    }

    if (matrix == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Matrix is nil")
    }

    self = [super init];

    _left = [[WWPlane alloc] initWithNormal:[frustum->_left vector]];
    _right = [[WWPlane alloc] initWithNormal:[frustum->_right vector]];
    _bottom = [[WWPlane alloc] initWithNormal:[frustum->_bottom vector]];
    _top = [[WWPlane alloc] initWithNormal:[frustum->_top vector]];
    _near = [[WWPlane alloc] initWithNormal:[frustum->_near vector]];
    _far = [[WWPlane alloc] initWithNormal:[frustum->_far vector]];

    [_left transformByMatrix:matrix];
    [_right transformByMatrix:matrix];
    [_bottom transformByMatrix:matrix];
    [_top transformByMatrix:matrix];
    [_near transformByMatrix:matrix];
    [_far transformByMatrix:matrix];

    return self;
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