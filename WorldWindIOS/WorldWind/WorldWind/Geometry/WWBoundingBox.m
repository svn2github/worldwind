/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Geometry/WWBoundingBox.h"
#import "WorldWind/Geometry/WWVec4.h"
#import "WorldWind/WWLog.h"
#import "WorldWind/Geometry/WWPlane.h"
#import "WorldWind/Util/WWMath.h"
#import "WorldWind/Geometry/WWFrustum.h"

@implementation WWBoundingBox

- (WWBoundingBox*) initWithPoints:(NSArray* __unsafe_unretained)points
{
    if (points == nil || [points count] == 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Points is nil or zero length")
    }

    self = [super init];

    tmp1 = [[WWVec4 alloc] initWithZeroVector];
    tmp2 = [[WWVec4 alloc] initWithZeroVector];
    tmp3 = [[WWVec4 alloc] initWithZeroVector];

    NSArray* unitAxes = [WWMath principalAxesFromPoints:points];
    _ru = [unitAxes objectAtIndex:0];
    _su = [unitAxes objectAtIndex:1];
    _tu = [unitAxes objectAtIndex:2];

    // Find the extremes along each axis.
    double minDotR = DBL_MAX;
    double maxDotR = -minDotR;
    double minDotS = DBL_MAX;
    double maxDotS = -minDotS;
    double minDotT = DBL_MAX;
    double maxDotT = -minDotT;

    for (WWVec4* __unsafe_unretained p in points) // no need to check for nil; NSArray does not permit nil elements
    {
        double pdr = [p dot3:_ru];
        if (pdr < minDotR)
            minDotR = pdr;
        if (pdr > maxDotR)
            maxDotR = pdr;

        double pds = [p dot3:_su];
        if (pds < minDotS)
            minDotS = pds;
        if (pds > maxDotS)
            maxDotS = pds;

        double pdt = [p dot3:_tu];
        if (pdt < minDotT)
            minDotT = pdt;
        if (pdt > maxDotT)
            maxDotT = pdt;
    }

    if (maxDotR == minDotR)
        maxDotR = minDotR + 1;
    if (maxDotS == minDotS)
        maxDotS = minDotS + 1;
    if (maxDotT == minDotT)
        maxDotT = minDotT + 1;

    _r = [[WWVec4 alloc] initWithVector:_ru];
    [_r multiplyByScalar3:(maxDotR - minDotR)];

    _s = [[WWVec4 alloc] initWithVector:_su];
    [_s multiplyByScalar3:(maxDotS - minDotS)];

    _t = [[WWVec4 alloc] initWithVector:_tu];
    [_t multiplyByScalar3:(maxDotT - minDotT)];

    _rLength = [_r length3];
    _sLength = [_s length3];
    _tLength = [_t length3];

    _radius = 0.5 * sqrt(_rLength * _rLength + _sLength * _sLength + _tLength * _tLength);

    WWVec4* ruh = [[WWVec4 alloc] initWithVector:_ru];
    WWVec4* suh = [[WWVec4 alloc] initWithVector:_su];
    WWVec4* tuh = [[WWVec4 alloc] initWithVector:_tu];
    [ruh multiplyByScalar3:0.5 * (maxDotR + minDotR)];
    [suh multiplyByScalar3:0.5 * (maxDotS + minDotS)];
    [tuh multiplyByScalar3:0.5 * (maxDotT + minDotT)];
    _center = [[WWVec4 alloc] initWithVector:ruh];
    [_center add3:suh];
    [_center add3:tuh];

    WWVec4* rHalf = [[WWVec4 alloc] initWithVector:_r];
    [rHalf multiplyByScalar3:0.5];
    _topCenter = [[WWVec4 alloc] initWithVector:_center];
    [_topCenter add3:rHalf];
    _bottomCenter = [[WWVec4 alloc] initWithVector:_center];
    [_bottomCenter subtract3:rHalf];

    NSMutableArray* thePlanes = [[NSMutableArray alloc] initWithCapacity:6];
    _planes = thePlanes;
    [thePlanes addObject:[[WWPlane alloc] initWithCoordinates:-[_ru x] y:-[_ru y] z:-[_ru z] distance:+minDotR]];
    [thePlanes addObject:[[WWPlane alloc] initWithCoordinates:+[_ru x] y:+[_ru y] z:+[_ru z] distance:-maxDotR]];
    [thePlanes addObject:[[WWPlane alloc] initWithCoordinates:-[_su x] y:-[_su y] z:-[_su z] distance:+minDotS]];
    [thePlanes addObject:[[WWPlane alloc] initWithCoordinates:+[_su x] y:+[_su y] z:+[_su z] distance:-maxDotS]];
    [thePlanes addObject:[[WWPlane alloc] initWithCoordinates:-[_tu x] y:-[_tu y] z:-[_tu z] distance:+minDotT]];
    [thePlanes addObject:[[WWPlane alloc] initWithCoordinates:+[_tu x] y:+[_tu y] z:+[_tu z] distance:-maxDotT]];

    return self;
}

- (double) distanceTo:(WWVec4* __unsafe_unretained)point
{
    if (point == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Point is nil")
    }

    double d = [point distanceTo3:_center] - _radius;

    return d >= 0 ? d : 0;
}

- (double) effectiveRadius:(WWPlane* __unsafe_unretained)plane
{
    if (plane == nil)
        return 0;

    WWVec4* n = [plane vector];

    return 0.5 * (fabs([_r dot3:n]) + fabs([_s dot3:n]) + fabs([_t dot3:n]));
}

- (BOOL) intersects:(WWFrustum* __unsafe_unretained)frustum
{
    if (frustum == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Frustum is nil")
    }

    // See Lengyel, Mathematics for 3D Game Programming & Computer Graphics, 2e, equation 7.49 for derivation
    // of bounding box effective radius calculations below.

    [tmp1 set:_bottomCenter];
    [tmp2 set:_topCenter];

    WWPlane* near = [frustum near];
    WWVec4* n = [near vector];
    double effectiveRadius = 0.5 * (fabs([_s dot3:n]) + fabs([_t dot3:n]));
    double intersectionPoint = [self intersectsAt:near
                                        effRadius:effectiveRadius
                                        endPoint1:tmp1
                                        endPoint2:tmp2];
    if (intersectionPoint < 0)
        return NO;

    WWPlane* far = [frustum far];
    n = [far vector];
    effectiveRadius = 0.5 * (fabs([_s dot3:n]) + fabs([_t dot3:n]));
    intersectionPoint = [self intersectsAt:far
                                 effRadius:effectiveRadius
                                 endPoint1:tmp1
                                 endPoint2:tmp2];
    if (intersectionPoint < 0)
        return NO;

    WWPlane* left = [frustum left];
    n = [left vector];
    effectiveRadius = 0.5 * (fabs([_s dot3:n]) + fabs([_t dot3:n]));
    intersectionPoint = [self intersectsAt:left
                                 effRadius:effectiveRadius
                                 endPoint1:tmp1
                                 endPoint2:tmp2];
    if (intersectionPoint < 0)
        return NO;

    WWPlane* right = [frustum right];
    n = [right vector];
    effectiveRadius = 0.5 * (fabs([_s dot3:n]) + fabs([_t dot3:n]));
    intersectionPoint = [self intersectsAt:right
                                 effRadius:effectiveRadius
                                 endPoint1:tmp1
                                 endPoint2:tmp2];
    if (intersectionPoint < 0)
        return NO;

    WWPlane* top = [frustum top];
    n = [top vector];
    effectiveRadius = 0.5 * (fabs([_s dot3:n]) + fabs([_t dot3:n]));
    intersectionPoint = [self intersectsAt:top
                                 effRadius:effectiveRadius
                                 endPoint1:tmp1
                                 endPoint2:tmp2];
    if (intersectionPoint < 0)
        return NO;

    WWPlane* bottom = [frustum bottom];
    n = [bottom vector];
    effectiveRadius = 0.5 * (fabs([_s dot3:n]) + fabs([_t dot3:n]));
    intersectionPoint = [self intersectsAt:bottom
                                 effRadius:effectiveRadius
                                 endPoint1:tmp1
                                 endPoint2:tmp2];
    return intersectionPoint >= 0;
}

- (double) intersectsAt:(WWPlane* __unsafe_unretained)plane
              effRadius:(double)effRadius
              endPoint1:(WWVec4* __unsafe_unretained)endPoint1
              endPoint2:(WWVec4* __unsafe_unretained)endPoint2
{
    // Test the distance from the first end-point.
    double dq1 = [plane dot:endPoint1];
    BOOL bq1 = dq1 <= -effRadius;

    // Test the distance from the second end-point.
    double dq2 = [plane dot:endPoint2];
    BOOL bq2 = dq2 <= -effRadius;

    if (bq1 && bq2) // endpoints more distant from plane than effective radius; box is on neg. side of plane
        return -1;

    if (bq1 == bq2) // endpoints less distant from plane than effective radius; can't draw any conclusions
        return 0;

    // Compute and return the endpoints of the box on the positive side of the plane
    [tmp3 set:endPoint1];
    [tmp3 subtract3:endPoint2];
    double t = (effRadius + dq1) / [[plane vector] dot3:tmp3];

    [tmp3 set:endPoint2];
    [tmp3 subtract3:endPoint1];
    [tmp3 multiplyByScalar3:t];
    [tmp3 add3:endPoint1];

    // Truncate the line to only that in the positive halfspace, e.g., inside the frustum.
    if (bq1)
        [endPoint1 set:tmp3];
    else
        [endPoint2 set:tmp3];

    return t;
}

- (void) translate:(WWVec4* __unsafe_unretained)translation
{
    if (translation == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Translation is nil")
    }

    [_bottomCenter add3:translation];
    [_topCenter add3:translation];
    [_center add3:translation];

    for (WWPlane* plane __unsafe_unretained in _planes)
    {
        [plane translate:translation];
    }
}

@end