/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/WorldWindView.h"
#import "WorldWind/Navigate/WWLookAtNavigator.h"
#import "WorldWind/Pick/WWPickedObjectList.h"
#import "WorldWind/Render/WWSceneController.h"
#import "WorldWind/Util/WWFrameStatistics.h"
#import "WorldWind/WorldWindConstants.h"
#import "WorldWind/WWLog.h"
#import "WorldWindViewDelegate.h"

@implementation WorldWindView
{
    NSLock* redrawRequestLock;
    NSMutableArray* delegates;
}

+ (Class) layerClass
{
    return [CAEAGLLayer class];
}

- (id) initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        self->redrawRequestLock = [[NSLock alloc] init];
        self->delegates = [[NSMutableArray alloc] init];

        CAEAGLLayer* eaglLayer = (CAEAGLLayer*) super.layer;
        eaglLayer.opaque = YES;
        self.clearsContextBeforeDrawing = NO;

        self->_context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        [EAGLContext setCurrentContext:self.context];

        // Generate OpenGL objects for the framebuffer, color renderbuffer, and depth renderbuffer. The storage for
        // each renderbuffer is allocated in resizeWithLayer.
        glGenFramebuffers(1, &self->_frameBuffer);
        glGenRenderbuffers(1, &self->_colorBuffer);
        glGenRenderbuffers(1, &self->_depthBuffer);

        // Generate a frame buffer and render buffers for picking.
        glGenFramebuffers(1, &_pickingFrameBuffer);
        glGenRenderbuffers(1, &_pickingColorBuffer);
        glGenRenderbuffers(1, &_pickingDepthBuffer);

        // Allocate storage for the color and depth renderbuffers. This computes the correct and consistent dimensions
        // for the renderbuffers, and assigns the viewport property.
        [self resizeWithLayer:eaglLayer];
//        [self setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];

        // Configure the picking framebuffer's color and depth attachments, then validate the framebuffer's status.
        glBindFramebuffer(GL_FRAMEBUFFER, _pickingFrameBuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, _pickingColorBuffer);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _pickingColorBuffer);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _pickingDepthBuffer);
        if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
        {
            WWLog(@"Failed to complete picking framebuffer attachment %x",
            glCheckFramebufferStatus(GL_FRAMEBUFFER));
            return nil;
        }

        // Configure the framebuffer's color and depth attachments, then validate the framebuffer's status.
        glBindFramebuffer(GL_FRAMEBUFFER, self->_frameBuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, self->_colorBuffer);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, self->_colorBuffer);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, self->_depthBuffer);

        if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
        {
            WWLog(@"Failed to complete framebuffer attachment %x",
            glCheckFramebufferStatus(GL_FRAMEBUFFER));
            return nil;
        }

        _sceneController = [[WWSceneController alloc] init];
        _navigator = [[WWLookAtNavigator alloc] initWithView:self];
        _frameStatistics = [[WWFrameStatistics alloc] init];

        // Indicate that iOS should maintain the WorldWindView's proportions when its size changes. This prevents the
        // scene from distorting when WorldWindView is rotated in response to a device orientation change. Without
        // contentMode configured this way, the globe appears to expand or contract during the autorotation animation.
        [self setContentMode:UIViewContentModeCenter];

        // Set up to handle redraw requests.
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleNotification:)
                                                     name:WW_REQUEST_REDRAW
                                                   object:nil];
    }

    return self;
}

- (void) dealloc
{
    [EAGLContext setCurrentContext:self.context];

    [self.sceneController dispose];

    [self tearDownGL];

    if ([EAGLContext currentContext] == self.context)
        [EAGLContext setCurrentContext:nil];
}

- (void) dispose
{
    // TODO: Is there a reason the sceneController is not disposed here?
    [_navigator dispose];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) tearDownGL
{
    glDeleteRenderbuffers(1, &self->_colorBuffer);
    self->_colorBuffer = 0;

    glDeleteRenderbuffers(1, &self->_depthBuffer);
    self->_depthBuffer = 0;

    glDeleteFramebuffers(1, &self->_frameBuffer);
    self->_frameBuffer = 0;

    glDeleteRenderbuffers(1, &self->_pickingColorBuffer);
    self->_pickingColorBuffer = 0;

    glDeleteRenderbuffers(1, &self->_pickingDepthBuffer);
    self->_pickingDepthBuffer = 0;

    glDeleteFramebuffers(1, &self->_pickingFrameBuffer);
    self->_pickingFrameBuffer = 0;
}

- (void) setNavigator:(id<WWNavigator>)navigator
{
    if (navigator == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Navigator is nil")
    }

    _navigator = navigator;
    [[NSNotificationCenter defaultCenter] postNotificationName:WW_NAVIGATOR_CHANGED object:_navigator];
}

- (void) addDelegate:(id <WorldWindViewDelegate>)delegate
{
    if (delegate != nil)
        [delegates addObject:delegate];
}

- (void) removeDelegate:(id <WorldWindViewDelegate>)delegate
{
    if (delegate != nil)
        [delegates removeObject:delegate];
}

- (void) drawView
{
    [_frameStatistics beginFrame];

    @synchronized (self->redrawRequestLock)
    {
        [self setRedrawRequested:NO];
    }

    for (id <WorldWindViewDelegate> delegate in delegates)
    {
        if ([delegate respondsToSelector:@selector(viewWillDraw:)])
            [delegate viewWillDraw:self];
    }

    [EAGLContext setCurrentContext:self.context];
    glBindFramebuffer(GL_FRAMEBUFFER, self->_frameBuffer);

    // The scene controller catches and logs rendering exceptions, so don't do it here. Draw the scene using the current
    // OpenGL viewport. We use the viewport instead of the bounds because the viewport contains the actual render buffer
    // dimension, whereas the bounds contain this view's dimension in screen points. When a WorldWindView is configured
    // for a retina display, the bounds do not represent the actual OpenGL render buffer resolution.
    [self.sceneController setFrameStatistics:_frameStatistics];
    [self.sceneController setNavigatorState:[[self navigator] currentState]];
    [self.sceneController render:self.viewport];

    // Requests that Core Animation display the renderbuffer currently bound to GL_RENDERBUFFER. This assumes that the
    // color renderbuffer is currently bound.
    NSTimeInterval beginTime = [NSDate timeIntervalSinceReferenceDate];
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
    [_frameStatistics setDisplayRenderbufferTime:[NSDate timeIntervalSinceReferenceDate] - beginTime];

    if (_drawContinuously)
    {
        NSNotification* redrawNotification = [NSNotification notificationWithName:WW_REQUEST_REDRAW object:self];
        [[NSNotificationCenter defaultCenter] postNotification:redrawNotification];
    }

    for (id <WorldWindViewDelegate> delegate in delegates)
    {
        if ([delegate respondsToSelector:@selector(viewDidDraw:)])
            [delegate viewDidDraw:self];
    }

    [_frameStatistics endFrame];
}

- (WWPickedObjectList*) pick:(CGPoint)pickPoint
{
    [EAGLContext setCurrentContext:self.context];
    glBindFramebuffer(GL_FRAMEBUFFER, _pickingFrameBuffer);

    [self.sceneController setNavigatorState:[[self navigator] currentState]];

    return [self.sceneController pick:[self viewport] pickPoint:pickPoint];
}

- (void) layoutSubviews
{
    // Called whenever the backing Core Animation layer's bounds or properties change. In this case, the WorldWindView
    // must reallocate storage for the color and depth renderbuffers, and reassign the viewport property. This ensures
    // that the renderbuffers fit the view, and that the OpenGL viewport and projection matrix match the renderbuffer
    // dimensions.

    [super layoutSubviews]; // let superclass perform Auto Layout

    CAEAGLLayer* eaglLayer = (CAEAGLLayer*) super.layer;
    [self resizeWithLayer:eaglLayer];
    [self drawView];
}

- (void) resizeWithLayer:(CAEAGLLayer*)layer
{
    GLint width, height;

    // Allocate storage for the color renderbuffer using the CAEAGLLayer, then retrieve its dimensions. The color
    // renderbuffer's are calculated based on this view's bounds and scale factor, and therefore may not be equal to
    // this view's bounds. The depth renderbuffer and viewport must have the same dimensions as the color renderbuffer.
    glBindRenderbuffer(GL_RENDERBUFFER, self->_colorBuffer);
    [self->_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:layer];
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &width);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &height);

    // Allocate storage for the depth renderbuffer using the color renderbuffer's dimensions retrieved from OpenGL. The
    // color renderbuffer and the depth renderbuffer must have the same dimensions.
    glBindRenderbuffer(GL_RENDERBUFFER, self->_depthBuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT24_OES, (GLsizei) width, (GLsizei) height);
    glGetIntegerv(GL_DEPTH_BITS, &_depthBits);

    // Allocate storage for the picking render buffers.
    glBindRenderbuffer(GL_RENDERBUFFER, _pickingColorBuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA8_OES, (GLsizei) width, (GLsizei) height);
    glBindRenderbuffer(GL_RENDERBUFFER, _pickingDepthBuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT24_OES, (GLsizei) width, (GLsizei) height);

    // Restore the GL_RENDERBUFFER binding to the color renderbuffer.
    glBindRenderbuffer(GL_RENDERBUFFER, self->_colorBuffer);

    // Assign the viewport to a rectangle with its origin at (0, 0) and with dimensions equal to the color renderbuffer.
    // This viewport property is used by the scene controller to set the OpenGL viewport state, and is used by the
    // navigator to compute the projection matrix. Both must use the dimensions of the color renderbuffer.
    self->_viewport = CGRectMake(0, 0, width, height);
}

- (void) handleNotification:(NSNotification*)notification
{
    if ([[notification name] isEqualToString:WW_REQUEST_REDRAW])
    {
        @synchronized (self->redrawRequestLock)
        {
            if (![self redrawRequested])
            {
                [self performSelectorOnMainThread:@selector(drawView) withObject:nil waitUntilDone:NO];
                [self setRedrawRequested:YES];
            }
        }
    }
}

- (void) requestRedraw
{
    NSNotification* redrawNotification = [NSNotification notificationWithName:WW_REQUEST_REDRAW object:self];
    [[NSNotificationCenter defaultCenter] postNotification:redrawNotification];
}

@end