/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>
#import <CoreGraphics/CGGeometry.h>
#import "WorldWind/Render/WWOrderedRenderable.h"

@class WWColor;
@class WWLayer;
@class WWMatrix;
@class WWPickedObject;
@class WWPickSupport;
@class WWPointPlacemarkAttributes;
@class WWPosition;
@class WWTexture;
@class WWVec4;

/**
* Provides a shape to identify individual locations. The location is identified by a single image,
* specified in an associated WWPointPlacemarkAttributes object.
*/
@interface WWPointPlacemark : NSObject <WWOrderedRenderable>
{
@protected
    // Placemark attributes.
    WWPointPlacemarkAttributes* defaultAttributes;
    WWPointPlacemarkAttributes* activeAttributes;
    WWTexture* activeTexture;
    // Placemark geometry.
    WWVec4* placePoint;
    WWMatrix* imageTransform;
    WWMatrix* texCoordMatrix;
    CGRect imageBounds;
    // Picking attributes.
    WWLayer* layer;
}

/// @name Point Placemark Attributes

/// This shape's display name.
@property (nonatomic) NSString* displayName;

/// The appearance attributes applied to the shape when it is not highlighted.
@property (nonatomic) WWPointPlacemarkAttributes* attributes;

/// The appearance attributes applied to the shape when it is highlighted.
@property (nonatomic) WWPointPlacemarkAttributes* highlightAttributes;

/// Indicates whether the shape should be drawn with its highlight attributes.
@property (nonatomic) BOOL highlighted;

/// Indicates whether the shape should be drawn.
@property (nonatomic) BOOL enabled;

/// The shape's geographic position.
@property (nonatomic) WWPosition* position;

/// Indicates the shapes relationship to the globe and terrain. One of WW_ALTITUDE_MODE_ABSOLUTE,
/// WW_ALTITUDE_MODE_RELATIVE_TO_GROUND or WW_ALTITUDE_MODE_CLAMP_TO_GROUND.
@property (nonatomic) NSString* altitudeMode;

/// The object to return as this shape's picked-object parent when this shape is picked.
@property (nonatomic) id pickDelegate;

/// The minimum distance of this shape from the eye point. This value changes potentially every frame and is calculated
/// during frame generation. Applications should not specify this value. It is meant to be set only by subclasses.
@property (nonatomic) double eyeDistance;

/// The time at which this shape was most recently inserted into the draw context's ordered renderable list. This value
/// is set by the draw context and should not be set by applications or subclasess. It is a method of the
/// WWWOrderedRenderable protocol.
@property (nonatomic) NSTimeInterval insertionTime;

/// A field for application-specific use, typically used to associate application data with the shape.
@property (nonatomic) id userObject;

/// @name Initializing Point Placemarks

/**
* Initialize this point placemark and assign its geographic position.
*
* @param position The point placemark's position.
*
* @return This point placemark initialized.
*
* @exception NSInvalidArgumentException if the specified position is nil.
*/
- (WWPointPlacemark*) initWithPosition:(WWPosition*)position;

/// @name Methods of Interest Only to Subclasses

/**
* Causes the shape's default attributes to be initialized. Called only during initialization.
*/
- (void) setDefaultAttributes;

/**
* Creates the geometry and other resources for the shape. Called during rendering.
*
* @param dc The current draw context.
*/
- (void) makeOrderedRenderable:(WWDrawContext*)dc;

/**
* Creates the geometry and other resources for the shape. Called during rendering after the current attributes have
* been determined.
*
* @param dc The current draw context.
*/
- (void) doMakeOrderedRenderable:(WWDrawContext*)dc;

/**
* Determines which set of attributes to apply. Called during makeOrderedRenderable.
*
* @param dc The current draw context.
*/
- (void) determineActiveAttributes:(WWDrawContext*)dc;

/**
* Indicates whether the placemark is visible relative to the current navigator state.
*
* @param dc The current draw context.
*/
- (BOOL) isPlacemarkVisible:(WWDrawContext*)dc;

/**
* Establishes the rendering state and draws the shape.
*
* @param dc The current draw context.
*/
- (void) drawOrderedRenderable:(WWDrawContext*)dc;

/**
* Draws the shape. Called by drawOrderedRenderable after the rendering state is established.
*
* @param dc The current draw context.
*/
- (void) doDrawOrderedRenderable:(WWDrawContext*)dc;

/**
* Draws the shape and any additional point placemark shapes adjacent in the ordererd renderable list. Called by
* drawOrderedRenderable after the rendering state is established.
*
* @param dc The current draw context.
*/
- (void) doDrawBatchOrderedRenderables:(WWDrawContext*)dc;

/**
* Establishes the rendering state.
*
* @param dc The current draw context.
*/
- (void) beginDrawing:(WWDrawContext*)dc;

/**
* Resets the rendering state.
*
* @param dc The current draw context.
*/
- (void) endDrawing:(WWDrawContext*)dc;

/**
* Creates a picked object instance for the shape when picked.
*
* @param dc The current draw context.
* @param colorCode The current pick color code.
*/
- (WWPickedObject*) createPickedObject:(WWDrawContext*)dc colorCode:(unsigned int)colorCode;

@end