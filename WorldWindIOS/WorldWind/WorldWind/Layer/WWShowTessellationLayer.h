/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WorldWind/Layer/WWLayer.h"

@class WWGpuProgram;
@class WWDrawContext;

/**
* Draws a wireframe representation of the globe, identifying aspects of the terrain tessellation.
*/
@interface WWShowTessellationLayer : WWLayer

/// @name WWShowTessellationLayer Attributes

/// This layer's GPU program used to render the wireframe globe.
@property (readonly, nonatomic) WWGpuProgram* gpuProgram;

/// @name Initializing

/**
* Initializes the layer.
*
* @return This layer, initialized.
*/
- (WWShowTessellationLayer*) init;

/// @name Supporting Methods of Interest to Subclasses

/**
* Called just prior to rendering the wireframe representation in order to bind the GPU program.
*
* This method is not intended to be called by applications. It is called internally as necessary.
*
* @param dc The current draw context.
*/
- (void) beginRendering:(WWDrawContext*)dc;

/**
* Called just after rendering the wireframe representation in order to unbind the GPU program.
*
* This method is not intended to be called by applications. It is called internally as necessary.
*
* @param dc The current draw context.
*/
- (void) endRendering:(WWDrawContext*)dc;

/**
* Called to create the GPU program used to render the wireframe representation.
*
* This method is not intended to be called by applications. It is called internally as necessary.
*/
- (void) makeGpuProgram;

@end