/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WorldWind/Render/WWRenderable.h"
#import "WorldWind/Util/WWDisposable.h"

@class WWDrawContext;
@class WWScreenImage;

/**
* Provides the base instance for a layer. This class is meant to be subclassed and provides no independent
* functionality of its own.
*/
@interface WWLayer : NSObject <WWRenderable, WWDisposable>

/// @name Attributes

/// The name to use when displaying the layer in the layer manager and other text locations. The default is _Layer_.
@property(nonatomic) NSString* displayName;

/// Indicates whether the layer should be displayed.
@property(nonatomic) BOOL enabled;

/// Indicates whether the layer currently participates in picking.
@property(nonatomic) BOOL pickEnabled;

/// Indicates the layer's opacity. 1 indicates full opacity. 0 indicates full transparency. Not all layers support
// opacity.
@property(nonatomic) float opacity;

/// The minimum eye altitude at which the layer is displayed. The layer is not displayed when the eye altitude is
// less than the specified value.
@property(nonatomic) double minActiveAltitude;

/// The maximum eye altitude at which the layer is displayed. The layer is not displayed when the eye altitude is
// greater than the specified value.
@property(nonatomic) double maxActiveAltitude;

/// Indicates whether the layer may retrieve resources from the network.
@property(nonatomic) BOOL networkRetrievalEnabled;

/// Indicates the name of the image file for this layer. The image is shown in the layer list.
@property(nonatomic) NSString* imageFile;

/// Provides a dictionary for the application to associate arbitrary data with the layer. World Wind makes no
/// explicit use of this property or its contents, which are entirely application dependent.
@property(nonatomic, readonly) NSMutableDictionary* userTags;

/// Indicates whether the layer's legend, if any, is displayed.
@property (nonatomic) BOOL legendEnabled;

/// @name Initializing Layers

/**
* Initialize the layer.
*
* Subclasses must call this method from their initializers.
*/
- (WWLayer*) init;

/// @name Operations on Layers

/**
* Draw the layer.
*
* This method should typically not be overridden by subclasses. It determines whether the layer is enabled and likely
 * to be visible. If so, the layer's doRender method is called. That method is implemented by subclasses to perform
 * the actual rendering.
*
* @param dc The current draw context.
*/
- (void) render:(WWDrawContext*)dc;

/// @name Methods of Interest Only to Subclasses

/**
* Method to be implemented by subclasses to draw the layer. The default implementation returns without performing any
 * operations.
 *
 * @param dc The current draw context.
*/
- (void) doRender:(WWDrawContext*)dc;

/**
* Indicates whether the current eye altitude is within the layer's minimum and maximum eye altitudes.
*
* @param dc The current draw context.
*/
- (BOOL) isLayerActive:(WWDrawContext*)dc;

/**
* Indicates whether the layer is potentially within view.
*
* @param dc The current draw context.
*
* This method should typically be overridden by subclasses that perform the actual visibility test (or tests). The
* default implementation always returns YES.
*
* @param dc The current draw context.
*/
- (BOOL) isLayerInView:(WWDrawContext*)dc;

@end
