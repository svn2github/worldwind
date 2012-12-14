/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Layer/WWBMNGOneImageLayer.h"
#import "WorldWind/Shapes/WWSurfaceImage.h"
#import "WorldWind/Geometry/WWSector.h"


@implementation WWBMNGOneImageLayer

- (WWBMNGOneImageLayer*) init
{
    self = [super init];

    _surfaceImage = [[WWSurfaceImage alloc] init];

    [_surfaceImage setSector:[[WWSector alloc] initWithFullSphere]];

    return self;
}

- (void) render:(WWDrawContext*)dc
{
    [_surfaceImage render:dc];
}

@end