/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Geometry/WWBoundingSphere.h"
#import "WorldWind/Geometry/WWVec4.h"
#import "WorldWind/WWLog.h"
#import "WorldWind/Geometry/WWFrustum.h"
#import "WorldWind/Geometry/WWPlane.h"

@implementation WWBoundingSphere

- (WWBoundingSphere*) initWithPoints:(NSArray*)points
{
    if (points == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Points array is nil");
    }

    self = [super init];

    WWVec4* p0 = [points objectAtIndex:0];
    double xmin = [p0 x];
    double ymin = [p0 y];
    double zmin = [p0 z];
    double xmax = xmin;
    double ymax = ymin;
    double zmax = zmin;

    for (NSUInteger i = 0; i < [points count]; i++)
    {
        WWVec4* point = [points objectAtIndex:i];

        double x = [point x];
        if (x > xmax)
            xmax = x;
        if (x < xmin)
            xmin = x;

        double y = [point y];
        if (y > ymax)
            ymax = y;
        if (y < ymin)
            ymin = y;

        double z = [point z];
        if (z > zmax)
            zmax = z;
        if (z < zmin)
            zmin = z;
    }

    double cx = (xmax + xmin) / 2;
    double cy = (ymax + ymin) / 2;
    double cz = (zmax + zmin) / 2;
    _center = [[WWVec4 alloc] initWithCoordinates:cx y:cy z:cz];

    _radius = sqrt((xmax - xmin) * (xmax - xmin) + (ymax - ymin) * (ymax - ymin) + (zmax - zmin) * (zmax - zmin)) / 2;

    return self;
}

- (WWBoundingSphere*) initWithPoint:(WWVec4*)point radius:(double)radius
{
    if (point == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Point is nil");
    }

    if (radius <= 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Radius is less than or equal to 0");
    }

    self = [super init];

    _center = point;
    _radius = radius;

    return self;
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

- (double) effectiveRadius:(WWPlane*)plane
{
    if (plane == nil)
        return 0;

    return _radius;
}

- (BOOL) intersects:(WWFrustum*)frustum
{
    if (frustum == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Frustum is nil")
    }

    if ([[frustum far] dot:_center] <= -_radius)
        return NO;

    if ([[frustum near] dot:_center] <= -_radius)
        return NO;

    if ([[frustum bottom] dot:_center] <= -_radius)
        return NO;

    if ([[frustum top] dot:_center] <= -_radius)
        return NO;

    if ([[frustum left] dot:_center] <= -_radius)
        return NO;

    if ([[frustum right] dot:_center] <= -_radius)
        return NO;

    return YES;
}

@end