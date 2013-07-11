/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Geometry/WWBoundingBox.h"
#import "WorldWind/Geometry/WWFrustum.h"
#import "WorldWind/Geometry/WWPlane.h"
#import "Worldwind/Geometry/WWSector.h"
#import "WorldWind/Geometry/WWVec4.h"
#import "WorldWind/Terrain/WWGlobe.h"
#import "WorldWind/Util/WWMath.h"
#import "WorldWind/WWLog.h"

void WWBoundingBoxAdjustExtremes(WWVec4* __unsafe_unretained r, double* rExtremes,
        WWVec4* __unsafe_unretained s, double* sExtremes,
        WWVec4* __unsafe_unretained t, double* tExtremes,
        WWVec4* __unsafe_unretained p)
{
    double pdr = [p dot3:r];
    if (rExtremes[0] > pdr)
        rExtremes[0] = pdr;
    if (rExtremes[1] < pdr)
        rExtremes[1] = pdr;

    double pds = [p dot3:s];
    if (sExtremes[0] > pds)
        sExtremes[0] = pds;
    if (sExtremes[1] < pds)
        sExtremes[1] = pds;

    double pdt = [p dot3:t];
    if (tExtremes[0] > pdt)
        tExtremes[0] = pdt;
    if (tExtremes[1] < pdt)
        tExtremes[1] = pdt;
}

void WWBoundingBoxSwapAxes(WWVec4* __unsafe_unretained a, double* aExtremes,
        WWVec4* __unsafe_unretained b, double* bExtremes,
        WWVec4* __unsafe_unretained tmp)
{
    [tmp set:a];
    [a set:b];
    [b set:tmp];

    double tmp0 = aExtremes[0];
    double tmp1 = aExtremes[1];
    aExtremes[0] = bExtremes[0];
    aExtremes[1] = bExtremes[1];
    bExtremes[0] = tmp0;
    bExtremes[1] = tmp1;
}

@implementation WWBoundingBox

- (WWBoundingBox*) initWithUnitBox;
{
    self = [super init];

    tmp1 = [[WWVec4 alloc] initWithZeroVector];
    tmp2 = [[WWVec4 alloc] initWithZeroVector];
    tmp3 = [[WWVec4 alloc] initWithZeroVector];

    _center = [[WWVec4 alloc] initWithCoordinates:0 y:0 z:0];
    _bottomCenter = [[WWVec4 alloc] initWithCoordinates:-0.5 y:0 z:0];
    _topCenter = [[WWVec4 alloc] initWithCoordinates:0.5 y:0 z:0];
    _r = [[WWVec4 alloc] initWithCoordinates:1 y:0 z:0];
    _s = [[WWVec4 alloc] initWithCoordinates:0 y:1 z:0];
    _t = [[WWVec4 alloc] initWithCoordinates:0 y:0 z:1];
    _radius = sqrt(3); // sqrt(1*1 + 1*1 + 1*1)

    return self;
}

- (void) setToPoints:(NSArray* __unsafe_unretained)points
{
    if (points == nil || [points count] == 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Points is nil or zero length")
    }

    [WWMath principalAxesFromPoints:points axis1:_r axis2:_s axis3:_t];

    // Find the extremes along each axis.
    double rMin = +DBL_MAX;
    double rMax = -DBL_MAX;
    double sMin = +DBL_MAX;
    double sMax = -DBL_MAX;
    double tMin = +DBL_MAX;
    double tMax = -DBL_MAX;

    for (WWVec4* __unsafe_unretained p in points) // no need to check for nil; NSArray does not permit nil elements
    {
        double pdr = [p dot3:_r];
        if (rMin > pdr)
            rMin = pdr;
        if (rMax < pdr)
            rMax = pdr;

        double pds = [p dot3:_s];
        if (sMin > pds)
            sMin = pds;
        if (sMax < pds)
            sMax = pds;

        double pdt = [p dot3:_t];
        if (tMin > pdt)
            tMin = pdt;
        if (tMax < pdt)
            tMax = pdt;
    }

    if (rMax == rMin)
        rMax = rMin + 1;
    if (sMax == sMin)
        sMax = sMin + 1;
    if (tMax == tMin)
        tMax = tMin + 1;

    double rLen = rMax - rMin;
    double sLen = sMax - sMin;
    double tLen = tMax - tMin;
    double rSum = rMax + rMin;
    double sSum = sMax + sMin;
    double tSum = tMax + tMin;

    double rx_2 = 0.5 * [_r x] * rLen;
    double ry_2 = 0.5 * [_r y] * rLen;
    double rz_2 = 0.5 * [_r z] * rLen;
    double cx = 0.5 * ([_r x] * rSum + [_s x] * sSum + [_t x] * tSum);
    double cy = 0.5 * ([_r y] * rSum + [_s y] * sSum + [_t y] * tSum);
    double cz = 0.5 * ([_r z] * rSum + [_s z] * sSum + [_t z] * tSum);
    [_center set:cx y:cy z:cz];
    [_topCenter set:cx + rx_2 y:cy + ry_2 z:cz + rz_2];
    [_bottomCenter set:cx - rx_2 y:cy - ry_2 z:cz - rz_2];

    [_r multiplyByScalar3:rLen];
    [_s multiplyByScalar3:sLen];
    [_t multiplyByScalar3:tLen];
    _radius = 0.5 * sqrt(rLen * rLen + sLen * sLen + tLen * tLen);
}

- (void) setToSector:(WWSector* __unsafe_unretained)sector
             onGlobe:(WWGlobe* __unsafe_unretained)globe
        minElevation:(double)minElevation
        maxElevation:(double)maxElevation
{
    if (sector == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Sector is nil")
    }

    if (globe == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Globe is nil")
    }

    double minLat = [sector minLatitude];
    double maxLat = [sector maxLatitude];
    double minLon = [sector minLongitude];
    double maxLon = [sector maxLongitude];
    double cenLat = [sector centroidLat];
    double cenLon = [sector centroidLon];

    // Compute the centroid point with the maximum elevation. This point is used to compute the local coordinate axes
    // at the sector's centroid, and to capture the maximum vertical dimension below.
    WWVec4* __unsafe_unretained p = tmp1;
    [globe computePointFromPosition:cenLat longitude:cenLon altitude:maxElevation outputPoint:p];

    // Compute the local coordinate axes. Since we know this box is bounding a geographic sector, we use the local
    // coordinate axes at its centroid as the box axes. Using these axes results in a box that has +-10% the volume of
    // a box with axes derived from a principal component analysis.
    [WWMath localCoordinateAxesAtPoint:p onGlobe:globe xaxis:_r yaxis:_s zaxis:_t];

    // Find the extremes along each axis.
    double rExtremes[2] = {+DBL_MAX, -DBL_MAX};
    double sExtremes[2] = {+DBL_MAX, -DBL_MAX};
    double tExtremes[2] = {+DBL_MAX, -DBL_MAX};

    // A point at the centroid captures the maximum vertical dimension.
    WWBoundingBoxAdjustExtremes(_r, rExtremes, _s, sExtremes, _t, tExtremes, p);
    // Bottom-left corner with min elevation.
    [globe computePointFromPosition:minLat longitude:minLon altitude:minElevation outputPoint:p];
    WWBoundingBoxAdjustExtremes(_r, rExtremes, _s, sExtremes, _t, tExtremes, p);
    // Bottom-left corner with max elevation.
    [globe computePointFromPosition:minLat longitude:minLon altitude:maxElevation outputPoint:p];
    WWBoundingBoxAdjustExtremes(_r, rExtremes, _s, sExtremes, _t, tExtremes, p);
    // Bottom-right corner with min elevation.
    [globe computePointFromPosition:minLat longitude:maxLon altitude:minElevation outputPoint:p];
    WWBoundingBoxAdjustExtremes(_r, rExtremes, _s, sExtremes, _t, tExtremes, p);
    // Bottom-right corner with max elevation.
    [globe computePointFromPosition:minLat longitude:maxLon altitude:maxElevation outputPoint:p];
    WWBoundingBoxAdjustExtremes(_r, rExtremes, _s, sExtremes, _t, tExtremes, p);
    // Top-right corner with min elevation.
    [globe computePointFromPosition:maxLat longitude:maxLon altitude:minElevation outputPoint:p];
    WWBoundingBoxAdjustExtremes(_r, rExtremes, _s, sExtremes, _t, tExtremes, p);
    // Top-right corner with max elevation.
    [globe computePointFromPosition:maxLat longitude:maxLon altitude:maxElevation outputPoint:p];
    WWBoundingBoxAdjustExtremes(_r, rExtremes, _s, sExtremes, _t, tExtremes, p);
    // Top-left corner with min elevation.
    [globe computePointFromPosition:maxLat longitude:minLon altitude:minElevation outputPoint:p];
    WWBoundingBoxAdjustExtremes(_r, rExtremes, _s, sExtremes, _t, tExtremes, p);
    // Top-left corner with max elevation.
    [globe computePointFromPosition:maxLat longitude:minLon altitude:maxElevation outputPoint:p];
    WWBoundingBoxAdjustExtremes(_r, rExtremes, _s, sExtremes, _t, tExtremes, p);

    if (minLat < 0 && maxLat > 0)
    {
        // If the sector spans the equator then the curvature of all four edges needs to be considered. The extreme points
        // along the top and bottom edges are located at their mid-points and the extreme points along the left and right
        // edges are on the equator. Add points with the longitude of the sector's centroid but with the sector's min and
        // max latitude, and add points with the sector's min and max longitude but with latitude at the equator. See
        // WWJINT-225.
        [globe computePointFromPosition:minLat longitude:cenLon altitude:maxElevation outputPoint:p];
        WWBoundingBoxAdjustExtremes(_r, rExtremes, _s, sExtremes, _t, tExtremes, p);
        [globe computePointFromPosition:maxLat longitude:cenLon altitude:maxElevation outputPoint:p];
        WWBoundingBoxAdjustExtremes(_r, rExtremes, _s, sExtremes, _t, tExtremes, p);
        [globe computePointFromPosition:0 longitude:minLon altitude:maxElevation outputPoint:p];
        WWBoundingBoxAdjustExtremes(_r, rExtremes, _s, sExtremes, _t, tExtremes, p);
        [globe computePointFromPosition:0 longitude:maxLon altitude:maxElevation outputPoint:p];
        WWBoundingBoxAdjustExtremes(_r, rExtremes, _s, sExtremes, _t, tExtremes, p);
    }
    else if (minLat < 0)
    {
        // If the sector is located entirely in the southern hemisphere, then the curvature of its top edge needs to be
        // considered. The extreme point along the top edge is located at its mid-point. Add a point with the longitude
        // of the sector's centroid but with the sector's max latitude. See WWJINT-225.
        [globe computePointFromPosition:maxLat longitude:cenLon altitude:maxElevation outputPoint:p];
        WWBoundingBoxAdjustExtremes(_r, rExtremes, _s, sExtremes, _t, tExtremes, p);
    }
    else
    {
        // If the sector is located entirely within the northern hemisphere then the curvature of its bottom edge needs to
        // be considered. The extreme point along the bottom edge is located at its mid-point. Add a point with the
        // longitude of the sector's centroid but with the sector's min latitude. See WWJINT-225.
        [globe computePointFromPosition:minLat longitude:cenLon altitude:maxElevation outputPoint:p];
        WWBoundingBoxAdjustExtremes(_r, rExtremes, _s, sExtremes, _t, tExtremes, p);
    }

    if (maxLon - minLon > 180)  // Need to compute more points to ensure the box encompasses the full sector.
    {
        // Centroid latitude, longitude midway between min longitude and centroid longitude.
        double lon = 0.5 * (minLon + cenLon);
        [globe computePointFromPosition:cenLat longitude:lon altitude:maxElevation outputPoint:p];
        WWBoundingBoxAdjustExtremes(_r, rExtremes, _s, sExtremes, _t, tExtremes, p);
        // Centroid latitude, longitude midway between centroid longitude and max longitude.
        lon = 0.5 * (maxLon + cenLon);
        [globe computePointFromPosition:cenLat longitude:lon altitude:maxElevation outputPoint:p];
        WWBoundingBoxAdjustExtremes(_r, rExtremes, _s, sExtremes, _t, tExtremes, p);
        // Centroid latitude, longitude at min longitude.
        [globe computePointFromPosition:cenLat longitude:minLon altitude:maxElevation outputPoint:p];
        WWBoundingBoxAdjustExtremes(_r, rExtremes, _s, sExtremes, _t, tExtremes, p);
        // Centroid latitude, longitude at max longitude.
        [globe computePointFromPosition:cenLat longitude:maxLon altitude:maxElevation outputPoint:p];
        WWBoundingBoxAdjustExtremes(_r, rExtremes, _s, sExtremes, _t, tExtremes, p);
    }

    // Sort the axes from most prominent to least prominent. The frustum intersection methods in WWBoundingBox assume
    // that the axes are defined in this way.

    if (rExtremes[1] - rExtremes[0] < sExtremes[1] - sExtremes[0]) {WWBoundingBoxSwapAxes(_r, rExtremes, _s, sExtremes, tmp1);}
    if (sExtremes[1] - sExtremes[0] < tExtremes[1] - tExtremes[0]) {WWBoundingBoxSwapAxes(_s, sExtremes, _t, tExtremes, tmp1);}
    if (rExtremes[1] - rExtremes[0] < sExtremes[1] - sExtremes[0]) {WWBoundingBoxSwapAxes(_r, rExtremes, _s, sExtremes, tmp1);}

    // Compute the box properties from its unit axes and the extremes along each axis.
    double rLen = rExtremes[1] - rExtremes[0];
    double sLen = sExtremes[1] - sExtremes[0];
    double tLen = tExtremes[1] - tExtremes[0];
    double rSum = rExtremes[1] + rExtremes[0];
    double sSum = sExtremes[1] + sExtremes[0];
    double tSum = tExtremes[1] + tExtremes[0];

    double cx = 0.5 * ([_r x] * rSum + [_s x] * sSum + [_t x] * tSum);
    double cy = 0.5 * ([_r y] * rSum + [_s y] * sSum + [_t y] * tSum);
    double cz = 0.5 * ([_r z] * rSum + [_s z] * sSum + [_t z] * tSum);
    double rx_2 = 0.5 * [_r x] * rLen;
    double ry_2 = 0.5 * [_r y] * rLen;
    double rz_2 = 0.5 * [_r z] * rLen;
    [_center set:cx y:cy z:cz];
    [_topCenter set:cx + rx_2 y:cy + ry_2 z:cz + rz_2];
    [_bottomCenter set:cx - rx_2 y:cy - ry_2 z:cz - rz_2];

    [_r multiplyByScalar3:rLen];
    [_s multiplyByScalar3:sLen];
    [_t multiplyByScalar3:tLen];
    _radius = 0.5 * sqrt(rLen * rLen + sLen * sLen + tLen * tLen);
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
}

@end