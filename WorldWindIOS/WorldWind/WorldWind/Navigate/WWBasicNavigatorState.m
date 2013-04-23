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
#import "WorldWind/WWLog.h"

@implementation WWBasicNavigatorState

- (WWBasicNavigatorState*) initWithModelview:(WWMatrix*)modelviewMatrix
                                  projection:(WWMatrix*)projectionMatrix
                                    viewport:(CGRect)viewport;
{
    if (modelviewMatrix == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Modelview matrix is nil");
    }

    if (projectionMatrix == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Projection matrix is nil");
    }

    self = [super init];

    // Store the modelview, projection, and modelview-projection matrices and
    _modelview = modelviewMatrix;
    _projection = projectionMatrix;
    _modelviewProjection = [[WWMatrix alloc] initWithMultiply:projectionMatrix matrixB:modelviewMatrix];
    _viewport = viewport;

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
    // transforming the bottom-left and top-right points of the frustum from homogeneous clip coordinates to eye
    // coordinates.
    WWVec4* nbl = [[[WWVec4 alloc] initWithCoordinates:-1 y:-1 z:-1] multiplyByMatrix:projectionInv];
    WWVec4* ntr = [[[WWVec4 alloc] initWithCoordinates:+1 y:+1 z:-1] multiplyByMatrix:projectionInv];
    WWVec4* fbl = [[[WWVec4 alloc] initWithCoordinates:-1 y:-1 z:+1] multiplyByMatrix:projectionInv];
    WWVec4* ftr = [[[WWVec4 alloc] initWithCoordinates:+1 y:+1 z:+1] multiplyByMatrix:projectionInv];
    [nbl divideByScalar:[nbl w]]; // Divide by the W coordinate to convert homogeneous clip coordinates to eye coordinates.
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

- (BOOL) project:(WWVec4*)modelPoint result:(WWVec4*)screenPoint
{
    if (modelPoint == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Model point is nil");
    }

    if (screenPoint == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Screen point is nil");
    }

    // TODO: Return NO if the modelPoint is behind the eye.

    // Multiply the model point by the combined modelview-projection matrix. This has the effect of transforming the
    // point from model coordinates to eye coordinates, then to clip coordinates. Additionally, this inverts the Z axis
    // and stores the negative of the eye coordinate Z value in the W coordinate.
    [screenPoint set:modelPoint];
    [screenPoint setW:1]; // Fourth column of modelview projection must be multiplied by 1.
    [screenPoint multiplyByMatrix:_modelviewProjection];

    double x = [screenPoint x];
    double y = [screenPoint y];
    double z = [screenPoint z];
    double w = [screenPoint w];

    if (w == 0)
    {
        return NO;
    }

    // Complete the conversion from model coordinates to clip coordinates by dividing by the W coordinate.
    x /= w;
    y /= w;
    z /= w;
    w /= w;

    // Convert the point from clip coordinates to the range [0, 1]. This enables the XY coordinates to be converted to
    // screen coordinates, and the Z coordinate to represent a depth value in the range [0, 1].
    x = x * 0.5 + 0.5;
    y = y * 0.5 + 0.5;
    z = z * 0.5 + 0.5;

    // Convert the XY coordinates from coordinates in the range [0, 1] to screen coordinates.
    x = x * CGRectGetWidth(_viewport) + CGRectGetMinX(_viewport);
    y = y * CGRectGetHeight(_viewport) + CGRectGetMinY(_viewport);

    [screenPoint set:x y:y z:z w:w];

    return YES;
}

- (BOOL) unProject:(WWVec4*)screenPoint result:(WWVec4*)modelPoint
{
    if (screenPoint == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Screen point is nil");
    }

    if (modelPoint == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Model point is nil");
    }

    // TODO: Return NO if the screenPoint is behind the eye.

    double x = [screenPoint x];
    double y = [screenPoint y];
    double z = [screenPoint z];

    // Convert the XY coordinates screen coordinates to coordinates in the range [0, 1]. This enables the XY coordinates
    // to be converted to clip coordinates in the range [-1, 1].
    x = (x - CGRectGetMinX(_viewport)) / CGRectGetWidth(_viewport);
    y = (y - CGRectGetMinY(_viewport)) / CGRectGetHeight(_viewport);

    // Convert from coordinates in the range [0, 1] to clip coordinates in the range [-1, 1].
    x = x * 2 - 1;
    y = y * 2 - 1;
    z = z * 2 - 1;

    // Multiply the point in clip coordinates by the inverse of the combined modelview-projection matrix. This has the
    // effect of transforming the point from clip coordinates to eye coordinates, then to model coordinates.
    // Additionally, this inverts the Z axis and stores the negative of the eye coordinate Z value in the W coordinate.
    [modelPoint set:x y:y z:z w:1]; // Fourth column of modelview projection must be multiplied by 1.
    [modelPoint multiplyByMatrix:modelviewProjectionInv];

    double w = [modelPoint w];
    if (w == 0)
    {
        return NO;
    }

    // Complete the conversion from clip coordinate to model coordinates by dividing by the W coordinate.
    [modelPoint divideByScalar:w];

    return YES;
}

- (WWLine*) rayFromScreenPoint:(double)x y:(double)y
{
    WWVec4* screenPoint = [[WWVec4 alloc] initWithZeroVector];

    [screenPoint set:x y:y z:0];
    WWVec4* nearPoint = [[WWVec4 alloc] initWithZeroVector];
    if (![self unProject:screenPoint result:nearPoint])
    {
        return nil;
    }

    [screenPoint set:x y:y z:1];
    WWVec4* farPoint = [[WWVec4 alloc] initWithZeroVector];
    if (![self unProject:screenPoint result:farPoint])
    {
        return nil;
    }

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