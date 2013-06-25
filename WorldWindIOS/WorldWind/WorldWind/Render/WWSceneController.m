/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Render/WWSceneController.h"
#import "WorldWind/Terrain/WWGLobe.h"
#import "WorldWind/Layer/WWLayerList.h"
#import "WorldWind/Layer/WWLayer.h"
#import "WorldWind/Render/WWDrawContext.h"
#import "WorldWind/Terrain/WWTerrainTileList.h"
#import "WorldWind/Util/WWGpuResourceCache.h"
#import "WorldWind/WWLog.h"
#import "WorldWind/Render/WWOrderedRenderable.h"
#import "WorldWind/Terrain/WWTessellator.h"
#import "WorldWind/Pick/WWPickedObjectList.h"
#import "WorldWind/Pick/WWPickedObject.h"

@implementation WWSceneController

- (WWSceneController*) init
{
    self = [super init];

    _globe = [[WWGlobe alloc] init];
    _layers = [[WWLayerList alloc] init];

    _gpuResourceCache = [[WWGpuResourceCache alloc] initWithLowWater:(long) 150e6 capacity:(long) 250e6];

    self->drawContext = [[WWDrawContext alloc] init];
    [self->drawContext setGpuResourceCache:_gpuResourceCache];

    return self;
}

- (void) dispose
{
    [_gpuResourceCache clear];
}

- (void) render:(CGRect)viewport
{
    @try
    {
        [self resetDrawContext];
        [self drawFrame:viewport];
    }
    @catch (NSException* exception)
    {
        WWLogE(@"Rendering Scene", exception);
    }
}

- (WWPickedObjectList*) pick:(CGRect)viewport pickPoint:(CGPoint)pickPoint
{
    @try
    {
        [self resetDrawContext];
        [drawContext setPickingMode:YES];
        [drawContext setPickPoint:pickPoint];
        [self drawFrame:viewport];

        return [drawContext objectsAtPickPoint];
    }
    @catch (NSException* exception)
    {
        WWLogE(@"Picking Scene", exception);

        return nil;
    }
}

- (void) resetDrawContext
{
    [self->drawContext reset];
    [self->drawContext setLayers:_layers];
    [self->drawContext setGlobe:[self globe]];
    [self->drawContext setNavigatorState:_navigatorState];
    [self->drawContext setVerticalExaggeration:1.0];
    [self->drawContext update];
}

- (void) drawFrame:(CGRect)viewport
{
    @try
    {
        [self beginFrame:viewport];
        [self createTerrain];
        [self clearFrame];
        if ([drawContext pickingMode])
        {
            [self doPick];
        }
        else
        {
            [self doDraw];
        }
    }
    @finally
    {
        [self endFrame];
    }
}

- (void) beginFrame:(CGRect)viewport
{
    [self beginStatistics];

    glViewport((int) viewport.origin.x, (int) viewport.origin.y, (int) viewport.size.width, (int) viewport.size.height);

    if ([drawContext pickingMode])
    {
        glDisable(GL_DITHER);
    }
    else
    {
        glEnable(GL_BLEND);
        glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    }

    glEnable(GL_CULL_FACE);
    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_LEQUAL);
}

- (void) endFrame
{
    glEnable(GL_DITHER);
    glDisable(GL_BLEND);
    glDisable(GL_CULL_FACE);
    glDisable(GL_DEPTH_TEST);
    glBlendFunc(GL_ONE, GL_ZERO);
    glDepthFunc(GL_LESS);
    glClearColor(0, 0, 0, 1);

    [self endStatistics];
}

- (void) clearFrame
{
    GLuint colorInt = [self->drawContext clearColor];
    float r = ((colorInt >> 24) & 0xff) / 255.0;
    float g = ((colorInt >> 16) & 0xff) / 255.0;
    float b = ((colorInt >> 8) & 0xff) / 255.0;
    float a = (colorInt & 0xff) / 255.0;

    glClearColor(r, g, b, a);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
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
    [self->drawContext setNumElevationTiles:[surfaceGeometry count]];
}

- (void) doDraw
{
    [self drawLayers];
    [self drawOrderedRenderables];
}

- (void) doPick
{
    [[[drawContext surfaceGeometry] tessellator] pick:drawContext];

    [self doDraw];

    [self resolveTopPick];
}

- (void) drawLayers
{
    int nLayers = _layers.count;
    for (NSUInteger i = 0; i < nLayers; i++)
    {
        WWLayer* layer = [_layers layerAtIndex:i];
        if (layer != nil)
        {
            [drawContext setCurrentLayer:layer];
            @try
            {
                [layer render:drawContext];
            }
            @catch (NSException* exception)
            {
                NSString* layerName = [layer displayName];
                NSString* msg = [NSString stringWithFormat:@"rendering layer %@", layerName != nil ? layerName : @""];
                WWLogE(msg, exception);
                // Keep going. Render the rest of the layers.
            }
        }
    }

    [drawContext setCurrentLayer:nil];
}

- (void) drawOrderedRenderables
{
    // Sort the ordered renderable list to prepare it for
    [drawContext sortOrderedRenderables];

    // Prepare to draw the sorted ordered renderables.
    [drawContext setOrderedRenderingMode:YES];

    // Process each ordered renderable in the queue. We avoid use of an iterator or enumerator and remove entries so
    // that renderables may draw themselves in batch and remove themselves from the queue as they do so.
    id <WWOrderedRenderable> or = nil;
    while ((or = [drawContext popOrderedRenderable]) != nil)
    {
        @try
        {
            [or render:drawContext];
        }
        @catch (NSException* exception)
        {
            NSString* msg = [NSString stringWithFormat:@"rendering shape"];
            WWLogE(msg, exception);
            // Keep going. Render the rest of the ordered renderables.
        }
    }

    [drawContext setOrderedRenderingMode:NO];
}

- (void) resolveTopPick
{
    // Make a last reading to find out which is the top color.

    WWPickedObjectList*  pickedObjects = [drawContext objectsAtPickPoint];
    if ([[pickedObjects objects] count] == 1)
    {
        [[[pickedObjects objects] objectAtIndex:0] setIsOnTop:YES];
    }
    else if ([[pickedObjects objects] count] > 1)
    {
        unsigned int colorCode = [drawContext readPickColor:[drawContext pickPoint]];
        if (colorCode != 0)
        {
            // Find the picked object with the top color code and set its "onTop" flag.
            for (NSUInteger i = 0; i < [[pickedObjects objects] count]; i++)
            {
                WWPickedObject* po = [[pickedObjects objects] objectAtIndex:i];
                if ([po colorCode] == colorCode)
                {
                    [po setIsOnTop:YES];
                    break;
                }
            }
        }
    }
}

- (void) beginStatistics
{
    ++frameCount;
    frameTime = [NSDate timeIntervalSinceReferenceDate];
}

- (void) endStatistics
{
    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    frameTime = now - frameTime;
    frameTimeCumulative += frameTime;

    if (frameTime < _frameTimeMin)
        _frameTimeMin = frameTime;
    if (frameTime > _frameTimeMax)
            _frameTimeMax = frameTime;

    if (now - frameTimeBase > 2)
    {
        _frameRateAverage = frameCount / (now - frameTimeBase);
        _frameTimeAverage = frameTimeCumulative / frameCount;
        frameTimeBase = now;
        frameCount = 0;
        frameTimeCumulative = 0;
        _frameTimeMin = DBL_MAX;
        _frameTimeMax = -DBL_MAX;
    }
}

- (int) numImageTiles
{
    return [drawContext numImageTiles];
}

- (int) numElevationTiles
{
    return [drawContext numElevationTiles];
}

- (int) numRenderedTiles
{
    return [drawContext numRenderedTiles];
}

@end