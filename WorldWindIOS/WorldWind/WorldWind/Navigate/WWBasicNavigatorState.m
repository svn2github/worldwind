/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "WorldWind/Navigate/WWBasicNavigatorState.h"
#import "WorldWind/Geometry/WWMatrix.h"

@implementation WWBasicNavigatorState

- (WWBasicNavigatorState*) initWithModelview:(WWMatrix*)modelviewMatrix projection:(WWMatrix*)projectionMatrix
{
    self = [super init];

    self->modelview = [[WWMatrix alloc] initWithMatrix:modelviewMatrix];
    self->projection = [[WWMatrix alloc] initWithMatrix:projectionMatrix];
    self->modelviewProjection = [[WWMatrix alloc] initWithMultiply:projectionMatrix matrixB:modelviewMatrix];

    return self;
}

- (WWMatrix*) modelview
{
    return self->modelview;
}

- (WWMatrix*) projection
{
    return self->projection;
}

- (WWMatrix*) modelviewProjection
{
    return self->modelviewProjection;
}

@end
