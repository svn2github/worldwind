/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Render/WWSceneController.h"
#import "WorldWind/Terrain/WWGLobe.h"
#import "WorldWind/Layer/WWLayerList.h"
#import "WorldWInd/Layer/WWLayer.h"
#import "WorldWind/Render/WWDrawContext.h"
#import "WorldWind/Terrain/WWTerrainTileList.h"
#import "WorldWind/WWLog.h"
#import "WorldWind/Geometry/WWMatrix.h"

@implementation WWSceneController

- (WWSceneController*)init
{
    self = [super init];

    _globe = [[WWGlobe alloc] init];
    _layers = [[WWLayerList alloc] init];
    
    self->drawContext = [[WWDrawContext alloc] init];

    return self;
}

- (void) dispose
{
}

- (void) handleMemoryWarning
{
}

- (void) render:(CGRect) bounds
{
    @try
    {
        [self resetDrawContext];
        [self drawFrame:bounds];
    }
    @catch (NSException *exception)
    {
        WWLogE(@"Rendering Scene", exception);
    }
}

- (void) resetDrawContext
{
    [self->drawContext reset];
    [self->drawContext setLayers:_layers];
    [self->drawContext setGlobe:[self globe]];
    [self->drawContext setVerticalExaggeration:1.0];
}

- (void) drawFrame:(CGRect) bounds
{
    @try {
        [self beginFrame:bounds];
        [self applyView];
        [self createTerrain];
        [self clearFrame];
        [self draw];
    }
    @finally {
        [self endFrame];
    }
}

- (void) beginFrame:(CGRect) bounds
{
    glViewport((int) bounds.origin.x, (int) bounds.origin.y, (int) bounds.size.width, (int) bounds.size.height);
    
    glEnable(GL_BLEND);
    glEnable(GL_CULL_FACE);
    glEnable(GL_DEPTH_TEST);
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    glDepthFunc(GL_LEQUAL);
}

- (void) endFrame
{
    glDisable(GL_BLEND);
    glDisable(GL_CULL_FACE);
    glDisable(GL_DEPTH_TEST);
    glBlendFunc(GL_ONE, GL_ZERO);
    glDepthFunc(GL_LESS);
    glClearColor(0, 0, 0, 1);
}

- (void) clearFrame
{
    glClearColor(0.3, 0.3, 0.3, 1);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}

- (void) applyView
{
    WWMatrix* m = [[WWMatrix alloc] initWithIdentity];
    m->m[0] = 0.5;
    m->m[5] = 1.0 / 3.0;

    [self->drawContext setModelviewProjection:m];
}

- (void) createTerrain
{
    WWTerrainTileList* surfaceGeometry = [_globe tessellate:self->drawContext];

    // If there's no surface geometry, just log a warning and keep going. Some layers may have meaning without it.
    if (surfaceGeometry == nil || [surfaceGeometry count] == 0)
    {
        WWLog(@"No surface geometry");
    }
    
    [self->drawContext setSurfaceGeometry:surfaceGeometry];
    [self->drawContext setVisibleSector:surfaceGeometry.sector];
}

- (void) draw
{
    [self drawLayers];
    [self drawOrderedRenderables];
}

- (void) drawLayers
{
    int nLayers = _layers.count;
    for (NSUInteger i = 0; i < nLayers; i++)
    {
        WWLayer* layer = [_layers layerAtIndex:i];
        if (layer != nil)
        {
            [layer render:self->drawContext];
        }
    }
}

- (void) drawOrderedRenderables
{
}

@end