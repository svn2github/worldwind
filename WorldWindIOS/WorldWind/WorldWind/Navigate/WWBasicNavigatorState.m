/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "WorldWind/Navigate/WWBasicNavigatorState.h"
#import "WorldWind/Geometry/WWMatrix.h"
#import "WorldWind/Geometry/WWVec4.h"
#import "WorldWind/WWLog.h"
#import "WorldWind/Geometry/WWFrustum.h"

@implementation WWBasicNavigatorState

- (WWBasicNavigatorState*) initWithModelview:(WWMatrix*)modelviewMatrix projection:(WWMatrix*)projectionMatrix
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

        // The eye point is computed by transforming the origin by the inverse of the modelview matrix.
        WWMatrix* invModelview = [[WWMatrix alloc] initWithInverse:_modelview];
        _eyePoint = [[WWVec4 alloc] initWithZeroVector];
        [invModelview multiplyVector:_eyePoint];

        _frustum = [projectionMatrix extractFrustum]; // returns normalized frustum plane vectors

        // The model-coordinate frustum is computed by transforming the frustum by the transpose of the modelview matrix.
        WWMatrix* modelviewTranspose = [[WWMatrix alloc] initWithTranspose:_modelview];
        _frustumInModelCoordinates = [[WWFrustum alloc] initWithTransformedFrustum:_frustum matrix:modelviewTranspose];
        [_frustumInModelCoordinates normalize];
    }

    return self;
}
//
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

@end
