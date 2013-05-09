/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Util/WWMath.h"
#import "WorldWind/Geometry/WWMatrix.h"
#import "WorldWind/Geometry/WWPosition.h"
#import "WorldWind/Geometry/WWVec4.h"
#import "WorldWind/Terrain/WWGlobe.h"
#import "WorldWind/WWLog.h"
#import "WorldWind/Geometry/WWLine.h"

#define ANIMATION_DISTANCE_MIN 1000
#define ANIMATION_DISTANCE_MAX 1000000
#define ANIMATION_DURATION_MIN 1.0
#define ANIMATION_DURATION_MAX 5.0

@implementation WWMath

//--------------------------------------------------------------------------------------------------------------------//
//-- Commonly Used Math Operations --//
//--------------------------------------------------------------------------------------------------------------------//

+ (double) clampValue:(double)value min:(double)min max:(double)max
{
    return value < min ? min : (value > max ? max : value);
}

+ (double) stepValue:(double)value min:(double)min max:(double)max
{
    // When the min and max are equivalent this cannot distinguish between the two. In this case, this returns 0 if the
    // value is on or before the min, and 1 if the value is after the max. The case that would cause a divide by zero
    // error is never evaluated. The value is always less than, equal to, or greater than the min/max.

    if (value <= min)
    {
        return 0;
    }
    else if (value >= max)
    {
        return 1;
    }
    else
    {
        return (value - min) / (max - min);
    }
}

+ (double) smoothStepValue:(double)value min:(double)min max:(double)max
{
    // When the min and max are equivalent this cannot distinguish between the two. In this case, this returns 0 if the
    // value is on or before the min, and 1 if the value is after the max. The case that would cause a divide by zero
    // error is never evaluated. The value is always less than, equal to, or greater than the min/max.

    if (value <= min)
    {
        return 0;
    }
    else if (value >= max)
    {
        return 1;
    }
    else
    {
        double step = (value - min) / (max - min);
        return step * step * (3 - 2 * step);
    }
}

+ (double) interpolateValue1:(double)value1 value2:(double)value2 amount:(double)amount
{
    return (1 - amount) * value1 + amount * value2;
}

+ (double) interpolateDegrees1:(double)angle1 degrees2:(double)angle2 amount:(double)amount
{
    // Normalize the two angles to the range [-180, +180].
    double a1 = [WWMath normalizeDegrees:angle1];
    double a2 = [WWMath normalizeDegrees:angle2];

    // If the shortest arc between the two angles crosses the -180/+180 degree boundary, add 360 degrees to the smaller
    // of the two angles then interpolate.
    if (a1 - a2 > 180)
    {
        a2 += 360;
    }
    else if (a1 - a2 < -180)
    {
        a1 += 360;
    }

    // Linearly interpolate between the two angles then normalize the interpolated result. Normalizing the result is
    // necessary when we have added 360 degrees to either angle in order to interpolate along the shortest arc.
    double a = (1 - amount) * a1 + amount * a2;
    return [WWMath normalizeDegrees:a];
}

+ (double) normalizeDegrees:(double)angle
{
    double a = fmod(angle, 360);
    return a > 180 ? a - 360 : (a < -180 ? 360 + a : a);
}

+ (double) normalizeDegreesLatitude:(double)latitude
{
    double lat = fmod(latitude, 180);
    return lat > 90 ? 180 - lat : (lat < -90 ? -180 - lat : lat);
}

+ (double) normalizeDegreesLongitude:(double)longitude
{
    double lon = fmod(longitude, 360);
    return lon > 180 ? lon - 360 : (lon < -180 ? 360 + lon : lon);
}

//--------------------------------------------------------------------------------------------------------------------//
//-- Computing Information About Shapes --//
//--------------------------------------------------------------------------------------------------------------------//

+ (NSArray*) principalAxesFromPoints:(NSArray*)points
{
    if (points == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Points is nil")
    }

    // Compute the covariance matrix.
    WWMatrix* covariance = [[WWMatrix alloc] initWithCovarianceOfPoints:points];
    if (covariance == nil)
        return nil;

    // Compute the eigenvectors and eigenvalues of the covariance matrix. Since the covariance matrix is symmetric by
    // definition, we can safely use the "symmetric" method below.
    NSMutableArray* eigenvalues = [[NSMutableArray alloc] initWithCapacity:3];
    NSMutableArray* eigenvectors = [[NSMutableArray alloc] initWithCapacity:3];
    [WWMatrix eigensystemFromSymmetricMatrix:covariance
                           resultEigenvalues:eigenvalues
                          resultEigenvectors:eigenvectors];

    // Return the normalized eigenvectors in order of decreasing eigenvalue. This has the effect of returning three
    // normalized orthogonal vectors defining a coordinate system, with the vectors sorted from the most prominent
    // axis to the lease prominent.
    NSArray* indexArray = [[NSArray alloc] initWithObjects:[NSNumber numberWithInt:0],
                                                           [NSNumber numberWithInt:1],
                                                           [NSNumber numberWithInt:2], nil];
    NSArray* sortedIndexArray = [indexArray sortedArrayUsingComparator:^NSComparisonResult(id a, id b)
    {
        NSUInteger indexA = (NSUInteger) [(NSNumber*) a intValue];
        NSUInteger indexB = (NSUInteger) [(NSNumber*) b intValue];

        return [[eigenvalues objectAtIndex:indexA] compare:[eigenvalues objectAtIndex:indexB]];
    }];

    NSUInteger index0 = (NSUInteger) [(NSNumber*) [sortedIndexArray objectAtIndex:0] intValue];
    NSUInteger index1 = (NSUInteger) [(NSNumber*) [sortedIndexArray objectAtIndex:1] intValue];
    NSUInteger index2 = (NSUInteger) [(NSNumber*) [sortedIndexArray objectAtIndex:2] intValue];

    NSMutableArray* resultArray = [[NSMutableArray alloc] initWithCapacity:3];
    [resultArray addObject:[[eigenvectors objectAtIndex:index2] normalize3]];
    [resultArray addObject:[[eigenvectors objectAtIndex:index1] normalize3]];
    [resultArray addObject:[[eigenvectors objectAtIndex:index0] normalize3]];

    return resultArray;
}

+ (NSArray*) localCoordinateAxesAtPoint:(WWVec4*)point onGlobe:(WWGlobe*)globe
{
    if (point == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Point is nil")
    }

    if (globe == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Globe is nil")
    }

    double x = [point x];
    double y = [point y];
    double z = [point z];

    // Compute the z axis from the surface normal in model coordinates. This axis is used to determine the other two
    // axes, and is the only constant in the computations below.
    WWVec4* zaxis = [[WWVec4 alloc] initWithZeroVector];
    [globe surfaceNormalAtPoint:x y:y z:z result:zaxis];

    // Compute the y axis from the north pointing tangent in model coordinates. This axis is known to be orthogonal to
    // the z axis, and is therefore used to compute the x axis.
    WWVec4* yaxis = [[WWVec4 alloc] initWithZeroVector];
    [globe northTangentAtPoint:x y:y z:z result:yaxis];

    // Compute the x axis as the cross product of the y and z axes. This ensures that the x and z axes are orthogonal.
    WWVec4* xaxis = [[WWVec4 alloc] initWithZeroVector];
    [xaxis set:yaxis];
    [xaxis cross3:zaxis];
    [xaxis normalize3];

    // Re-compute the y axis as the cross product of the z and x axes. This ensures that all three axes are orthogonal.
    // Though the initial y axis computed above is likely to be very nearly orthogonal, we re-compute it using cross
    // products to reduce the effect of floating point rounding errors caused by working with Earth sized coordinates.
    [yaxis set:zaxis];
    [yaxis cross3:xaxis];
    [yaxis normalize3];

    return [[NSArray alloc] initWithObjects:xaxis, yaxis, zaxis, nil];
}

+ (CGRect) boundingRectForUnitQuad:(WWMatrix*)transformMatrix
{
    if (transformMatrix == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Matrix is nil")
    }

    double* m = transformMatrix->m;
    // transform of (0, 0)
    double x1 = m[3];
    double y1 = m[7];
    // transform of (1, 0)
    double x2 = m[0] + m[3];
    double y2 = m[4] + m[7];
    // transform of (0, 1)
    double x3 = m[1] + m[3];
    double y3 = m[5] + m[7];
    // transform of (1, 1)
    double x4 = m[0] + m[1] + m[3];
    double y4 = m[4] + m[5] + m[7];

    double minX = MIN(MIN(x1, x2), MIN(x3, x4));
    double maxX = MAX(MAX(x1, x2), MAX(x3, x4));
    double minY = MIN(MIN(y1, y2), MIN(y3, y4));
    double maxY = MAX(MAX(y1, y2), MAX(y3, y4));

    return CGRectMake((CGFloat) minX, (CGFloat) minY, (CGFloat) (maxX - minX), (CGFloat) (maxY - minY));
}

//--------------------------------------------------------------------------------------------------------------------//
//-- Computing Viewing and Navigation Information --//
//--------------------------------------------------------------------------------------------------------------------//

+ (NSTimeInterval) durationForAnimationWithBeginPosition:(WWPosition*)posA
                                             endPosition:(WWPosition*)posB
                                                 onGlobe:(WWGlobe*)globe
{
    if (posA == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Begin position is nil")
    }

    if (posB == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"End position is nil")
    }

    if (globe == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Globe is nil")
    }

    WWVec4* pa = [[WWVec4 alloc] initWithZeroVector];
    WWVec4* pb = [[WWVec4 alloc] initWithZeroVector];
    [globe computePointFromPosition:[posA latitude] longitude:[posA longitude] altitude:[posA altitude] outputPoint:pa];
    [globe computePointFromPosition:[posB latitude] longitude:[posB longitude] altitude:[posB altitude] outputPoint:pb];

    double distance = [pa distanceTo3:pb];
    double stepDistance = [WWMath stepValue:distance min:ANIMATION_DISTANCE_MIN max:ANIMATION_DISTANCE_MAX];

    return [WWMath interpolateValue1:ANIMATION_DURATION_MIN value2:ANIMATION_DURATION_MAX amount:stepDistance];
}

+ (double) horizonDistanceForGlobeRadius:(double)radius eyeAltitude:(double)altitude
{
    if (radius < 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Radius is negative")
    }

    return (radius > 0 && altitude > 0) ? sqrt(altitude * (2 * radius + altitude)) : 0;
}

+ (CGRect) perspectiveFrustumRect:(CGRect)viewport atDistance:(double)near
{
    CGFloat viewportWidth = CGRectGetWidth(viewport);
    CGFloat viewportHeight = CGRectGetHeight(viewport);

    if (viewportWidth == 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Viewport width is zero")
    }

    if (viewportHeight == 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Viewport height is zero")
    }

    // Compute a frustum rectangle that preserves the scene's size relative to the viewport when the viewport width and
    // height are swapped. This has the effect of maintaining the scene's size on screen when the device is rotated.

    CGFloat x, y, width, height;

    if (viewportWidth < viewportHeight)
    {
        width = (CGFloat) near;
        height = (CGFloat) near * viewportHeight / viewportWidth;
        x = -width / 2;
        y = -height / 2;
    }
    else
    {
        width = (CGFloat) near * viewportWidth / viewportHeight;
        height = (CGFloat) near;
        x = -width / 2;
        y = -height / 2;
    }

    return CGRectMake(x, y, width, height);
}

+ (double) perspectivePixelSize:(CGRect)viewport atDistance:(double)distance
{
    if (CGRectGetWidth(viewport) == 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Viewport width is zero")
    }

    if (CGRectGetHeight(viewport) == 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Viewport height is zero")
    }

    // Compute the dimensions of a rectangle in model coordinates carved out of the frustum at the given distance along
    // the negative z axis, also in model coordinates.
    CGRect frustRect = [WWMath perspectiveFrustumRect:viewport atDistance:distance];

    // Compute the pixel size in model coordinates as a ratio of the rectangle dimensions to the viewport dimensions.
    // The resultant units are model coordinates per pixel (usually meters per pixel).
    CGFloat xPixelSize = CGRectGetWidth(frustRect) / CGRectGetWidth(viewport);
    CGFloat yPixelSize = CGRectGetHeight(frustRect) / CGRectGetHeight(viewport);

    // Return the maximum of the x and y pixel sizes. These two sizes are usually equivalent but we select the maximum
    // in order to correctly handle the case where the x and y pixel sizes differ.
    return MAX(xPixelSize, yPixelSize);
}

+ (double) perspectiveFitDistance:(CGRect)viewport forObjectWithRadius:(double)radius
{
    if (CGRectGetWidth(viewport) == 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Viewport width is zero")
    }

    if (CGRectGetHeight(viewport) == 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Viewport height is zero")
    }

    if (radius < 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Radius is negative")
    }

    // The distance needed to fill the smaller of either frustum dimensions with an object of a specified radius is
    // always half the object's radius. Though this this method is trivial, it provides a layer of indirection for the
    // details of the perspective projections used by World Wind. This indirection makes it simple to add a field of
    // view to perspective projections without identifying inline computations based on assumptions of how perspective
    // projections worked prior to adding field of view.

    return radius * 2;
}

+ (double) perspectiveFitDistance:(CGRect)viewport
                     forPositionA:(WWPosition*)posA
                        positionB:(WWPosition*)posB
                          onGlobe:(WWGlobe*)globe
{
    if (CGRectGetWidth(viewport) == 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Viewport width is zero")
    }

    if (CGRectGetHeight(viewport) == 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Viewport height is zero")
    }

    if (posA == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Position A is nil")
    }

    if (posB == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Position B is nil")
    }

    if (globe == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Globe is nil")
    }

    WWVec4* pa = [[WWVec4 alloc] initWithZeroVector];
    WWVec4* pb = [[WWVec4 alloc] initWithZeroVector];
    [globe computePointFromPosition:[posA latitude] longitude:[posA longitude] altitude:[posA altitude] outputPoint:pa];
    [globe computePointFromPosition:[posB latitude] longitude:[posB longitude] altitude:[posB altitude] outputPoint:pb];

    double radius = [pa distanceTo3:pb] / 2;

    return [WWMath perspectiveFitDistance:viewport forObjectWithRadius:radius];
}

+ (double) perspectiveNearDistance:(CGRect)viewport forObjectAtDistance:(double)distance
{
    CGFloat viewportWidth = CGRectGetWidth(viewport);
    CGFloat viewportHeight = CGRectGetHeight(viewport);

    if (viewportWidth == 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Viewport width is zero")
    }

    if (viewportHeight == 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Viewport height is zero")
    }

    // Compute the maximum near clip distance that avoids clipping an object at the specified distance from the eye.
    // Since the furthest points on the near clip rectangle are the four corners, we compute a near distance that puts
    // any one of these corners exactly at the given distance. The distance to one of the four corners can be expressed
    // in terms of the near clip distance, given distance to a corner 'd', near distance 'n', and aspect ratio 'a':
    //
    // d*d = x*x + y*y + z*z
    // d*d = (n*n/4 * a*a) + (n*n/4) + (n*n)
    //
    // Extracting 'n*n/4' from the right hand side gives:
    //
    // d*d = (n*n/4) * (a*a + 1 + 4)
    // d*d = (n*n/4) * (a*a + 5)
    //
    // Finally, solving for 'n' gives:
    //
    // n*n = 4 * d*d / (a*a + 5)
    // n = 2 * d / sqrt(a*a + 5)

    CGFloat aspect = (viewportWidth < viewportHeight)
            ? (viewportHeight / viewportWidth) : (viewportWidth / viewportHeight);

    return 2 * distance / sqrt(aspect * aspect + 5);
}

+ (BOOL) computeTriangleIntersection:(WWLine*)line
                                 vax:(double)vax
                                 vay:(double)vay
                                 vaz:(double)vaz
                                 vbx:(double)vbx
                                 vby:(double)vby
                                 vbz:(double)vbz
                                 vcx:(double)vcx
                                 vcy:(double)vcy
                                 vcz:(double)vcz
                              result:(WWVec4*)result
{
    // Taken from Moller and Trumbore
    // http://www.cs.virginia.edu/~gfx/Courses/2003/ImageSynthesis/papers/Acceleration/
    // Fast%20MinimumStorage%20RayTriangle%20Intersection.pdf

    static double EPSILON = 0.00001;

    WWVec4* origin = [line origin];
    WWVec4* dir = [line direction];

    // find vectors for two edges sharing point a: vb - va and vc - va
    double edge1x = vbx - vax;
    double edge1y = vby - vay;
    double edge1z = vbz - vaz;

    double edge2x = vcx - vax;
    double edge2y = vcy - vay;
    double edge2z = vcz - vaz;

    // Compute cross product of line direction and edge2
    double pvecx = ([dir y] * edge2z) - ([dir z] * edge2y);
    double pvecy = ([dir z] * edge2x) - ([dir x] * edge2z);
    double pvecz = ([dir x] * edge2y) - ([dir y] * edge2x);

    // Get determinant
    double det = edge1x * pvecx + edge1y * pvecy + edge1z * pvecz; // edge1 dot pvec
    if (det > -EPSILON && det < EPSILON) // if det is near zero then ray lies in plane of triangle
    {
        return NO;
    }

    double detInv = 1.0 / det;

    // Compute distance for vertex A to ray origin: origin - va
    double tvecx = [origin x] - vax;
    double tvecy = [origin y] - vay;
    double tvecz = [origin z] - vaz;

    // Calculate u parameter and test bounds: 1/det * tvec dot pvec
    double u = detInv * (tvecx * pvecx + tvecy * pvecy + tvecz * pvecz);
    if (u < 0 || u > 1)
    {
        return NO;
    }

    // Prepare to test v parameter: tvec cross edge1
    double qvecx = (tvecy * edge1z) - (tvecz * edge1y);
    double qvecy = (tvecz * edge1x) - (tvecx * edge1z);
    double qvecz = (tvecx * edge1y) - (tvecy * edge1x);

    // Calculate v parameter and test bounds: 1/det * dir dot qvec
    double v = detInv * ([dir x] * qvecx + [dir y] * qvecy + [dir z] * qvecz);
    if (v < 0 || u + v > 1)
    {
        return NO;
    }

    // Calculate the point of intersection on the line: t = 1/det * edge2 dot qvec
    double t = detInv * (edge2x * qvecx + edge2y * qvecy + edge2z * qvecz);
    if (t < 0)
    {
        return NO;
    }

    [line pointAt:t result:result];

    return YES;
}

@end