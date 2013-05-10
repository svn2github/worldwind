/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WorldWind/Shapes/WWOutlinedShape.h"
#import "WorldWind/Render/WWOrderedRenderable.h"

@class WWShapeAttributes;
@class WWMatrix;
@class WWColor;
@class WWVec4;
@class WWPosition;
@protocol WWExtent;
@class WWDrawContext;
@class WWGpuProgram;
@class WWGpuResourceCache;
@class WWGlobe;
@class WWPickSupport;
@class WWLayer;

/**
* The base class for most 3D shapes. This class is intended to be abstract and therefore requires subclasses to
* implement specific drawing behavior.
*/
@interface WWAbstractShape : NSObject <WWOutlinedShape, WWOrderedRenderable>
{
@protected
    WWShapeAttributes* defaultAttributes;
    WWShapeAttributes* activeAttributes;
    WWMatrix* transformationMatrix; // positions the shape's local coordinates into world coordinates
    WWVec4* referencePoint; // the shape's local-coordinate origin.
    double verticalExaggeration; // the vertical exaggeration last used to create the shape's Cartesian representation
    NSString* _altitudeMode;
    WWPickSupport* pickSupport;
    WWLayer* pickLayer;
}

/// @name Shape Attributes

/// This shape's display name.
@property (nonatomic) NSString* displayName;

/// The appearance attributes applied to the shape when it is not highlighted.
@property(nonatomic) WWShapeAttributes* attributes;

/// The appearance attributes applied to the shape when it is highlighted.
@property(nonatomic) WWShapeAttributes* highlightAttributes;

/// Indicates whether the shape should be drawn with its highlight attributes.
@property(nonatomic) BOOL highlighted;

/// Indicates whether the shape should be drawn.
@property(nonatomic) BOOL enabled;

/// Indicates the shapes relationship to the globe and terrain. One of WW_ALTITUDE_MODE_ABSOLUTE,
/// WW_ALTITUDE_MODE_RELATIVE_TO_GROUND or WW_ALTITUDE_MODE_CLAMP_TO_GROUND.
@property(nonatomic) NSString* altitudeMode;

/// The object to return as this shape's picked-object parent when this shape is picked.
@property(nonatomic) id delegateOwner;

/// The position of this shape's local coordinate system.
@property(nonatomic) WWPosition* referencePosition;

/// The minimum distance of this shape from the eye point. This value changes potentially every frame and is calculated
/// during frame generation. Applications should not specify this value. It is meant to be set only by subclasses.
@property(nonatomic) double eyeDistance;

/// This shape's Cartesian extent. This value changes potentially every frame and is calculated during frame
// generation. Applications should not specify this value. It is meant to be set only be subclasses.
@property(nonatomic) id <WWExtent> extent;

/// The time at which this shape was most recently inserted into the draw context's ordered renderable list. This value
/// is set by the draw context and should not be set by applications or subclasess. It is a method of the
/// WWWOrderedRenderable protocol.
@property(nonatomic) NSTimeInterval insertionTime;

/// @name Methods of Interest Only to Subclasses

/**
* Initialize this shape.
*
* This method should be called by subclasses within their initialization methods.
*
* @return This shape, initialized.
*/
- (WWAbstractShape*) init;

/**
* Invalidates any computed data this shape may have.
*
* This method is intended to be called by subclasses when aspects of this shape are
* re-specified by the application and require the Cartesian representation of the shape to be recomputed.
*/
- (void) reset;

/**
* Called during initialization in order to give a subclass the opportunity to set the default attributes,
* which are used when the application has not set the normal attributes.
*/
- (void) setDefaultAttributes;

/**
* Prepares this shape's basic OpenGL state for rendering and calls doDrawOrderedRenderable.
*
* Subclasses should generally not override this method but override doDrawOrderedRenderable instead.
*
* This method also restores the OpenGL state it set prior to returning.
*
* @param dc The current draw context.
*/
- (void) drawOrderedRenderable:(WWDrawContext*)dc;

/**
* Called by this base class to cause the subclass to render this shape.
*
* When this method is called the subclass should draw the shape. The draw context will be in ordered rendering mode,
* meaning that shapes are being drawn back to front and it is now this shape's turn to draw itself.
*
* @param dc The current draw context.
*/
- (void) doDrawOrderedRenderable:(WWDrawContext*)dc;

/**
* Causes the Cartesian form of this shape to be created.
*
* Subclasses should generally not override this method but instead override doMakeOrderedRenderable.
*
* @param dc The current draw context.
*/
- (void) makeOrderedRenderable:(WWDrawContext*)dc;

/**
* Called by this base class to cause the subclass to generate the shape's Cartesian geometry.
*
* In addition to creating the shape's geometry, this method should also compute and set the shape's reference point
* and extent.
*
* @param dc The current draw context.
*/
- (void) doMakeOrderedRenderable:(WWDrawContext*)dc;

/**
* Determines the attributes to apply -- normal, highlight or default -- during a single frame.
*/
- (void) determineActiveAttributes;

/**
* Indicates whether this shape must generate or regenerate its Cartesian geometry.
*
* When this method returns YES, this base class calls makeOrderedRenderable,
* which in turn calls doMakeOrderedRenderable.
*
* @param dc The current draw context.
*/
- (BOOL) mustRegenerateGeometry:(WWDrawContext*)dc;

/**
* Indicates whether the ordered renderable should be drawn.
*
* This method is called during drawOrderedRenderable. Subclasses should return YES if the shape was successfully
* generated and can be drawn immediately.
*
* @param dc The current draw context.
*/
- (BOOL) isOrderedRenderableValid:(WWDrawContext*)dc;

/**
* Indicates whether this shape's interior should be drawn.
*/
- (BOOL) mustDrawInterior;

// Indicates whether this shape's outline should be drawn.
- (BOOL) mustDrawOutline;

/**
* Sets up the genera shape-drawing OpenGL state such as the current program.
*
* @param dc The current draw context.
*/
- (void) beginDrawing:(WWDrawContext*)dc;

/**
* Restores the OpenGL state set in beginDrawing.
*
* @param dc The current draw context.
*/
- (void) endDrawing:(WWDrawContext*)dc;

/**
* Called the base class to instruct the subclass to pass this shape's transformation matrix to OpenGL.
*
* The transformation matrix maps this shape's local coordinates to world coordinates.
*
* @param dc The current draw context.
*/
- (void) applyModelviewProjectionMatrix:(WWDrawContext*)dc;

/**
* Establishes the OpenGL state for the interior attributes.
*
* Subclasses may override this method to set additional attributes but should call this base class method as well.
*
* @param dc The current draw context.
* @param attributes The attributes to use when drawing the interior.
*/
- (void) prepareToDrawInterior:(WWDrawContext*)dc attributes:(WWShapeAttributes*)attributes;

/**
* Establishes the OpenGL state for the outline attributes.
*
* Subclasses may override this method to set additional attributes but should call this base class method as well.
*
* @param dc The current draw context.
* @param attributes The attributes to use when drawing the outline.
*/
- (void) prepareToDrawOutline:(WWDrawContext*)dc attributes:(WWShapeAttributes*)attributes;

/**
* Called by this base class to instruct the subclass to draw its shape's interior.
*
* @param dc The current draw context.
*/
- (void) doDrawInterior:(WWDrawContext*)dc;

/**
* Called by this base class to instruct the subclass to draw its shape's outline.
*
* @param dc The current draw context.
*/
- (void) doDrawOutline:(WWDrawContext*)dc;

@end