/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration.
 All Rights Reserved.
 
 * @version $Id$
 */


#import "WorldWindView.h"

@interface WorldWindView ()
- (void) tearDownGL;
@end

@implementation WorldWindView

+ (Class) layerClass
{
    return [CAEAGLLayer class];
}

- (id) initWithFrame:(CGRect) frame
{
    if (self = [super initWithFrame:frame])
    {
        CAEAGLLayer *eaglLayer = (CAEAGLLayer *) super.layer;
        eaglLayer.opaque = YES;
        
        self->_context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        [EAGLContext setCurrentContext:self.context];
        
        glGenRenderbuffers(1, &self->_depthBuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, self->_depthBuffer);
        glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT24_OES, CGRectGetWidth(frame), CGRectGetHeight(frame));
        
        glGenRenderbuffers(1, &self->_renderBuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, self->_renderBuffer);
        [self.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:eaglLayer];
        
        glGenFramebuffers(1, &self->_frameBuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, self->_frameBuffer);
        
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, self->_renderBuffer);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, self->_depthBuffer);
        
        if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
        {
            WWLog(@"Failed to complete framebuffer attachment %x",
                  glCheckFramebufferStatus(GL_FRAMEBUFFER));
            return nil;
        }

        self->_sceneController = [[WWSceneController alloc] init];
    }
    
    return self;
}

- (void) drawView
{
    [EAGLContext setCurrentContext:self.context];
    
    // The scene controller catches and logs rendering exceptions, so don't do it here.
    [self.sceneController render:self.frame];
    
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
}

- (void) dealloc
{
    [EAGLContext setCurrentContext:self.context];
    
    [self.sceneController dispose];
    
    [self tearDownGL];
    
    if ([EAGLContext currentContext] == self.context)
        [EAGLContext setCurrentContext:nil];
}

- (void) tearDownGL
{
    glDeleteRenderbuffers(1, &self->_renderBuffer);
    self->_renderBuffer = 0;
    
    glDeleteRenderbuffers(1, &self->_depthBuffer);
    self->_depthBuffer = 0;
    
    glDeleteFramebuffers(1, &self->_frameBuffer);
    self->_frameBuffer = 0;
}
@end