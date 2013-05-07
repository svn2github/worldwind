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
@class WWVec4;
@class WWPickedObjectList;

/**
* Directs the rendering of the globe and associated layers. The scene controller causes the globe's terrain to be
* generated and the layer list to be traversed and the layers drawn in their listed order. The scene controller
* resets the draw context prior to each frame and otherwise manages the draw context. (The draw context maintains
* rendering state. See WWDrawContext.)
*/
@interface WWSceneController : NSObject
{
@protected
    WWDrawContext* drawContext;
}

/// @name Scene Controller Attributes

/// The globe to display.
@property(readonly, nonatomic) WWGlobe* globe;
/// The layers to display. Layers are displayed in the order given in the layer list.
@property(readonly, nonatomic) WWLayerList* layers;
/// The current navigator state defining the current viewing state.
@property(nonatomic) id <WWNavigatorState> navigatorState;
/// The GPU resource cache in which to hold and manage all OpenGL resources.
@property(readonly, nonatomic) WWGpuResourceCache* gpuResourceCache;

/// @name Initializing a Scene Controller

/**
* Initialize the scene controller.
*
* This method allocates and initializes a globe and a layer list and attaches them to this scene controller. It also
* allocates and initializes a GPU resource cache and a draw context.
*
* @return This instance initialized to default values.
*/
- (WWSceneController*) init;

/// @name Initiating Rendering

/**
* Causes the scene controller to render a frame using the current state of its associate globe and layer list.
*
* An OpenGL context must be current when this method is called.
*
* @param viewport The viewport in which to draw the globe.
*/
- (void) render:(CGRect)viewport;

/// @name Operations on Scene Controller

/**
* Release resources currently held by the scene controller.
*
* This scene controller may still be used subsequently.
*/
- (void) dispose;

/// @name Supporting Methods of Interest Only to Subclasses

/**
* Reset the draw context to its default values.
*
* This method is not meant to be called by applications. It is called internally as needed. Subclasses may override
* this method to implement alternate or additional behavior.
*/
- (void) resetDrawContext;

/**
* Top-level method called by render to generate the frame.
*
* This method is not meant to be called by applications. It is called internally as needed. Subclasses may override
* this method to implement alternate or additional behavior.
*
* @param viewport The viewport in which to draw the globe.
*/
- (void) drawFrame:(CGRect)viewport;

/**
* Establishes default OpenGL state for rendering the frame.
*
* @param viewport The viewport in which to draw the globe.
*
* This method is not meant to be called by applications. It is called internally as needed. Subclasses may override
* this method to implement alternate or additional behavior.
*/
- (void) beginFrame:(CGRect)viewport;

/**
* Resets OpenGL state to OpenGL defaults after the frame is generated.
*
* This method is not meant to be called by applications. It is called internally as needed. Subclasses may override
* this method to implement alternate or additional behavior.
*/
- (void) endFrame;

/**
* Invokes glClear to clear the frame buffer and depth buffer.
*
* This method is not meant to be called by applications. It is called internally as needed. Subclasses may override
* this method to implement alternate or additional behavior.
*/
- (void) clearFrame;

/**
* Causes the globe to create the terrain visible with the current viewing state.
*
* This method is not meant to be called by applications. It is called internally as needed. Subclasses may override
* this method to implement alternate or additional behavior.
*/
- (void) createTerrain;

/**
* Renders the layer list and the list of ordered renderables.
*
* This method is not meant to be called by applications. It is called internally as needed. Subclasses may override
* this method to implement alternate or additional behavior.
*/
- (void) doDraw;

/**
* Low-level method to traverse the layer list and call each layer's render method.
*
* This method is not meant to be called by applications. It is called internally as needed. Subclasses may override
* this method to implement alternate or additional behavior.
*/
- (void) drawLayers;

/**
* Traverses the list of ordered renderables and calls their render method.
*
* This method is not meant to be called by applications. It is called internally as needed. Subclasses may override
* this method to implement alternate or additional behavior.
*/
- (void) drawOrderedRenderables;

/**
* Performs a pick of the current model. Traverses the terrain to determine the geographic position at the specified
* pick point, and traverses pickable shapes to determine which intersect the pick point.
*
* This method is not meant to be called by applications. It is called internally as needed. Subclasses may override
* this method to implement alternate or additional behavior.
*
* @param viewport The viewport in which to perform the pick.
* @param pickPoint The screen coordinate point to test for pickable items. Only the X and Y coordinates are used.
*
* @return The list of picked items, which is empty if no items are at the specified pick point or the pick point is
* nil.
*/
- (WWPickedObjectList*) pick:(CGRect)viewport pickPoint:(WWVec4*)pickPoint;
@end