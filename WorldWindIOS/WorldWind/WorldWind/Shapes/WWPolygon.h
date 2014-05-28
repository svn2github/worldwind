/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>
#import <OpenGLES/ES2/gl.h>
#import "WorldWind/Shapes/WWAbstractShape.h"

@class WWPolygonTessellator;

/**
* Displays a polygon who's vertices are specified by an array of positions. Polygons have separate attributes for normal
* display and highlighted display. If no attributes are specified, default attributes are used.
*
* The polygon's positions are interpreted as indicating the polygon's outer boundary, and describe an arbitrary
* polygonal shape drawn according to the current shape attributes. A polygon may be configured with one or more holes
* by adding an inner boundary using [WWPolygon addInnerBoundary:]. Inner boundaries placed inside the polygon's
* positions cause the inner region to be removed from the polygon's filled interior, while inner boundaries placed
* inside another inner boundary cause the innermost region to be added back to the polygon's filled interior. This makes
* it possible to create polygons with complex interiors, such as a state boundary omitting a lake but including islands
* on that lake. In either case, the winding order of the outer boundary and the inner boundaries is irrelevant.
*
* The positions and inner boundaries may be in any winding order, and need not describe a closed contour. WWPolygon
* correctly displays its outer boundary and its inner boundaries regardless of whether they are arranged in a clockwise
* winding order or a counter-clockwise winding order. Additionally, WWPolygon automatically creates a closed contour
* for its outer boundary and its inner boundaries when necessary.
*
* Altitudes at the polygon's inner boundary vertices and outer boundary vertices are interpreted according to the
* altitude mode. If the altitude mode is WW_ALTITUDE_MODE_ABSOLUTE, the default, the altitudes are considered as height
* above the ellipsoid. If the altitude mode is WW_ALTITUDE_MODE_RELATIVE_TO_GROUND the altitudes are added to the
* elevation of the terrain at each vertex position. If the altitude mode is WW_ALTITUDE_MODE_CLAMP_TO_GROUND the
* altitudes are ignored and the polygon's vertices are drawn on the terrain at that point.
*/
@interface WWPolygon : WWAbstractShape
{
@protected
    // Variables supporting polygon attributes.
    NSMutableArray* boundaries; // the polygon's outer and inner boundaries
    WWVec4* referenceNormal;

    // Data structures used during polygon tessellation.
    WWPolygonTessellator* tess;
    NSMutableArray* tessVertices;

    // Data structures submitted to OpenGL during rendering.
    GLsizei vertexCount; // the number of vertices in the vertex array
    GLsizei vertexStride; // the number of floats between two vertices in the vertex array
    GLfloat* vertices; // the vertex array
    GLsizei indexCount; // the number of values in the index array
    GLushort* indices; // the index array
    NSRange interiorIndexRange; // the range of interior indices in the index array
    NSRange outlineIndexRange; // the range of outline indices in the index array
}

/// @name Attributes

/**
* Returns an array indicating the polygon's outer boundary positions.
*
* @return The positions indicating the polygon's outer boundary vertices.
*/
- (NSArray*) positions;

/**
* Sets this polygon's outer boundary vertices to the positions in the specified array. See the class level documentation
* for information on how vertex positions are interpreted.
*
* @param positions The positions indicating the polygon's outer boundary vertices.
*
* @exception NSInvalidArgumentException If the specified positions array is nil.
*/
- (void) setPositions:(NSArray*)positions;

/**
* Returns an array of arrays indicating the polygon's inner boundaries. The returned array is empty if this polygon has
* no inner boundaries.
*
* @return An array of NSArray instances indicating the polygon's inner boundaries.
*/
- (NSArray*) innerBoundaries;

/**
* Adds an inner boundary using the positions in the specified array. See the class level documentation for information
* on how vertex positions are interpreted.
*
* @param positions The positions indicating the new inner boundary vertices.
*
* @exception NSInvalidArgumentException If the specified positions array is nil.
*/
- (void) addInnerBoundary:(NSArray*)positions;

/// @name Initializing Polygons

/**
* Initializes a polygon with its outer boundary vertices set to the specified positions. See the class level
* documentation for information on how vertex positions are interpreted.
*
* @param positions The positions indicating the polygon's outer boundary vertices.
*
* @return This polygon initialized with the specified outer boundary vertices.
*
* @exception NSInvalidArgumentException If the specified positions array is nil.
*/
- (WWPolygon*) initWithPositions:(NSArray*)positions;

/// @name Methods of Interest Only to Subclasses

- (void) tessellatePolygon:(WWDrawContext*)dc;

- (void) tessellatePolygon:(WWDrawContext*)dc combineVertex:(double)x y:(double)y z:(double)z outIndex:(GLushort*)outIndex;

- (void) makeRenderedPolygon:(WWDrawContext*)dc;

@end