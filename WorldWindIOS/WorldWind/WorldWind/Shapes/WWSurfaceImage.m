/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Shapes/WWSurfaceImage.h"
#import "WorldWind/Geometry/WWSector.h"
#import "WorldWind/Render/WWDrawContext.h"
#import "WorldWind/Render/WWSurfaceTileRenderer.h"


@implementation WWSurfaceImage

- (WWSurfaceImage*) init
{
    self = [super init];

    _sector = [[WWSector alloc] initWithFullSphere];

    return self;
}

- (BOOL) bind:(WWDrawContext*)dc
{
    return true;
}

- (void) applyInternalTransform:(WWDrawContext*)dc matrix:(WWMatrix*)matrix
{
}

- (void) render:(WWDrawContext*)dc
{
    [[dc surfaceTileRenderer] renderTile:dc surfaceTile:self];
}

@end