/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "WorldWind/Navigate/WWBasicNavigatorState.h"
#import "WorldWind/Geometry/WWMatrix.h"
#import "WorldWind/Geometry/WWVec4.h"
#import "WorldWind/Geometry/WWFrustum.h"
#import "WorldWind/WWLog.h"

@implementation WWBasicNavigatorState
{
    WWMatrix* modelviewInv;
    WWMatrix* projectionInv;
    WWMatrix* modelviewProjectionInv;

    double pixelSizeScale;
    double pixelSizeOffset;
}

- (WWBasicNavigatorState*) initWithModelview:(WWMatrix*)modelviewMatrix projection:(WWMatrix*)projectionMatrix viewport:(CGRect)viewport;
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

    if (self != nil)
    {
        _modelview = [[WWMatrix alloc] initWithMatrix:modelviewMatrix];
        _projection = [[WWMatrix alloc] initWithMatrix:projectionMatrix];
        _modelviewProjection = [[WWMatrix alloc] initWithMultiply:projectionMatrix matrixB:modelviewMatrix];
        _viewport = viewport;

        // Compute the inverse of the modelview, projection, and modelview-projection matrices. These inverses are used
        // to support operations on navigator state, such as project, unProject, and pixelSizeAtDistance.
        self->modelviewInv = [[WWMatrix alloc] initWithTransformInverse:_modelview];
        self->projectionInv = [[WWMatrix alloc] initWithInverse:_projection];
        self->modelviewProjectionInv = [[WWMatrix alloc] initWithInverse:_modelviewProjection];

        // Compute the eye point in model coordinates. The eye point is computed by multiplying (0, 0, 0, 1) by the
        // inverse of the modelview matrix. We have pre-computed the result and stored it inline here to avoid an
        // unnecessary matrix multiplication.
        double* mvi = self->modelviewInv->m;
        _eyePoint = [[WWVec4 alloc] initWithCoordinates:mvi[3] y:mvi[7] z:mvi[11]];

        // Extract the frustum in eye coordinates from the projection matrix. Transform the frustum to model coordinates
        // by multiplying its planes by the transpose of the modelview matrix.
        WWMatrix* modelviewTranspose = [[WWMatrix alloc] initWithTranspose:_modelview];
        _frustum = [projectionMatrix extractFrustum]; // returns normalized frustum plane vectors
        _frustumInModelCoordinates = [[WWFrustum alloc] initWithTransformedFrustum:_frustum matrix:modelviewTranspose];
        [_frustumInModelCoordinates normalize]; // re-normalize after transforming the frustum plane vectors.

        // Compute the eye coordinate rectangles carved out of the frustum by the near and far clipping planes, and
        // the distance between those planes and the eye point along the -Z axis. The rectangles are determined by
        // transforming the bottom-left and top-right points of the frustum from homogeneous clip coordinates to eye
        // coordinates.
        WWVec4* nbl = [[[WWVec4 alloc] initWithCoordinates:-1 y:-1 z:-1] multiplyByMatrix:self->projectionInv];
        WWVec4* ntr = [[[WWVec4 alloc] initWithCoordinates:1 y:1 z:-1] multiplyByMatrix:self->projectionInv];
        WWVec4* fbl = [[[WWVec4 alloc] initWithCoordinates:-1 y:-1 z:1] multiplyByMatrix:self->projectionInv];
        WWVec4* ftr = [[[WWVec4 alloc] initWithCoordinates:1 y:1 z:1] multiplyByMatrix:self->projectionInv];
        [nbl divideByScalar:nbl.w]; // Divide by the W coordinate to convert homogeneous clip coordinates to eye coordinates.
        [ntr divideByScalar:ntr.w];
        [fbl divideByScalar:fbl.w];
        [ftr divideByScalar:ftr.w];
        double nearRectWidth = fabs(ntr.x - nbl.x);
        double farRectWidth = fabs(ftr.x - fbl.x);
        double nearDistance = -nbl.z; // Projection matrices invert the Z axis.
        double farDistance = -fbl.z;

        // Compute the scale and offset used to determine the width of a pixel on a rectangle carved out of the frustum
        // at a distance along the -Z axis in eye coordinates. These values are found by computing the scale and offset
        // of a frustum rectangle at a given distance, then dividing each by the viewport width.
        double frustumWidthScale = (farRectWidth - nearRectWidth) / (farDistance - nearDistance);
        double frustumWidthOffset = nearRectWidth - frustumWidthScale * nearDistance;
        self->pixelSizeScale = frustumWidthScale / CGRectGetWidth(_viewport);
        self->pixelSizeOffset = frustumWidthOffset / CGRectGetWidth(_viewport);
    }

    return self;
}

// TODO: Determine if this alternate method can be removed.
//- (WWBasicNavigatorState*) initWithModelview:(WWMatrix*)modelviewMatrix projection:(WWMatrix*)projectionMatrix
//                                    viewport:(CGRect)viewport
//                                nearDistance:(double)nearDistance
//                                 farDistance:(double)farDistance
//{
//    if (modelviewMatrix == nil)
//    {
//        WWLOG_AND_THROW(NSInvalidArgumentException, @"Modelview matrix is nil");
//    }
//
//    if (projectionMatrix == nil)
//    {
//        WWLOG_AND_THROW(NSInvalidArgumentException, @"Projection matrix is nil");
//    }
//
//    self = [super init];
//
//    _modelview = [[WWMatrix alloc] initWithMatrix:modelviewMatrix];
//    _projection = [[WWMatrix alloc] initWithMatrix:projectionMatrix];
//    _modelviewProjection = [[WWMatrix alloc] initWithMultiply:projectionMatrix matrixB:modelviewMatrix];
//
//    // The eye point is computed by transforming the origin by the inverse of the modelview matrix.
//    WWMatrix* invModelview = [[WWMatrix alloc] initWithInverse:_modelview];
//    _eyePoint = [[WWVec4 alloc] initWithZeroVector];
//    [invModelview multiplyVector:_eyePoint];
//
//    _frustum = [projectionMatrix extractFrustum]; // returns normalized frustum plane vectors
//    WWFrustum* oldFrustum = [[WWFrustum alloc] initWithViewportWidth:CGRectGetWidth(viewport)
//                                                      viewportHeight:CGRectGetHeight(viewport)
//                                                        nearDistance:nearDistance
//                                                         farDistance:farDistance];
//    _frustum = oldFrustum;
//
//    // The model-coordinate frustum is computed by transforming the frustum by the transpose of the modelview matrix.
//    WWMatrix* modelviewTranspose = [[WWMatrix alloc] initWithTranspose:_modelview];
//    _frustumInModelCoordinates = [[WWFrustum alloc] initWithTransformedFrustum:_frustum matrix:modelviewTranspose];
//    // TODO: Should the MC frustum plane vectors be normalized after applying the transform?
//
//    return self;
//}

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

    return self->pixelSizeScale * distance + self->pixelSizeOffset;
}

@end
