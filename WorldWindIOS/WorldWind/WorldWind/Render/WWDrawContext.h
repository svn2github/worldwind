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
@protocol WWNavigatorState;
@class WWPosition;

/**
* Provides current state during rendering. The current draw context is passed to most rendering methods in order to
* make those methods aware of current state.
*/
@interface WWDrawContext : NSObject

/// @name Draw Context Attributes

/// The time at which this draw context was most recently reset or initialized. This is the time at which the current
/// frame started.
@property (readonly, nonatomic) NSDate* timestamp;

/// The globe being rendered.
@property (nonatomic) WWGlobe* globe;

/// The current layer list.
@property (nonatomic) WWLayerList* layers;

/// The current navigator state. This state contains the current viewing information.
@property (nonatomic) id <WWNavigatorState> navigatorState;

/// The current set of terrain tiles visible in the frame. This set enables more precise determination of the
/// geographic area visible in the current frame than can be determined from the visibleSector field.
@property (nonatomic) WWTerrainTileList* surfaceGeometry;

/// The union of all the terrain tile sectors. This is a very gross measure of the visible geographic area.
@property (nonatomic) WWSector* visibleSector;

/// The GPU program currently established with OpenGL.
@property (nonatomic) WWGpuProgram* currentProgram;

/// The current vertical exaggeration, as specified by the application to the scene controller, WWSceneController.
@property (nonatomic) double verticalExaggeration;

/// The current renderer used to draw terrain tiles and the imagery placed on them.
@property (readonly, nonatomic) WWSurfaceTileRenderer* surfaceTileRenderer;

/// The cache containing all currently active GPU resources such as textures, programs and vertex buffers. This is an
/// LRU cache. It assumes the responsibility of freeing GPU resources when they are evicted from the cache.
@property (nonatomic) WWGpuResourceCache* gpuResourceCache;

@property (nonatomic, readonly) WWPosition* eyePosition;

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

@end
