/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Render/WWDrawContext.h"
#import "WorldWind/Render/WWSurfaceTileRenderer.h"

@implementation WWDrawContext

- (WWDrawContext*) init
{
    self = [super init];

    _surfaceTileRenderer = [[WWSurfaceTileRenderer alloc] init];
    _verticalExaggeration = 1;
    _timestamp = [NSDate date];

    return self;
}

- (void) reset
{
    _timestamp = [NSDate date];
    _verticalExaggeration = 1;
}

@end
