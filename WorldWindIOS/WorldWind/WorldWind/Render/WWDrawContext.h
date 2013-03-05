/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>
#import <OpenGLES/ES2/gl.h>

@class WWGlobe;
@class WWLayerList;
@class WWTerrainTileList;
@class WWSector;
@class WWGpuProgram;
@class WWSurfaceTileRenderer;
@class WWGpuResourceCache;
@class WWPosition;
@class WWMatrix;
@protocol WWNavigatorState;
@protocol WWExtent;
@protocol WWOrderedRenderable;
@protocol WWOutlinedShape;
@protocol WWTerrain;

/**
* Provides current state during rendering. The current draw context is passed to most rendering methods in order to
* make those methods aware of current state.
*/
@interface WWDrawContext : NSObject

/// @name Draw Context Attributes

/// The time at which this draw context was most recently reset or initialized. This is the time at which the current
/// frame started.
@property(readonly, nonatomic) NSDate* timestamp;

/// The globe being rendered.
@property(nonatomic) WWGlobe* globe;

/// The current layer list.
@property(nonatomic) WWLayerList* layers;

/// The current navigator state. This state contains the current viewing information.
@property(nonatomic) id <WWNavigatorState> navigatorState;

/// The current set of terrain tiles visible in the frame. This set enables more precise determination of the
/// geographic area visible in the current frame than can be determined from the visibleSector field.
@property(nonatomic) WWTerrainTileList* surfaceGeometry;

/// The union of all the terrain tile sectors. This is a very gross measure of the visible geographic area.
@property(nonatomic) WWSector* visibleSector;

/// The GPU program currently established with OpenGL.
@property(nonatomic) WWGpuProgram* currentProgram;

/// The current vertical exaggeration, as specified by the application to the scene controller, WWSceneController.
@property(nonatomic) double verticalExaggeration;

/// The current renderer used to draw terrain tiles and the imagery placed on them.
@property(readonly, nonatomic) WWSurfaceTileRenderer* surfaceTileRenderer;

/// The cache containing all currently active GPU resources such as textures, programs and vertex buffers. This is an
/// LRU cache. It assumes the responsibility of freeing GPU resources when they are evicted from the cache.
@property(nonatomic) WWGpuResourceCache* gpuResourceCache;

/// The current eye position.
@property(nonatomic, readonly) WWPosition* eyePosition;

/// Indicates whether the scene controller is in ordered rendering mode.
@property(nonatomic) BOOL orderedRenderingMode;

/// The current tessellated terrain.
@property(nonatomic, readonly) id <WWTerrain> terrain;

@property NSMutableArray* orderedRenderables;

/// The modelview-projection matrix appropriate for displaying objects in screen coordinates. This matrix has the effect
/// of preserving coordinates that have already been projected using [WWNavigatorState project:result:]. The XY screen
/// coordinates are interpreted as literal screen coordinates and the Z coordinate is interpeted as a depth value.
@property(nonatomic, readonly) WWMatrix* screenProjection;

/// @name Initializing a Draw Context

/**
* Initializes a draw context.
*
* @return This draw context initialized to empty values.
*/
- (WWDrawContext*) init;

/// @name Operations on Draw Context

/**
* Reinitialize certain draw context fields to default values.
*
* The reinitialized fields and their defaults are:
*
* - timestamp (the current time)
* - verticalExaggeration (1)
*/
- (void) reset;

/**
* The last draw context method called by the scene controller after the draw context state is set but prior to
* rendering.
*
* This method updates the draw context's fields as necessary to reflect viewing and other state that was set since
* the most recent call to update. The draw context computes, for example, the eye position from the just set
* navigation state.
*/
- (void) update;

/**
* Indicates whether a specified extent is smaller than a specified number of pixels.
*
* This method is typically used to avoid drawing shapes that are too small to be seen.
*
* @param extent The extent to test.
* @param numPixels The threshold number of pixels at or below which the extent is considered small.
*
* @return YES if the shape is determined to be small or the specified extent is nil, otherwise NO.
*/
- (BOOL) isSmall:(id <WWExtent>)extent numPixels:(int)numPixels;

/**
* Draw the specified shape, potentially using a multi-path algorithm to coordinate the proper drawing of the shape's
* outline over its interior.
*
* @param shape The shape to draw.
*
* @exception NSInvalidArgumentException If the specified shape is nil.
*/
- (void) drawOutlinedShape:(id <WWOutlinedShape>)shape;


/// @name Ordered Renderable Operations on Draw Context

/**
* Adds a specified shape to the scene controller's ordered renderable list.
*
* @param orderedRenderable The shape to add to the ordered renderable list. May be nil, in which case the ordered
* renderable list is not modified.
*/
- (void) addOrderedRenderable:(id <WWOrderedRenderable>)orderedRenderable;

/**
* Adds a specified shape to the back of the scene controller's ordered renderable list.
*
* @param orderedRenderable The shape to add to the ordered renderable list. May be nil, in which case the ordered
* renderable list is not modified.
*/
- (void) addOrderedRenderableToBack:(id <WWOrderedRenderable>)orderedRenderable;

@end