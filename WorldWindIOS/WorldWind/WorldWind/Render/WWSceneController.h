/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/ES2/gl.h>

@class WWGlobe;
@class WWLayerList;
@class WWDrawContext;
@class WWGpuResourceCache;
@protocol WWNavigatorState;

@interface WWSceneController : NSObject
{
@protected
    WWDrawContext *drawContext;
}

@property (readonly, nonatomic) WWGlobe* globe;
@property (readonly, nonatomic) WWLayerList* layers;
@property (nonatomic) id<WWNavigatorState> navigatorState;
@property (readonly, nonatomic) WWGpuResourceCache* gpuResourceCache;

- (WWSceneController*)init;
- (void) render:(CGRect)viewport;
- (void) dispose;
- (void) resetDrawContext;
- (void) drawFrame:(CGRect)viewport;
- (void) beginFrame:(CGRect)viewport;
- (void) endFrame;
- (void) clearFrame;
- (void) createTerrain;
- (void) draw;
- (void) drawLayers;
- (void) drawOrderedRenderables;
@end