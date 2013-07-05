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
* requested either by calling the World Wind view's requestRedraw method or by sending a WW_REQUEST_REDRAW notification
* to the default notification center. See the implementation of WorldWindView.requestRedraw for an example of how to
* form and send the notification. The benefit of the notification approach is that the application object requesting
* the redraw need not have a reference to the WorldWindView object.
*/
@interface WorldWindView : UIView <WWDisposable>

/// @name World Wind View attributes

/// The view's scene controller. Use this to add and remove layers.
@property(nonatomic, readonly) WWSceneController* sceneController;

/// The view's navigator.
@property(nonatomic) id <WWNavigator> navigator;

/// The view's viewport, in screen coordinates.
@property(nonatomic, readonly) CGRect viewport;

/// The view's OpenGL frame buffer. Applications typically do not need to be aware of this object.
@property(nonatomic, readonly) GLuint frameBuffer;

/// The view's OpenGL color buffer. Applications typically do not need to be aware of this object.
@property(nonatomic, readonly) GLuint colorBuffer;

/// The view's OpenGL depth buffer. Applications typically do not need to be aware of this object.
@property(nonatomic, readonly) GLuint depthBuffer;

/// The view's OpenGL picking frame buffer. Applications typically do not need to be aware of this object.
@property(nonatomic, readonly) GLuint pickingFrameBuffer;

/// The view's OpenGL picking color buffer. Applications typically do not need to be aware of this object.
@property(nonatomic, readonly) GLuint pickingColorBuffer;

/// The view's OpenGL picking depth buffer. Applications typically do not need to be aware of this object.
@property(nonatomic, readonly) GLuint pickingDepthBuffer;

/// The view's OpenGL context. Applications typically do not need to be aware of this object.
@property(nonatomic, readonly) EAGLContext* context;

/// The view's frame statistics associated with the most recent frame. Frame statistics provides measurements indicating
/// the view's current and average rendering performance.
@property(nonatomic, readonly) WWFrameStatistics* frameStatistics;

/// A flag indicating that a redraw has been requested. Applications typically do not need to be aware of this object.
@property BOOL redrawRequested;

/// Specifies whether the view should redraw itself continuously. This is used only for diagnostics and performance
// statistic gathering and should not be used by the application.
@property(nonatomic) BOOL drawContinuously;

/// @name Redrawing World Wind Views

/**
* Redraw the view. The redraw is performed immediately.
*
* Applications should typically not use this method to redraw, but should call requestRedraw instead.
*/
- (void) drawView;

/**
* Request that the view be redrawn.
*
* This method collapses multiple redraw requests so that the view is not redrawn excessively.
*/
- (void) requestRedraw;

/// @name Picking

/**
* Request the objects at a specified pick point.
*
* @param pickPoint The point to examine, in screen coordinates.
*
* @return The objects at the specified pick point. If the pick point intersects the globe,
* the returned list contains an object identifying the associated geographic position.
*/
- (WWPickedObjectList*) pick:(CGPoint)pickPoint;

/// @name Methods of Interest Only to Subclasses

/**
* Releases the OpenGL objects created when the view was initialized.
*/
- (void) tearDownGL;

/**
* Responds to notifications of interest to the view.
*
* @param notification The notification to respond to.
*/
- (void) handleNotification:(NSNotification*)notification;

@end