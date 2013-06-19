/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "WorldWind/Geometry/WWLine.h"
#import "WorldWind/Geometry/WWVec4.h"
#import "WorldWind/WWLog.h"

@implementation WWLine

- (WWLine*) initWithOrigin:(WWVec4*)origin direction:(WWVec4*)direction
{
    if (origin == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Origin is nil")
    }

    if (direction == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Direction is nil")
    }

    if ([direction length3] == 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Direction length is zero")
    }

    self = [super init];

    _origin = origin;
    _direction = direction;

    return self;
}

- (void) pointAt:(double)distance result:(WWVec4* __unsafe_unretained)result
{
    if (result == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Result is nil")
    }

    [WWVec4 pointOnLine:_origin direction:_direction t:distance result:result];
}

- (void) nearestPointTo:(WWVec4* __unsafe_unretained)point result:(WWVec4* __unsafe_unretained)result
{
    if (point == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Point is nil")
    }

    if (result == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Result is nil")
    }

    // Compute a vector from this line's origin to the specified point.
    [result set:point];
    [result subtract3:_origin];

    // Compute the projection of the vector onto this line's direction.
    double proj = [result dot3:_direction] / [_direction dot3:_direction];

    // Compute the point on this line corresponding to the vector's projection.
    [self pointAt:proj result:result];
}

@end