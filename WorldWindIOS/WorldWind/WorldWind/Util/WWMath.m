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

double NormalizedDegreesLatitude(double degrees)
{
    double lat = fmod(degrees, 180);
    return lat > 90 ? 180 - lat : lat < -90 ? -180 - lat : lat;
}

double NormalizedDegreesLongitude(double degrees)
{
    double lon = fmod(degrees, 360);
    return lon > 180 ? lon - 360 : lon < -180 ? 360 + lon : lon;
}

double NormalizedDegreesHeading(double degrees)
{
    double angle = fmod(degrees, 360);
    return angle > 180 ? angle - 360 : angle < -180 ? 360 + angle : angle;
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
    // The form for interpolation below a + t*(b-a) requires one fewer operation than the standard form of
    // (1-t)*a + t*b. Since both forms are straightforward to implement and understand, we have used the somewhat more
    // efficient form below.

    return value1 + amount * (value2 - value1);
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

@end