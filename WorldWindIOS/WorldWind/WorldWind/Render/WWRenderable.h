/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

@class WWDrawContext;

/**
* Provides a method to draw an instance conforming to this protocol.
*/
@protocol WWRenderable

/// @name Drawing Renderables

/**
* Draw this instance.
*
* @param dc The current draw context.
*/
- (void) render:(WWDrawContext*)dc;

@end