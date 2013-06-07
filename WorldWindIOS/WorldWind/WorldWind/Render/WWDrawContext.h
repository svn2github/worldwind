/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>
#import <CoreGraphics/CGGeometry.h>
#import <OpenGLES/ES2/gl.h>

@class WWGlobe;
@class WWLayerList;
@class WWTerrainTileList;
@class WWSector;
@class WWGpuProgram;
@class WWSurfaceTileRenderer;
@class WWGpuResourceCache;
@class WWPosition;
@class WWMatrix;
@protocol WWNavigatorState;
@protocol WWExtent;
@protocol WWOrderedRenderable;
@protocol WWOutlinedShape;
@protocol WWTerrain;
@class WWVec4;
@class WWPickedObject;
@class WWPickedObjectList;
@class WWTerrainTile;
@class WWLayer;

/**
* Provides current state during rendering. The current draw context is passed to most rendering methods in order to
* make those methods aware of current state.
*/
@interface WWDrawContext : NSObject
{
@protected
    NSMutableArray* orderedRenderables; // ordered renderable queue
    NSString* defaultProgramKey; // cache key for the default program
    NSString* defaultTextureProgramKey; // cache key for the default texture program
    NSString* unitQuadKey; // cache key for the unit quadrilateral VBO
    unsigned int uniquePickNumber; // incrementing pick number for pick color
}

/// @name Draw Context Attributes

/// The time at which this draw context was most recently reset or initialized. This is the time at which the current
/// frame started.
@property(readonly, nonatomic) NSDate* timestamp;

/// The globe being rendered.
@property(nonatomic) WWGlobe* globe;

/// The current layer list.
@property(nonatomic) WWLayerList* layers;

/// The current navigator state. This state contains the current viewing information.
@property(nonatomic) id <WWNavigatorState> navigatorState;

/// The current set of terrain tiles visible in the frame. This set enables more precise determination of the
/// geographic area visible in the current frame than can be determined from the visibleSector field.
@property(nonatomic) WWTerrainTileList* surfaceGeometry;

/// The union of all the terrain tile sectors. This is a very gross measure of the visible geographic area.
@property(nonatomic) WWSector* visibleSector;

/// The GPU program currently established with OpenGL.
@property(nonatomic) WWGpuProgram* currentProgram;

/// The current vertical exaggeration, as specified by the application to the scene controller, WWSceneController.
@property(nonatomic) double verticalExaggeration;

/// The current renderer used to draw terrain tiles and the imagery placed on them.
@property(readonly, nonatomic) WWSurfaceTileRenderer* surfaceTileRenderer;

/// The cache containing all currently active GPU resources such as textures, programs and vertex buffers. This is an
/// LRU cache. It assumes the responsibility of freeing GPU resources when they are evicted from the cache.
@property(nonatomic) WWGpuResourceCache* gpuResourceCache;

/// The current eye position.
@property(nonatomic, readonly) WWPosition* eyePosition;

/// Indicates whether the scene controller is in ordered rendering mode.
@property(nonatomic) BOOL orderedRenderingMode;

/// The current tessellated terrain.
@property(nonatomic, readonly) id <WWTerrain> terrain;

/// The modelview-projection matrix appropriate for displaying objects in screen coordinates. This matrix has the effect
/// of preserving coordinates that have already been projected using [WWNavigatorState project:result:]. The xy screen
/// coordinates are interpreted as literal screen coordinates and the z coordinate is interpeted as a depth value.
@property(nonatomic, readonly) WWMatrix* screenProjection;

/// The packed 32-but unsigned RGBA integer identifying the view's clear color.
@property(nonatomic) GLuint clearColor;

/// Indicates whether this frame is generating a pick rather than displaying.
@property(nonatomic) BOOL pickingMode;

/// The current pick point as specified by the application, in UIKit screen coordinates.
///
/// The pick point is understood to be in the UIKit coordinate system of the WorldWindView, with its origin in the
/// top-left corner and axes that extend down and to the right from the origin point. See the section titled View
/// Geometry and Coordinate Systems in the [View Programming Guide for iOS](http://developer.apple.com/library/ios/#documentation/WindowsViews/Conceptual/ViewPG_iPhoneOS/WindowsandViews/WindowsandViews.html).
@property(nonatomic) CGPoint pickPoint;

/// The pickable objects intersecting the pick point, including the terrain.
@property(nonatomic, readonly) WWPickedObjectList* objectsAtPickPoint;

/// The current layer being rendered.
@property (nonatomic) WWLayer* currentLayer;

/**
* Binds and returns the default program, creating it if it doesn't already exist.
*
* The default program draws geometry in a single solid color. The following uniform variables and attributes are
* exposed:
*
* *Uniforms*
*
* - mat4 mvpMatrix - The modelview-projection matrix used to transform the vertexPoint attribute.
* - vec4 color - The RGBA color used to draw the geometry.
*
* *Attributes*
*
* - vec4 vertexPoint - The geometry's vertex points, in model coordinates.
*
* @return The default program.
*/
- (WWGpuProgram*) defaultProgram;

/**
* Binds and returns the default texture program, creating it if it doesn't already exist.
*
* The default texture program draws geometry in a single solid color with an optional texture. When the texture is
* enabled the final fragment color is determined by multiplying the texture color with the solid color. The following
* uniform variables and attributes are exposed:
*
* *Uniforms*
*
* - mat4 mvpMatrix - The modelview-projection matrix used to transform the vertexPoint attribute.
* - vec4 color - The RGBA color used to draw the geometry.
* - bool enableTexture - true to enable the textureSampler; otherwise false.
* - sampler2D textureSampler - The texture unit the texture is bound to (0, 1, 2, etc.), typically 0.
*
* *Attributes*
*
* - vec4 vertexPoint - The geometry's vertex points, in model coordinates.
* - vec4 vertexTexCoord - The geometry's vertex texture coordinates.
*
* @return The default program.
*/
- (WWGpuProgram*) defaultTextureProgram;

/**
* Returns the OpenGL ID for a vertex buffer object representing the points of a unit quad, in local coordinates.
*
* A unit quad has its lower left coordinate at (0, 0) and its upper left coordinate at (1, 1). This buffer object
* contains four xy coordinates defining a unit quad appropriate for display as a triangle strip. Coordinates appear in
* the following order: (0, 1) (0, 0) (1, 1) (1, 0).
*
* *Binding to a Vertex Attribute*
*
* Use the following arguments when binding this buffer object as the source of an OpenGL vertex attribute pointer:
*
* - size: 2
* - type: GL_FLOAT
* - normalized: GL_FALSE
* - stride: 0
* - pointer: 0
*
* *Drawing*
*
* Use the following arguments when drawing this buffer object in OpenGL via glDrawArrays:
*
* - mode: GL_TRIANGLE_STRIP
* - first: 0
* - count: 4
*
* @return An OpenGL ID for the unit quad's vertex buffer object.
*/
- (GLuint) unitQuadBuffer;

/// @name Initializing a Draw Context

/**
* Initializes a draw context.
*
* @return This draw context initialized to empty values.
*/
- (WWDrawContext*) init;

/// @name Operations on Draw Context

/**
* Reinitialize certain draw context fields to default values.
*
* The reinitialized fields and their defaults are:
*
* - timestamp (the current time)
* - verticalExaggeration (1)
*/
- (void) reset;

/**
* The last draw context method called by the scene controller after the draw context state is set but prior to
* rendering.
*
* This method updates the draw context's fields as necessary to reflect viewing and other state that was set since
* the most recent call to update. The draw context computes, for example, the eye position from the just set
* navigation state.
*/
- (void) update;

/**
* Indicates whether a specified extent is smaller than a specified number of pixels.
*
* This method is typically used to avoid drawing shapes that are too small to be seen.
*
* @param extent The extent to test.
* @param numPixels The threshold number of pixels at or below which the extent is considered small.
*
* @return YES if the shape is determined to be small or the specified extent is nil, otherwise NO.
*/
- (BOOL) isSmall:(id <WWExtent>)extent numPixels:(int)numPixels;

/**
* Draw the specified shape, potentially using a multi-path algorithm to coordinate the proper drawing of the shape's
* outline over its interior.
*
* @param shape The shape to draw.
*
* @exception NSInvalidArgumentException If the specified shape is nil.
*/
- (void) drawOutlinedShape:(id <WWOutlinedShape>)shape;

/// @name Ordered Renderable Operations

/**
* Adds a specified renderable to this draw context's ordered renderable list.
*
* @param orderedRenderable The renderable to add to the ordered renderable list. May be nil, in which case the ordered
* renderable list is not modified.
*/
- (void) addOrderedRenderable:(id <WWOrderedRenderable>)orderedRenderable;

/**
* Adds a specified renderable to the back of this draw context's ordered renderable list.
*
* This causes the specified object to be drawn before other ordered renderables.
*
* @param orderedRenderable The renderable to add to the ordered renderable list. May be nil, in which case the ordered
* renderable list is not modified.
*/
- (void) addOrderedRenderableToBack:(id <WWOrderedRenderable>)orderedRenderable;

/**
* Returns the next ordered renderable in this draw context's ordered renderable list without modifying the list.
*
* This returns nil if the ordered renderable list is empty.
*
* @return The next ordered renderable, or nil if the list is empty.
*/
- (id <WWOrderedRenderable>) peekOrderedRenderable;

/**
* Removes and returns the next ordered renderable in this draw context's ordered renderable list.
*
* This returns nil if the ordered renderable list is empty.
*
* @return The next ordered renderable, or nil if the list is empty.
*/
- (id <WWOrderedRenderable>) popOrderedRenderable;

/**
* Sorts this draw context's ordered renderable list in order to prepare it for rendering objects from back to front.
*
* Subsequent calls to peekOrderedRenderable and popOrderedRenderable return objects in back to front order based on
* distance from the viewer's eye point. Two objects with the same eye distance are returned in their relative order in
* the layer list.
*/
- (void) sortOrderedRenderables;

/// @name Picking Operations

/**
* Returns a unique color that can be used to identify picked terrain and shapes.
*
* @return A packed RGBA 32-bit unsigned integer containing the pick color.
*/
- (unsigned int) uniquePickColor;

/**
* Reads and returns the current frame buffer color at the pick point.
*
* The pick point is understood to be in the UIKit coordinate system of the WorldWindView, with its origin in the
* top-left corner and axes that extend down and to the right from the origin point. See the section titled View Geometry
* and Coordinate Systems in the [View Programming Guide for iOS](http://developer.apple.com/library/ios/#documentation/WindowsViews/Conceptual/ViewPG_iPhoneOS/WindowsandViews/WindowsandViews.html).
*
* @param pickPoint The UIKit screen coordinate point to read.
*
* @return A packed RGBA 32-bit unsigned integer identifying the frame buffer color at the pick point.
*/
- (unsigned int) readPickColor:(CGPoint)pickPoint;

/**
* Adds an object to this instance's picked object list.
*
* @param pickedObject The object to add.
*/
- (void) addPickedObject:(WWPickedObject*)pickedObject;

@end