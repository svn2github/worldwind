/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WorldWind/Layer/WWRenderableLayer.h"

/**
* Provides a compass display in the upper right corner of the screen. The compass tracks the navigator's current
* heading and tilt.
*/
@interface CompassLayer : WWRenderableLayer

/// @name Initializing Compass Layer

/**
* Initialize the layer.
*
* @return The initialized layer.
*/
- (CompassLayer*) init;

@end