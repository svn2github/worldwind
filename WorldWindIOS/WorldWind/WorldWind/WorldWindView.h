/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <UIKit/UIKit.h>
#import "WorldWind/Util/WWDisposable.h"

@class WWFrameStatistics;
@class WWPickedObjectList;
@class WWSceneController;
@class WWVec4;
@protocol WWNavigator;
@protocol WorldWindViewDelegate;

/**
* Provides a view with a World Wind virtual globe. This is the top-level World Wind object and the fundamental object
* applications instance and interact with. The view automatically provides on-demand retrieval of imagery, elevations
* and other data, as well as user-initiated navigation and globe manipulation. Using the view is simple: allocate it,
* initialize it and add it to the application's main view or sub-view.
*
* Manipulation of the globe is performed by the user via a Navigator. The default navigator is WWLookAtNavigator,
* which provides a trackball-style interaction model. World Wind also provides a WWFirstPersonNavigator that
* implements a first-person model allowing the user to manipulate a virtual camera. The navigation models can be
* switched by setting the view's navigator property.
*
* The view provides picking support via its pick method. When called, that method determines the shapes and
* terrain-location for a specified pick point, which is typically the point associated with a tap gesture. Applications
* must call the pick method to effect a pick; picking is not performed automatically. Unlike World Wind Java,
* there is no select event mechanism.
*
* Layers can be added to and removed from the World Wind view via the scene controller, available via the
* sceneController property.
*
* When a layer or other aspect of the view is changed, the view must redraw to effect the change on the screen. This
* is performed automatically during navigation and for layer list changes. Applications must explicitly request a
* redraw when they make changes to layer contents, including the shapes in a WWRenderableLayer. Redraws can be
* requested by calling WorldWindView's requestRedraw method, which posts a WW_REQUEST_REDRAW notification to the default
* notification center. The benefit of using requestRedraw rather than posting notifications explicitly is that this
* method will coalesce redundant redraw requests.
*/
@interface WorldWindView : UIView <WWDisposable>
{
@protected
    NSUInteger startRedrawingRequests;
    CADisplayLink* redrawDisplayLink;
    NSMutableArray* delegates;
}

/// @name Attributes

/// The view's scene controller. Use this to add and remove layers.
@property(nonatomic, readonly) WWSceneController* sceneController;

/// The view's navigator.
@property(nonatomic) id <WWNavigator> navigator;

/// The view's frame statistics associated with the most recent frame. Frame statistics provides measurements indicating
/// the view's current and average rendering performance.
@property(nonatomic, readonly) WWFrameStatistics* frameStatistics;

/// The view's OpenGL context. Applications typically do not need to be aware of this object.
@property(nonatomic, readonly) EAGLContext* context;

/// The view's viewport, in screen coordinates.
@property(nonatomic, readonly) CGRect viewport;

/// The view's OpenGL frame buffer. Applications typically do not need to be aware of this object.
@property(nonatomic, readonly) GLuint frameBuffer;

/// The view's OpenGL color buffer. Applications typically do not need to be aware of this object.
@property(nonatomic, readonly) GLuint colorBuffer;

/// The view's OpenGL depth buffer. Applications typically do not need to be aware of this object.
@property(nonatomic, readonly) GLuint depthBuffer;

/// The number of bitplanes in the view's OpenGL depth buffer. Applications typically do not need to be aware of this
/// value.
@property(nonatomic, readonly) GLint depthBits;

/// The view's OpenGL picking frame buffer. Applications typically do not need to be aware of this object.
@property(nonatomic, readonly) GLuint pickingFrameBuffer;

/// The view's OpenGL picking color buffer. Applications typically do not need to be aware of this object.
@property(nonatomic, readonly) GLuint pickingColorBuffer;

/// The view's OpenGL picking depth buffer. Applications typically do not need to be aware of this object.
@property(nonatomic, readonly) GLuint pickingDepthBuffer;

/// @name Updating the World Wind Scene

/**
* Redraws this view's scene.
*
* The redraw is performed immediately. Applications should typically not use this method to redraw, but should use
* requestRedraw, startRedrawing and stopRedrawing instead.
*/
- (void) drawView;

/**
* Requests that WorldWindViews redraw themselves when the current run loop completes.
*
* This methods queues a redraw request then returns immediately to the caller, without waiting for the redraw to
* complete. Multiple redraw requests posted during the same run loop iteration are coalesced so that views are not
* redrawn excessively. Redraw requests submitted while a view is continuously redrawing are ignored. See startRedrawing
* for information on continuous redrawing.
*
* It is safe to call this method from any thread. Requests received on a non-main thread are automatically forwarded to
* the main thread.
*/
+ (void) requestRedraw;

/**
* Requests that WorldWindViews start redrawing themselves continuously. This must be paired with a corresponding call to
* stopRedrawing.
*
* This method causes WorldWindViews to start redrawing themselves continuously then returns to the caller. The first
* redraw is performed during the next run loop iteration. Single redraw requests submitted while a view is continuously
* redrawing are ignored. See requestRedraw for information on single redraw requests.
*
* Continuous WorldWindView redrawing is synchronized with the refresh rate of the display using a CADisplayLink. The
* display link may be configured to draw at an implementation defined fraction of the native refresh rate in order to
* maintain a steady redraw rate.
*
* It is safe to call this method from any thread. Requests received on a non-main thread are automatically forwarded to
* the main thread.
*/
+ (void) startRedrawing;

/**
* Requests that WorldWindViews stop redrawing themselves continuously. This must be paired with a corresponding call to
* startRedrawing.
*
* This method requests that WorldWindViews redraw themselves one final time, then causes WorldWindViews to stop drawing
* themselves continuously and returns to the caller.
*
* It is safe to call this method from any thread. Requests received on a non-main thread are automatically forwarded to
* the main thread.
*/
+ (void) stopRedrawing;

/// @name Picking Objects in the World Wind Scene

/**
* Request the objects at a specified pick point.
*
* @param pickPoint The point to examine, in screen coordinates.
*
* @return The objects at the specified pick point. If the pick point intersects the globe,
* the returned list contains an object identifying the associated geographic position.
*/
- (WWPickedObjectList*) pick:(CGPoint)pickPoint;

/// @name Interposing in View Operations

/**
* Adds a delegate to this view's list of delegates called at key points in the view's lifecycle.
*
* @param delegate The delegate to call at lifecycle points.
*/
- (void) addDelegate:(id <WorldWindViewDelegate>)delegate;

/**
* Removes previously added delegates.
*
* @param delegate The delegate to remove.
*/
- (void) removeDelegate:(id <WorldWindViewDelegate>)delegate;

/// @name Methods of Interest Only to Subclasses

/**
* Allocates storage for this view's OpenGL renderbuffer objects and updates the viewport and depthBits properties to
* match the current renderbuffer storage configuration.
*
* Called when this view is initialized and any time its OpenGL renderbuffer dimensions change thereafter.
*
* @param drawable The EAGLDrawable instance that will serve as the storage target for this view's OpenGL rendering.
*/
- (void) establishRenderbufferStorage:(id <EAGLDrawable>)drawable;

/**
* Releases the OpenGL framebuffer objects and renderbuffer objects created when this view was initialized.
*/
- (void) deleteRenderbuffers;

/**
* Responds to notifications posted by requestRedraw and any notification named WW_REQUEST_REDRAW.
*
* This correctly handles notifications posted on any thread.
*
* @param notification The posted notification.
*/
- (void) handleRequestRedraw:(NSNotification*)notification;

/**
* Responds to notifications posted by startRedrawing and any notification named WW_START_REDRAWING.
*
* This correctly handles notifications posted on any thread.
*
* @param notification The posted notification.
*/
- (void) handleStartRedrawing:(NSNotification*)notification;

/**
* Responds to notifications posted by stopRedrawing and any notification named WW_STOP_REDRAWING.
*
* This correctly handles notifications posted on any thread.
*
* @param notification The posted notification.
*/
- (void) handleStopRedrawing:(NSNotification*)notification;

@end