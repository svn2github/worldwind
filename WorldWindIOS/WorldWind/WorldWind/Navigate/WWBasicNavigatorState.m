/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "WorldWind/Navigate/WWBasicNavigatorState.h"
#import "Worldwind/Geometry/WWLine.h"
#import "WorldWind/Geometry/WWMatrix.h"
#import "WorldWind/Geometry/WWVec4.h"
#import "WorldWind/Geometry/WWFrustum.h"
#import "WorldWind/Util/WWMath.h"
#import "WorldWind/WorldWindView.h"
#import "WorldWind/WWLog.h"

@implementation WWBasicNavigatorState

- (WWBasicNavigatorState*) initWithModelview:(WWMatrix*)modelviewMatrix
                                  projection:(WWMatrix*)projectionMatrix
                                        view:(WorldWindView*)view
                                     heading:(double)heading
                                        tilt:(double)tilt
{
    if (modelviewMatrix == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Modelview matrix is nil");
    }

    if (projectionMatrix == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Projection matrix is nil");
    }

    if (view == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"View is nil")
    }

    self = [super init];

    // Store the modelview, projection, and modelview-projection matrices and
    _modelview = modelviewMatrix;
    _projection = projectionMatrix;
    _modelviewProjection = [[WWMatrix alloc] initWithMultiply:projectionMatrix matrixB:modelviewMatrix];
    _viewport = [view viewport];
    viewBounds = [view bounds];
    _heading = heading;
    _tilt = tilt;

    // Compute the eye point and forward ray in model coordinates.
    _eyePoint = [_modelview extractEyePoint];
    _forward = [_modelview extractForwardVector];
    _forwardRay = [[WWLine alloc] initWithOrigin:_eyePoint direction:_forward];

    // Compute the frustum in model coordinates. Start by computing the frustum in eye coordinates from the projection
    // matrix, then transform this frustum to model coordinates by multiplying its planes by the transpose of the
    // modelview matrix. We use the transpose of the modelview matrix because planes are transformed by the inverse
    // transpose of a matrix, and we want to transform from eye coordinates to model coordinates.
    WWMatrix* modelviewTranspose = [[WWMatrix alloc] initWithTranspose:_modelview];
    _frustumInModelCoordinates = [projectionMatrix extractFrustum]; // returns normalized frustum plane vectors
    [_frustumInModelCoordinates transformByMatrix:modelviewTranspose];
    [_frustumInModelCoordinates normalize]; // re-normalize after transforming the frustum plane vectors.

    // Compute the inverse of the modelview, projection, and modelview-projection matrices. The inverse matrices are
    // used to support operations on navigator state, such as project, unProject, and pixelSizeAtDistance.
    modelviewInv = [[WWMatrix alloc] initWithTransformInverse:_modelview];
    projectionInv = [[WWMatrix alloc] initWithInverse:_projection];
    modelviewProjectionInv = [[WWMatrix alloc] initWithInverse:_modelviewProjection];

    // Compute the eye coordinate rectangles carved out of the frustum by the near and far clipping planes, and
    // the distance between those planes and the eye point along the -Z axis. The rectangles are determined by
    // transforming the bottom-left and top-right points of the frustum from clip coordinates to eye coordinates.
    WWVec4* nbl = [[WWVec4 alloc] initWithCoordinates:-1 y:-1 z:-1];
    WWVec4* ntr = [[WWVec4 alloc] initWithCoordinates:+1 y:+1 z:-1];
    WWVec4* fbl = [[WWVec4 alloc] initWithCoordinates:-1 y:-1 z:+1];
    WWVec4* ftr = [[WWVec4 alloc] initWithCoordinates:+1 y:+1 z:+1];
    // Convert each frustum corner from clip coordinates to eye coordinates by multiplying by the inverse projection
    // matrix.
    [nbl multiplyByMatrix:projectionInv];
    [ntr multiplyByMatrix:projectionInv];
    [fbl multiplyByMatrix:projectionInv];
    [ftr multiplyByMatrix:projectionInv];
    // Divide by the W coordinate to complete the conversion from clip coordinates to eye coordinates.
    [nbl divideByScalar:[nbl w]];
    [ntr divideByScalar:[ntr w]];
    [fbl divideByScalar:[fbl w]];
    [ftr divideByScalar:[ftr w]];
    double nrRectWidth = fabs(ntr.x - nbl.x);
    double frRectWidth = fabs(ftr.x - fbl.x);
    double nrDistance = -nbl.z; // Projection matrices invert the Z axis.
    double frDistance = -fbl.z;

    // Compute the scale and offset used to determine the width of a pixel on a rectangle carved out of the frustum
    // at a distance along the -Z axis in eye coordinates. These values are found by computing the scale and offset
    // of a frustum rectangle at a given distance, then dividing each by the viewport width.
    double frustumWidthScale = (frRectWidth - nrRectWidth) / (frDistance - nrDistance);
    double frustumWidthOffset = nrRectWidth - frustumWidthScale * nrDistance;
    pixelSizeScale = frustumWidthScale / CGRectGetWidth(_viewport);
    pixelSizeOffset = frustumWidthOffset / CGRectGetWidth(_viewport);

    return self;
}

- (BOOL) project:(WWVec4* __unsafe_unretained)modelPoint result:(WWVec4* __unsafe_unretained)screenPoint
{
    if (modelPoint == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Model point is nil");
    }

    if (screenPoint == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Screen point is nil");
    }

    double mx = [modelPoint x];
    double my = [modelPoint y];
    double mz = [modelPoint z];

    // Transform the model point from model coordinates to eye coordinates, then to clip coordinates. This inverts the Z
    // axis and stores the negative of the eye coordinate Z value in the W coordinate. We inline the computation here
    // instead of using [WWVec4 multiplyByMatrix:] in order to improve performance.
    double* m = _modelviewProjection->m;
    double x = m[0] * mx + m[1] * my + m[2] * mz + m[3];
    double y = m[4] * mx + m[5] * my + m[6] * mz + m[7];
    double z = m[8] * mx + m[9] * my + m[10] * mz + m[11];
    double w = m[12] * mx + m[13] * my + m[14] * mz + m[15];

    if (w == 0)
    {
        return NO;
    }

    // Complete the conversion from model coordinates to clip coordinates by dividing by the W coordinate. The resultant
    // X Y and Z coordinates are in the range [-1, 1].
    x /= w;
    y /= w;
    z /= w;

    // Clip the point against the near and far clip planes. In clip coordinates the near and far clip planes are
    // perpendicular to the Z axis and are located at -1 and 1, respectively.
    if (z < -1 || z > 1)
    {
        return NO;
    }

    // Convert the point from clip coordinates to the range [0, 1]. This enables the XY coordinates to be converted to
    // screen coordinates, and the Z coordinate to represent a depth value in the range [0, 1].
    x = x * 0.5 + 0.5;
    y = y * 0.5 + 0.5;
    z = z * 0.5 + 0.5;

    // Convert the XY coordinates from coordinates in the range [0, 1] to screen coordinates.
    x = x * CGRectGetWidth(_viewport) + CGRectGetMinX(_viewport);
    y = y * CGRectGetHeight(_viewport) + CGRectGetMinY(_viewport);

    [screenPoint set:x y:y z:z];

    return YES;
}

- (BOOL) project:(WWVec4* __unsafe_unretained)modelPoint result:(WWVec4* __unsafe_unretained)screenPoint depthOffset:(double)depthOffset
{
    if (modelPoint == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Model point is nil");
    }

    if (screenPoint == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Screen point is nil");
    }

    double mx = [modelPoint x];
    double my = [modelPoint y];
    double mz = [modelPoint z];

    // Transform the model point from model coordinates to eye coordinates. We inline the computation here instead of
    // using [WWVec4 multiplyByMatrix:] in order to improve performance. The eye coordinate and clip coordinate are
    // computed separately in order to reuse the eye coordinate below.
    double* mv = _modelview->m;
    double ex = mv[0] * mx + mv[1] * my + mv[2] * mz + mv[3];
    double ey = mv[4] * mx + mv[5] * my + mv[6] * mz + mv[7];
    double ez = mv[8] * mx + mv[9] * my + mv[10] * mz + mv[11];
    double ew = mv[12] * mx + mv[13] * my + mv[14] * mz + mv[15];

    // Transform the model point from eye coordinates to clip coordinates. This inverts the Z axis and stores the
    // negative of the eye coordinate Z value in the W coordinate. We inline the computation here instead of using
    // [WWVec4 multiplyByMatrix:] in order to improve performance.
    double* pr = _projection->m;
    double x = pr[0] * ex + pr[1] * ey + pr[2] * ez + pr[3] * ew;
    double y = pr[4] * ex + pr[5] * ey + pr[6] * ez + pr[7] * ew;
    double z = pr[8] * ex + pr[9] * ey + pr[10] * ez + pr[11] * ew;
    double w = pr[12] * ex + pr[13] * ey + pr[14] * ez + pr[15] * ew;

    if (w == 0)
    {
        return NO;
    }

    // Complete the conversion from model coordinates to clip coordinates by dividing by the W coordinate. The resultant
    // X Y and Z coordinates are in the range [-1, 1].
    x /= w;
    y /= w;
    z /= w;

    // Clip the point against the near and far clip planes. In clip coordinates the near and far clip planes are
    // perpendicular to the Z axis and are located at -1 and 1, respectively.
    if (z < -1 || z > 1)
    {
        return NO;
    }

    // Transform the Z eye coordinate to clip coordinates again, this time applying a depth offset. The depth offset is
    // applied only to the matrix element affecting the projected Z coordinate, so we inline the computation here
    // instead of re-computing X, Y, Z and W in order to improve performance. See [WWMatrix offsetProjectionDepth:] for
    // more information on the effect of this offset.
    z = pr[8] * ex + pr[9] * ey + pr[10] * ez * (1 + depthOffset) + pr[11] * ew;
    z /= w;

    // Clamp the point to the near and far clip planes. We know the point's original Z value is contained within the
    // clip planes, so we limit its offset z value to the range [-1, 1] in order to ensure it is not clipped by OpenGL.
    // In clip coordinates the near and far clip planes are perpendicular to the Z axis and are located at -1 and 1,
    // respectively.
    z = WWCLAMP(z, -1, 1);

    // Convert the point from clip coordinates to the range [0, 1]. This enables the XY coordinates to be converted to
    // screen coordinates, and the Z coordinate to represent a depth value in the range [0, 1].
    x = x * 0.5 + 0.5;
    y = y * 0.5 + 0.5;
    z = z * 0.5 + 0.5;

    // Convert the XY coordinates from coordinates in the range [0, 1] to screen coordinates.
    x = x * CGRectGetWidth(_viewport) + CGRectGetMinX(_viewport);
    y = y * CGRectGetHeight(_viewport) + CGRectGetMinY(_viewport);

    [screenPoint set:x y:y z:z];

    return YES;
}

- (BOOL) unProject:(WWVec4* __unsafe_unretained)screenPoint result:(WWVec4* __unsafe_unretained)modelPoint
{
    if (screenPoint == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Screen point is nil");
    }

    if (modelPoint == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Model point is nil");
    }

    double sx = [screenPoint x];
    double sy = [screenPoint y];
    double sz = [screenPoint z];

    // Convert the XY screen coordinates to coordinates in the range [0, 1]. This enables the XY coordinates to be
    // converted to clip coordinates.
    sx = (sx - CGRectGetMinX(_viewport)) / CGRectGetWidth(_viewport);
    sy = (sy - CGRectGetMinY(_viewport)) / CGRectGetHeight(_viewport);

    // Convert from coordinates in the range [0, 1] to clip coordinates in the range [-1, 1].
    sx = sx * 2 - 1;
    sy = sy * 2 - 1;
    sz = sz * 2 - 1;

    // Clip the point against the near and far clip planes. In clip coordinates the near and far clip planes are
    // perpendicular to the Z axis and are located at -1 and 1, respectively.
    if (sz < -1 || sz > 1)
    {
        return NO;
    }

    // Transform the screen point from clip coordinates to eye coordinates, then to model coordinates. This inverts the
    // Z axis and stores the  negative of the eye coordinate Z value in the W coordinate. We inline the computation here
    // instead of using  [WWVec4 multiplyByMatrix:] in order to improve performance.
    double* m = modelviewProjectionInv->m;
    double x = m[0] * sx + m[1] * sy + m[2] * sz + m[3];
    double y = m[4] * sx + m[5] * sy + m[6] * sz + m[7];
    double z = m[8] * sx + m[9] * sy + m[10] * sz + m[11];
    double w = m[12] * sx + m[13] * sy + m[14] * sz + m[15];

    if (w == 0)
    {
        return NO;
    }

    // Complete the conversion from clip coordinates to model coordinates by dividing by the W coordinate.
    x /= w;
    y /= w;
    z /= w;
    
    [modelPoint set:x y:y z:z];

    return YES;
}

- (CGPoint) convertPointToView:(WWVec4*)screenPoint
{
    if (screenPoint == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Screen point is nil")
    }

    double x = [screenPoint x];
    double y = [screenPoint y];

    // Convert the point form OpenGL screen coordinates to normalized coordinates in the range [0, 1].
    x = (x - CGRectGetMinX(_viewport)) / CGRectGetWidth(_viewport);
    y = (y - CGRectGetMinY(_viewport)) / CGRectGetHeight(_viewport);

    // Transform the origin from the bottom-left corner to the top-left corner.
    y = 1 - y;

    // Convert the point from normalized coordinates in the range [0, 1] to UIKit coordinates.
    x = x * CGRectGetWidth(viewBounds) + CGRectGetMinX(viewBounds);
    y = y * CGRectGetHeight(viewBounds) + CGRectGetMinY(viewBounds);

    return CGPointMake((CGFloat) x, (CGFloat) y);
}

- (WWVec4*) convertPointToViewport:(CGPoint)point
{
    double x = point.x;
    double y = point.y;

    // Convert the point from UIKit coordinates to normalized coordinates in the range [0, 1].
    x = (x - CGRectGetMinX(viewBounds)) / CGRectGetWidth(viewBounds);
    y = (y - CGRectGetMinY(viewBounds)) / CGRectGetHeight(viewBounds);

    // Transform the origin from the top-left corner to the bottom-left corner.
    y = 1 - y;

    // Convert the point from normalized coordinates in the range [0, 1] to OpenGL screen coordinates.
    x = x * CGRectGetWidth(_viewport) + CGRectGetMinX(_viewport);
    y = y * CGRectGetHeight(_viewport) + CGRectGetMinY(_viewport);

    return [[WWVec4 alloc] initWithCoordinates:x y:y z:0];
}

- (WWLine*) rayFromScreenPoint:(CGPoint)point
{
    // Convert the point's xy coordinates from UIKit coordinates to OpenGL coordinates.
    WWVec4* screenPoint = [self convertPointToViewport:point];

    // Compute the model coordinate point on the near clip plane with the xy coordinates and depth 0.
    [screenPoint setZ:0];
    WWVec4* nearPoint = [[WWVec4 alloc] initWithZeroVector];
    if (![self unProject:screenPoint result:nearPoint])
    {
        return nil;
    }

    // Compute the model coordinate point on the far clip plane with the xy coordinates and depth 1.
    [screenPoint setZ:1];
    WWVec4* farPoint = [[WWVec4 alloc] initWithZeroVector];
    if (![self unProject:screenPoint result:farPoint])
    {
        return nil;
    }

    // Compute a ray originating at the eye point and with direction pointing from the xy coordinate on the near plane
    // to the same xy coordinate on the far plane.
    WWVec4* origin = [[WWVec4 alloc] initWithVector:_eyePoint];
    WWVec4* direction = [[WWVec4 alloc] initWithZeroVector];
    [direction set:farPoint];
    [direction subtract3:nearPoint];
    [direction normalize3];

    return [[WWLine alloc] initWithOrigin:origin direction:direction];
}

- (double) pixelSizeAtDistance:(double)distance
{
    // Compute the pixel size from the width of a rectangle in carved out of the frustum in model coordinates at the
    // specified distance along the -Z axis and the viewport width in screen coordinates. The pixel size is expressed
    // in model coordinates per screen coordinate (e.g. meters per pixel).
    //
    // The frustum width is determined by noticing that the frustum size is a linear function of distance from the eye
    // point. The linear equation constants are determined during initialization, then solved for distance here.
    //
    // This considers only the frustum width by assuming that the frustum and viewport share the same aspect ratio, so
    // that using either the frustum width or height results in the same pixel size.

    return pixelSizeScale * distance + pixelSizeOffset;
}

@end