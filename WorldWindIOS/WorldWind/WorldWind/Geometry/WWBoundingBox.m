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

- (WWBoundingBox*) initWithPoint:(WWVec4*)point
{
    if (point == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Point is nil")
    }

    self = [super init];

    self->tmp1 = [[WWVec4 alloc] initWithZeroVector];
    self->tmp2 = [[WWVec4 alloc] initWithZeroVector];
    self->tmp3 = [[WWVec4 alloc] initWithZeroVector];

    _ru = [[WWVec4 alloc] initWithCoordinates:1 y:0 z:0];
    _su = [[WWVec4 alloc] initWithCoordinates:0 y:1 z:0];
    _tu = [[WWVec4 alloc] initWithCoordinates:0 y:0 z:1];

    _r = _ru;
    _s = _su;
    _t = _tu;

    _rLength = 1;
    _sLength = 1;
    _tLength = 1;

    // Plane normals point outwards from the box.
    NSMutableArray* thePlanes = [[NSMutableArray alloc] initWithCapacity:6];
    _planes = thePlanes;
    double d = 0.5 * [point length3];
    [thePlanes addObject:[[WWPlane alloc] initWithCoordinates:-1 y:+0 z:+0 distance:-(d + 0.5)]];
    [thePlanes addObject:[[WWPlane alloc] initWithCoordinates:+1 y:+0 z:+0 distance:-(d + 0.5)]];
    [thePlanes addObject:[[WWPlane alloc] initWithCoordinates:-0 y:-1 z:+0 distance:-(d + 0.5)]];
    [thePlanes addObject:[[WWPlane alloc] initWithCoordinates:+0 y:+1 z:+0 distance:-(d + 0.5)]];
    [thePlanes addObject:[[WWPlane alloc] initWithCoordinates:-0 y:+0 z:-1 distance:-(d + 0.5)]];
    [thePlanes addObject:[[WWPlane alloc] initWithCoordinates:+0 y:+0 z:+1 distance:-(d + 0.5)]];

    _center = [[WWVec4 alloc] initWithCoordinates:0.5 y:0.5 z:0.5];

    _topCenter = [[WWVec4 alloc] initWithCoordinates:1 y:0.5 z:0.5];
    _bottomCenter = [[WWVec4 alloc] initWithCoordinates:0 y:0.5 z:0.5];

    return self;
}

- (WWBoundingBox*) initWithPoints:(NSArray*)points
{
    if (points == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Points is nil")
    }

    self = [super init];

    self->tmp1 = [[WWVec4 alloc] initWithZeroVector];
    self->tmp2 = [[WWVec4 alloc] initWithZeroVector];
    self->tmp3 = [[WWVec4 alloc] initWithZeroVector];

    NSArray* unitAxes = [WWMath principalAxesFromPoints:points];
    if (unitAxes == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Unable to compute principal axes")
    }

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

    for (NSUInteger i = 0; i < [points count]; i++)
    {
        WWVec4* p = [points objectAtIndex:i];

        if (p == nil)
            continue;

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

    WWVec4* ruh = [[[WWVec4 alloc] initWithVector:_ru] multiplyByScalar3:0.5 * (maxDotR + minDotR)];
    WWVec4* suh = [[[WWVec4 alloc] initWithVector:_su] multiplyByScalar3:0.5 * (maxDotS + minDotS)];
    WWVec4* tuh = [[[WWVec4 alloc] initWithVector:_tu] multiplyByScalar3:0.5 * (maxDotT + minDotT)];
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

- (double) radius
{
    return 0.5 * sqrt(_rLength * _rLength + _sLength * _sLength + _tLength * _tLength);
}

- (double) distanceTo:(WWVec4*)point
{
    if (point == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Point is nil")
    }

    double d = [point distanceTo3:_center] - [self radius];

    return d >= 0 ? d : 0;
}

- (double) effectiveRadiusST:(WWPlane*)plane
{
    // This method is used when the R axis need not be considered.
    // TODO: Cite passage by Lengyel that explains the use of this method.
    if (plane == nil)
        return 0;

    WWVec4* n = [plane vector];

    return 0.5 * (fabs([_s dot3:n]) + fabs([_t dot3:n]));
}

- (double) effectiveRadius:(WWPlane*)plane
{
    if (plane == nil)
        return 0;

    WWVec4* n = [plane vector];

    return 0.5 * (fabs([_r dot3:n]) + fabs([_s dot3:n]) + fabs([_t dot3:n]));
}

- (BOOL) intersects:(WWFrustum*)frustum
{
    if (frustum == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Frustum is nil")
    }

    [self->tmp1 set:_bottomCenter];
    [self->tmp2 set:_topCenter];

    double effectiveRadius = [self effectiveRadiusST:[frustum near]];
    double intersectionPoint = [self intersectsAt:[frustum near]
                                        effRadius:effectiveRadius
                                        endPoint1:self->tmp1
                                        endPoint2:self->tmp2];
    if (intersectionPoint < 0)
        return NO;

    effectiveRadius = [self effectiveRadiusST:[frustum far]];
    intersectionPoint = [self intersectsAt:[frustum far]
                                 effRadius:effectiveRadius
                                 endPoint1:self->tmp1
                                 endPoint2:self->tmp2];
    if (intersectionPoint < 0)
        return NO;

    effectiveRadius = [self effectiveRadiusST:[frustum left]];
    intersectionPoint = [self intersectsAt:[frustum left]
                                 effRadius:effectiveRadius
                                 endPoint1:self->tmp1
                                 endPoint2:self->tmp2];
    if (intersectionPoint < 0)
        return NO;

    effectiveRadius = [self effectiveRadiusST:[frustum right]];
    intersectionPoint = [self intersectsAt:[frustum right]
                                 effRadius:effectiveRadius
                                 endPoint1:self->tmp1
                                 endPoint2:self->tmp2];
    if (intersectionPoint < 0)
        return NO;

    effectiveRadius = [self effectiveRadiusST:[frustum top]];
    intersectionPoint = [self intersectsAt:[frustum top]
                                 effRadius:effectiveRadius
                                 endPoint1:self->tmp1
                                 endPoint2:self->tmp2];
    if (intersectionPoint < 0)
        return NO;

    effectiveRadius = [self effectiveRadiusST:[frustum bottom]];
    intersectionPoint = [self intersectsAt:[frustum bottom]
                                 effRadius:effectiveRadius
                                 endPoint1:self->tmp1
                                 endPoint2:self->tmp2];
    return intersectionPoint >= 0;
}

- (double) intersectsAt:(WWPlane*)plane
              effRadius:(double)effRadius
              endPoint1:(WWVec4*)endPoint1
              endPoint2:(WWVec4*)endPoint2
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
    [self->tmp3 set:endPoint1];
    [self->tmp3 subtract3:endPoint2];
    double t = (effRadius + dq1) / [[plane vector] dot3:self->tmp3];

    [self->tmp3 set:endPoint2];
    [self->tmp3 subtract3:endPoint1];
    [self->tmp3 multiplyByScalar3:t];
    [self->tmp3 add3:endPoint1];

    // Truncate the line to only that in the positive halfspace, e.g., inside the frustum.
    if (bq1)
        [endPoint1 set:self->tmp3];
    else
        [endPoint2 set:self->tmp3];

    return t;
}

- (void) translate:(WWVec4*)translation
{
    if (translation == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Translation is nil")
    }

    [_bottomCenter add3:translation];
    [_topCenter add3:translation];
    [_center add3:translation];

    for (NSUInteger i = 0; i < [_planes count]; i++)
    {
        [[_planes objectAtIndex:i] translate:translation];
    }
}

@end