/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Render/WWDrawContext.h"
#import "WorldWind/Render/WWSurfaceTileRenderer.h"
#import "WorldWind/Geometry/WWVec4.h"
#import "WorldWind/Terrain/WWGlobe.h"
#import "WorldWind/Navigate/WWNavigatorState.h"
#import "WorldWind/Geometry/WWPosition.h"

@implementation WWDrawContext

- (WWDrawContext*) init
{
    self = [super init];

    _surfaceTileRenderer = [[WWSurfaceTileRenderer alloc] init];
    _verticalExaggeration = 1;
    _timestamp = [NSDate date];
    _eyePosition = [[WWPosition alloc] initWithDegreesLatitude:0 longitude:0 altitude:0];

    return self;
}

- (void) reset
{
    _timestamp = [NSDate date];
    _verticalExaggeration = 1;
}

- (void) update
{
    WWVec4* ep = [_navigatorState eyePoint];

    [_globe computePositionFromPoint:[ep x] y:[ep y] z:[ep z] outputPosition:_eyePosition];
}

@end
