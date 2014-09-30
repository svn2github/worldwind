/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/WorldWindView.h"
#import "WorldWind/Geometry/WWPosition.h"
#import "WorldWind/Geometry/WWVec4.h"
#import "WorldWind/Navigate/WWNavigatorState.h"
#import "WorldWind/Navigate/WWLookAtNavigator.h"
#import "WorldWind/Pick/WWPickedObjectList.h"
#import "WorldWind/Render/WWSceneController.h"
#import "WorldWind/Terrain/WWGlobe.h"
#import "WorldWind/Util/WWFrameStatistics.h"
#import "WorldWind/WorldWindConstants.h"
#import "WorldWind/WorldWindViewDelegate.h"
#import "WorldWind/WWLog.h"
#import "OpenGLES/ES2/glext.h"

#define REDRAW_FRAME_INTERVAL (3)

@implementation WorldWindView

+ (Class) layerClass
{
    return [CAEAGLLayer class];
}

- (id) initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
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

        // Set up to receive redraw notifications.
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleRequestRedraw:)
                                                     name:WW_REQUEST_REDRAW object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleStartRedrawing:)
                                                     name:WW_START_REDRAWING object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleStopRedrawing:)
                                                     name:WW_STOP_REDRAWING object:nil];
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

    // Invalidate the redraw display link if the view is de-allocated before continuous redraw can be stopped normally.
    if (redrawDisplayLink != nil)
    {
        [redrawDisplayLink invalidate];
        redrawDisplayLink = nil;
    }

    // Remove references to view delegates and remove this view from the default notification center.
    [delegates removeAllObjects];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) layoutSubviews
{
    // Let the superclass UIView perform auto layout.
    [super layoutSubviews];

    // The backing Core Animation layer's bounds or properties may have changed. Re-establish storage for the view's
    // renderbuffers and update the viewport and depthBits propertites. This ensures that the renderbuffer dimensions
    // match the view and the OpenGL viewport and projection matrix. Finally, draw this view immediately to ensure its
    // state matches the current layout.
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
    [_sceneController setNavigatorState:[_navigator currentState]];
    [_sceneController render:_viewport];

    // Request that Core Animation display the renderbuffer currently bound to GL_RENDERBUFFER. This assumes that the
    // color renderbuffer is currently bound.
    NSTimeInterval beginTime = [NSDate timeIntervalSinceReferenceDate];
    [_context presentRenderbuffer:GL_RENDERBUFFER];
    [_frameStatistics setDisplayRenderbufferTime:[NSDate timeIntervalSinceReferenceDate] - beginTime];

    // Notify any delegates that the WorldWindView completed drawing its OpenGL framebuffer contents.
    for (id <WorldWindViewDelegate> delegate in delegates)
    {
        if ([delegate respondsToSelector:@selector(viewDidDraw:)])
            [delegate viewDidDraw:self];
    }

    [_frameStatistics endFrame];
}

+ (void) requestRedraw
{
    if (![NSThread isMainThread]) // enqueue notifications on the main thread to ensure they are delivered
    {
        [[WorldWindView class] performSelectorOnMainThread:@selector(requestRedraw) withObject:nil waitUntilDone:NO];
        return;
    }

    // Enqueue a request redraw notification on the main thread using the default notification queue to coalesce redraw
    // requests posted on the same iteration of the run loop. Coalesced notifications are posted to the default
    // notification center when the current run loop completes. Notifications must be enqueued on the main thread for
    // two reasons: (1) each thread has its own default notification queue which performs coalescing, and (2) enqueued
    // notifications are not posted when the thread they are posted terminates before the next run loop iteration.
    NSNotification* redrawNotification = [NSNotification notificationWithName:WW_REQUEST_REDRAW object:nil];
    [[NSNotificationQueue defaultQueue] enqueueNotification:redrawNotification postingStyle:NSPostASAP];
}

+ (void) startRedrawing
{
    [[NSNotificationCenter defaultCenter] postNotificationName:WW_START_REDRAWING object:nil]; // don't coalesce start/stop notifications
}

+ (void) stopRedrawing
{
    [[NSNotificationCenter defaultCenter] postNotificationName:WW_STOP_REDRAWING object:nil]; // don't coalesce start/stop notifications
}

- (WWPickedObjectList*) pick:(CGPoint)pickPoint
{
    [EAGLContext setCurrentContext:_context];
    glBindFramebuffer(GL_FRAMEBUFFER, _pickingFrameBuffer);

    [_sceneController setNavigatorState:[_navigator currentState]];

    return [_sceneController pick:_viewport pickPoint:pickPoint];
}

- (WWPickedObjectList*) pickTerrain:(CGPoint)pickPoint
{
    [EAGLContext setCurrentContext:_context];
    glBindFramebuffer(GL_FRAMEBUFFER, _pickingFrameBuffer);

    [_sceneController setNavigatorState:[_navigator currentState]];

    return [_sceneController pickTerrain:_viewport pickPoint:pickPoint];
}

- (BOOL) convertPosition:(WWPosition*)position toPoint:(CGPoint*)point
{
    if (position == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Position is nil")
    }

    if (point == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Point is nil")
    }

    // Transform the geographic position to model coordinates.
    WWVec4* modelPoint = [[WWVec4 alloc] init];
    [[_sceneController globe] computePointFromPosition:[position latitude] longitude:[position longitude]
                                              altitude:[position altitude] outputPoint:modelPoint];

    // Transform the model coordinate point to OpenGL screen coordinates.
    WWVec4* screenPoint = [[WWVec4 alloc] init];
    if (![[_sceneController navigatorState] project:modelPoint result:screenPoint])
    {
        return NO; // Position is clipped by the frustum's near plane or the far plane.
    }

    // Test the screen coordinate point against the view frustum.
    if (!CGRectContainsPoint(_viewport, CGPointMake((CGFloat) [screenPoint x], (CGFloat) [screenPoint y])))
    {
        return NO; // Position is offscreen.
    }

    // Transform the OpenGL screen coordinate point to UIKit coordinates.
    *point = [[_sceneController navigatorState] convertPointToView:screenPoint];
    return YES;
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

- (void) handleRequestRedraw:(NSNotification*)notification
{
    if (![NSThread isMainThread]) // handle notifications on the main thread
    {
        [self performSelectorOnMainThread:@selector(handleRequestRedraw:) withObject:notification waitUntilDone:NO];
        return;
    }

    if (startRedrawingRequests == 0) // ignore redraw requests while the view is redrawing continuously
    {
        [self drawView];
    }
}

- (void) handleStartRedrawing:(NSNotification*)notification
{
    if (![NSThread isMainThread]) // handle notifications on the main thread
    {
        [self performSelectorOnMainThread:@selector(handleStartRedrawing:) withObject:notification waitUntilDone:NO];
        return;
    }

    if (++startRedrawingRequests == 1) // start redrawing on the first request and keep track of the total count
    {
        redrawDisplayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(drawView)];
        [redrawDisplayLink setFrameInterval:REDRAW_FRAME_INTERVAL];
        [redrawDisplayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    }
}

- (void) handleStopRedrawing:(NSNotification*)notification
{
    if (![NSThread isMainThread]) // handle notifications on the main thread
    {
        [self performSelectorOnMainThread:@selector(handleStopRedrawing:) withObject:notification waitUntilDone:NO];
        return;
    }

    if (--startRedrawingRequests == 0) // stop redrawing when all start requests have been accompanied by a stop request
    {
        [redrawDisplayLink invalidate];
        redrawDisplayLink = nil;
        [WorldWindView requestRedraw]; // request that a final frame be drawn during the next run loop iteration
    }
}

@end