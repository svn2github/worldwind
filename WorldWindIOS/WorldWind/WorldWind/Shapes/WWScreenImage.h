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
@class WWOffset;
@class WWPickedObject;
@class WWPickSupport;
@class WWSize;
@class WWTexture;
@class WWVec4;

/**
* Provides a shape that draws an image in the plane of the screen at a specified screen location and offset from that
* screen location.
*/
@interface WWScreenImage : NSObject <WWOrderedRenderable>
{
@protected
    // Rendering attributes.
    WWMatrix* mvpMatrix;
    WWMatrix* texCoordMatrix;
    WWTexture* texture;
    // Picking attributes.
    WWPickSupport* pickSupport;
    WWLayer* pickLayer;
}

/// @name Attributes

/// This shape's display name.
@property (nonatomic) NSString* displayName;

/// Indicates whether the shape should be drawn.
@property (nonatomic) BOOL enabled;

/// The screen location at which to draw the image.
@property (nonatomic) WWOffset* screenOffset;

/// The full path to the image file to display.
@property (nonatomic) NSString* imagePath;

/// The color to apply to the image background.
@property (nonatomic) WWColor* imageColor;

/// The offset of the image from the specified screen location.
@property (nonatomic) WWOffset* imageOffset;

/// The size in which to draw the image.
@property (nonatomic) WWSize* imageSize;

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

/// @name Initializing Screen Images

- (WWScreenImage*) initWithScreenOffset:(WWOffset*)screenOffset imagePath:(NSString*)imagePath;

/// @name Methods of Interest Only to Subclasses

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
* Creates a texture for the image.
*
* @param dc The current draw context.
*/
- (void) assembleActiveTexture:(WWDrawContext*)dc;

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