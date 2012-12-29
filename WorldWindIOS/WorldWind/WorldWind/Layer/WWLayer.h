/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WorldWind/Render/WWRenderable.h"

@class WWDrawContext;

/**
* Provides the base instance for a layer.
*/
@interface WWLayer : NSObject <WWRenderable>

/// @name Operations on Layers

/**
* Draw the layer.
*
* @param dc The current draw context.
*/
- (void) render:(WWDrawContext *)dc;

@end
