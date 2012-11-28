/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/ES2/gl.h>
//#import "WorldWind/WorldWind.h"

@class WWGlobe;
@class WWLayerList;
@class WWDrawContext;


@interface WWSceneController : NSObject
{
@protected
    GLuint program;
    WWDrawContext *drawContext;
}

@property (readonly) WWGlobe* globe;
@property (readonly) WWLayerList* layers;

- (WWSceneController*)init;
- (void) render:(CGRect) bounds;
- (void) dispose;
- (void) resetDrawContext;
- (void) drawFrame:(CGRect) bounds;
- (void) beginFrame:(CGRect) bounds;
- (void) endFrame;
- (void) clearFrame;
- (void) applyView;
- (void) createTerrain;
- (void) draw;
- (void) drawLayers;
- (void) drawOrderedRenderables;
@end