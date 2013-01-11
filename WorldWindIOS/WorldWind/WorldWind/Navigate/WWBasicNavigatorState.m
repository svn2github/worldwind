/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "WorldWind/Navigate/WWBasicNavigatorState.h"
#import "WorldWind/Geometry/WWMatrix.h"
#import "WorldWind/Geometry/WWVec4.h"
#import "WorldWind/WWLog.h"

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

    _modelview = [[WWMatrix alloc] initWithMatrix:modelviewMatrix];
    _projection = [[WWMatrix alloc] initWithMatrix:projectionMatrix];
    _modelviewProjection = [[WWMatrix alloc] initWithMultiply:projectionMatrix matrixB:modelviewMatrix];

    // The eye point is computed by transforming the origin by the inverse of the modelview matrix.
    WWMatrix* invModelview = [[WWMatrix alloc] initWithInverse:_modelview];
    _eyePoint = [invModelview multiplyVector:[[WWVec4 alloc] initWithZeroVector]];

    return self;
}

@end
