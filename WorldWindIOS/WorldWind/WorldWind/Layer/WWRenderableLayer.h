/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WorldWind/Layer/WWLayer.h"

@protocol WWRenderable;

/**
* Provides a layer to hold renderables.
*/
@interface WWRenderableLayer : WWLayer

/// @name Renderable Layer Attributes

/// The list of renderables associated with this layer.
@property (nonatomic, readonly) NSMutableArray* renderables;

/// @name Initializing Renderable Layers

/**
* Initialize this renderable layer.
*
* @return This layer, initialized.
*/
- (WWRenderableLayer*) init;

/// @name Operations on Renderable Layers

/**
* Add a specified renderable to this layer.
*
* The renderable is added to the end of this layer's renderable list.
*
* @param renderable The renderable to add.
*
* @exception NSInvalidArgumentException If the specified renderable is nil.
*/
- (void) addRenderable:(id <WWRenderable>)renderable;

/**
* Add a specified list of renderables to this layer.
*
* The renderables are added to the end of this layer's renderable list.
*
* @param renderables The renderables to add.
*
* @exception NSInvalidArgumentException If the specified renderable list is nil.
*/
- (void) addRenderables:(NSArray*)renderables;

/**
* Remove a specified renderable from this layer.
*
* @param renderable The renderable to remove.
*
* @exception NSInvalidArgumentException if the specified renderable is nil.
*/
- (void) removeRenderable:(id <WWRenderable>)renderable;

/**
* Removes all renderables from this layer.
*/
- (void) removeAllRenderables;

@end