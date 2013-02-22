/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Layer/WWRenderableLayer.h"
#import "WorldWind/WWLog.h"

@implementation WWRenderableLayer

- (WWRenderableLayer*) init
{
    self = [super init];

    [self setDisplayName:@"Renderables"];

    _renderables = [[NSMutableArray alloc] init];

    return self;
}

- (void) addRenderable:(id <WWRenderable>)renderable
{
    if (renderable == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Renderable is nil")
    }

    if (renderable != nil)
    {
        [_renderables addObject:renderable];
    }
}

- (void) doRender:(WWDrawContext*)dc
{
    for (NSUInteger i = 0; i < [_renderables count]; i++)
    {
        [[_renderables objectAtIndex:i] render:dc];
    }
}

@end