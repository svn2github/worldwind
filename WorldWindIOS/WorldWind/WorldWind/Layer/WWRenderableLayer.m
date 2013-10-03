/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <WorldWind/Layer/WWTiledImageLayer.h>
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

- (void) dispose
{
    [_renderables removeAllObjects];
}

- (void) addRenderable:(id <WWRenderable>)renderable
{
    if (renderable == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Renderable is nil")
    }

    [_renderables addObject:renderable];
}

- (void) addRenderables:(NSArray*)renderables
{
    if (renderables == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Renderables is nil")
    }

    for (id <WWRenderable> renderable in renderables)
    {
        [_renderables addObject:renderable];
    }
}

- (void) removeRenderable:(id <WWRenderable>)renderable
{
    if (renderable == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Renderable is nil")
    }

    [_renderables removeObject:renderable];
}

- (void) removeAllRenderables
{
    [_renderables removeAllObjects];
}

- (void) setOpacity:(float)opacity
{
    [super setOpacity:opacity];

    // TODO: Rather than set the opacity field of renderables, set a field for "layer opacity" in the draw context
    // and implement the renderables to composite it with their own opacity.
    for (id renderable in [self renderables])
    {
        if ([renderable isKindOfClass:[WWTiledImageLayer class]])
        {
            [((WWTiledImageLayer*) renderable) setOpacity:opacity];
        }
    }
}

- (void) doRender:(WWDrawContext*)dc
{
    for (id renderable in [self renderables])
    {
        [renderable render:dc];
    }
}

@end