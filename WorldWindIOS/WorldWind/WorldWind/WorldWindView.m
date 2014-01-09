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
#import "WorldWind/WorldWindViewDelegate.h"
#import "WorldWind/WWLog.h"

@implementation WorldWindView

+ (Class) layerClass
{
    return [CAEAGLLayer class];
}

- (id) initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        redrawRequestLock = [[NSLock alloc] init];
        delegates = [[NSMutableArray alloc] init];
        _sceneController = [[WWSceneController alloc] init];
        _navigator = [[WWLookAtNavigator alloc] initWithView:self];
        _frameStatistics = [[WWFrameStatistics alloc] init];
        _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];

        // Configure this view to avoid clearing its context in drawRect: and maintain the view's proportions when its
        // size changes. This prevents the scene from distorting when WorldWindView is rotated in response to a device
        // orientation change. Without contentMode configured this way the globe appears to expand or contract during
        // the autorotation animation.
        [self setClearsContextBeforeDrawing:NO];
        [self setContentMode:UIViewContentModeCenter];

        // Make this view's OpenGL context the current rendering context. The following OpenGL framebuffer and
        // renderbuffer function calls are applied to this view's context.
        [EAGLContext setCurrentContext:_context];

        // Generate OpenGL objects for the framebuffer, color renderbuffer, and depth renderbuffer. The storage for
        // each renderbuffer is allocated in establishRenderbufferStorage.
        glGenFramebuffers(1, &_frameBuffer);
        glGenRenderbuffers(1, &_colorBuffer);
        glGenRenderbuffers(1, &_depthBuffer);

        // Generate a frame buffer and render buffers for picking.
        glGenFramebuffers(1, &_pickingFrameBuffer);
        glGenRenderbuffers(1, &_pickingColorBuffer);
        glGenRenderbuffers(1, &_pickingDepthBuffer);

        // Establish storage for the renderbuffers. This computes the correct and consistent dimensions for the
        // renderbuffers, and assigns the viewport property. According to the CAEAGLLayer class documentation, setting
        // the view's backing layer to opaque is necessary for best performance.
        CAEAGLLayer* eaglLayer = (CAEAGLLayer*) [super layer];
        [eaglLayer setOpaque:YES];
        [self establishRenderbufferStorage:eaglLayer];

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
        glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, _colorBuffer);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorBuffer);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _depthBuffer);

        if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
        {
            WWLog(@"Failed to complete framebuffer attachment %x",
            glCheckFramebufferStatus(GL_FRAMEBUFFER));
            return nil;
        }

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
    [self dispose];
}

- (void) dispose
{
    // Make this view's OpenGL context the current rendering context. OpenGL functions invoked by the scene controller
    // and deleteRenderbuffers and are applied to this view's context.
    [EAGLContext setCurrentContext:_context];

    // Let the scene controller and the navigator dispose of themselves.
    [_sceneController dispose];
    [_navigator dispose];

    // Delete this view's OpenGL framebuffer objects and renderbuffer objects.
    [self deleteRenderbuffers];

    // Release any pointers to this view's OpenGL context.
    if ([EAGLContext currentContext] == _context)
        [EAGLContext setCurrentContext:nil];

    [delegates removeAllObjects];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) layoutSubviews
{
    [super layoutSubviews]; // let the superclass UIView perform Auto Layout functions

    // Called whenever the backing Core Animation layer's bounds or properties change. In this case, the WorldWindView
    // must re-establish storage for the color and depth renderbuffers, and reassign the viewport property. This ensures
    // that the renderbuffers fit the view, and that the OpenGL viewport and projection matrix match the renderbuffer
    // dimensions.
    [EAGLContext setCurrentContext:_context];
    [self establishRenderbufferStorage:(CAEAGLLayer*) [super layer]];
    [self drawView];
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

- (void) drawView
{
    [_frameStatistics beginFrame];

    @synchronized (redrawRequestLock)
    {
        [self setRedrawRequested:NO];
    }

    // Notify any delegates that the WorldWindView is about to draw its OpenGL framebuffer contents.
    for (id <WorldWindViewDelegate> delegate in delegates)
    {
        if ([delegate respondsToSelector:@selector(viewWillDraw:)])
            [delegate viewWillDraw:self];
    }

    // Make this view's OpenGL context the current rendering context.
    [EAGLContext setCurrentContext:_context];
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);

    // Draw the scene using the current OpenGL viewport. We use the viewport instead of the bounds because the viewport
    // contains the actual renderbuffer dimensions, whereas the bounds contain this view's dimension in UIKit
    // coordinates. When a WorldWindView is configured for a retina display, the bounds do not represent the actual
    // OpenGL render buffer resolution. Note that the scene controller catches and logs rendering exceptions, so we
    // don't do it here.
    [_sceneController setFrameStatistics:_frameStatistics];
    [_sceneController setNavigatorState:[[self navigator] currentState]];
    [_sceneController render:_viewport];

    // Request that Core Animation display the renderbuffer currently bound to GL_RENDERBUFFER. This assumes that the
    // color renderbuffer is currently bound.
    NSTimeInterval beginTime = [NSDate timeIntervalSinceReferenceDate];
    [_context presentRenderbuffer:GL_RENDERBUFFER];
    [_frameStatistics setDisplayRenderbufferTime:[NSDate timeIntervalSinceReferenceDate] - beginTime];

    if (_drawContinuously)
    {
        NSNotification* redrawNotification = [NSNotification notificationWithName:WW_REQUEST_REDRAW object:self];
        [[NSNotificationCenter defaultCenter] postNotification:redrawNotification];
    }

    // Notify any delegates that the WorldWindView completed drawing its OpenGL framebuffer contents.
    for (id <WorldWindViewDelegate> delegate in delegates)
    {
        if ([delegate respondsToSelector:@selector(viewDidDraw:)])
            [delegate viewDidDraw:self];
    }

    [_frameStatistics endFrame];
}

- (void) requestRedraw
{
    NSNotification* redrawNotification = [NSNotification notificationWithName:WW_REQUEST_REDRAW object:self];
    [[NSNotificationCenter defaultCenter] postNotification:redrawNotification];
}

- (WWPickedObjectList*) pick:(CGPoint)pickPoint
{
    [EAGLContext setCurrentContext:_context];
    glBindFramebuffer(GL_FRAMEBUFFER, _pickingFrameBuffer);

    [_sceneController setNavigatorState:[[self navigator] currentState]];

    return [_sceneController pick:[self viewport] pickPoint:pickPoint];
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

- (void) establishRenderbufferStorage:(id <EAGLDrawable>)drawable
{
    GLint width, height;

    // Allocate storage for the color renderbuffer using the CAEAGLLayer, then retrieve its dimensions. The color
    // renderbuffer's are calculated based on this view's bounds and scale factor, and therefore may not be equal to
    // this view's bounds in UIKit coordinates.
    glBindRenderbuffer(GL_RENDERBUFFER, _colorBuffer);
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:drawable];
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &width);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &height);

    // Allocate storage for the depth renderbuffer using the color renderbuffer's dimensions retrieved from OpenGL. The
    // depth renderbuffer must have the same dimensions as the color renderbuffer.
    glBindRenderbuffer(GL_RENDERBUFFER, _depthBuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT24_OES, (GLsizei) width, (GLsizei) height);
    glGetIntegerv(GL_DEPTH_BITS, &_depthBits);

    // Allocate storage for the picking render buffers. The picking color and depth renderbuffers must have the same
    // dimensions as the visible color and depth renderbuffers.
    glBindRenderbuffer(GL_RENDERBUFFER, _pickingColorBuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA8_OES, (GLsizei) width, (GLsizei) height);
    glBindRenderbuffer(GL_RENDERBUFFER, _pickingDepthBuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT24_OES, (GLsizei) width, (GLsizei) height);

    // Restore the GL_RENDERBUFFER binding to the color renderbuffer.
    glBindRenderbuffer(GL_RENDERBUFFER, _colorBuffer);

    // Assign the viewport to a rectangle with its origin at (0, 0) and with dimensions equal to the color renderbuffer.
    // This viewport property is used by the scene controller to set the OpenGL viewport state, and is used by the
    // navigator to compute the projection matrix. Both must use the dimensions of the color renderbuffer.
    _viewport = CGRectMake(0, 0, width, height);
}

- (void) deleteRenderbuffers
{
    glDeleteRenderbuffers(1, &_colorBuffer);
    _colorBuffer = 0;

    glDeleteRenderbuffers(1, &_depthBuffer);
    _depthBuffer = 0;

    glDeleteFramebuffers(1, &_frameBuffer);
    _frameBuffer = 0;

    glDeleteRenderbuffers(1, &_pickingColorBuffer);
    _pickingColorBuffer = 0;

    glDeleteRenderbuffers(1, &_pickingDepthBuffer);
    _pickingDepthBuffer = 0;

    glDeleteFramebuffers(1, &_pickingFrameBuffer);
    _pickingFrameBuffer = 0;
}

- (void) handleNotification:(NSNotification*)notification
{
    if ([[notification name] isEqualToString:WW_REQUEST_REDRAW])
    {
        @synchronized (redrawRequestLock)
        {
            if (![self redrawRequested])
            {
                [self performSelectorOnMainThread:@selector(drawView) withObject:nil waitUntilDone:NO];
                [self setRedrawRequested:YES];
            }
        }
    }
}

@end