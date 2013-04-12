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

///  @name Renderable Attributes

/// This renderable's display name.
@property(nonatomic) NSString* displayName;

/// Indicates whether this renderable should be displayed.
@property(nonatomic) BOOL enabled;

/// @name Drawing Renderables

/**
* Draw this instance.
*
* @param dc The current draw context.
*/
- (void) render:(WWDrawContext*)dc;

@end