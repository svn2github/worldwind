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
* Displays a polygon that encloses a three-dimensional portion of the atmosphere, defined an array of boundary locations
* an upper altitude and a lower altitude. Airspace polygons have separate attributes for normal display and highlighted
* display. If no attributes are specified, default attributes are used.
*
* The airsapce polygon's locations are interpreted as indicating the polygon's outer boundary, and describe an arbitrary
* polygonal shape drawn according to the current shape attributes. An airspace polygon may be configured with one or
* more holes by adding an inner boundary using [WWAirspacePolygon addInnerBoundary:]. Inner boundaries placed inside the
* airspace polygon's locations cause the inner region to be removed from the airspace polygon's filled interior, while
* inner boundaries placed inside another inner boundary cause the innermost region to be added back to the airspace
* polygon's filled interior. This makes it possible to create airspace polygons with complex interiors, such as a state
* boundary omitting a lake but including islands on that lake. In either case, the winding order of the outer boundary
* and the inner boundaries is irrelevant.
*
* The locations and inner boundaries may be in any winding order, and need not describe a closed contour.
* WWAirspacePolygon correctly displays its outer boundary and its inner boundaries regardless of whether they are
* arranged in a clockwise winding order or a counter-clockwise winding order. Additionally, WWAirspacePolygon
* automatically creates a closed contour for its outer boundary and its inner boundaries when necessary.
*
* Airspace polygon enclose the three-dimensional portion of the atmosphere contained within the filled interior and
* between the lowerAltitude and the upperAltitude, inclusive. The lower altitude and the upper altitude at each inner
* boundary vertex and each outer boundary vertex are interpreted according to the lowerAltitudeMode and
* upperAltitudeMode, respectively. If the altitude mode is WW_ALTITUDE_MODE_ABSOLUTE, the default, the altitudes are
* considered as height above the ellipsoid. If the altitude mode is WW_ALTITUDE_MODE_RELATIVE_TO_GROUND the altitudes
* are added to the elevation of the terrain at each vertex position. If the altitude mode is
* WW_ALTITUDE_MODE_CLAMP_TO_GROUND the altitudes are ignored and the polygon's vertices are drawn on the terrain at that
* point. Airspace polygons ignore the altitudeMode attribute inherited from WWAbstractShape.
*/
@interface WWAirspacePolygon : WWAbstractShape
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
* Returns an array indicating the airspace polygon's outer boundary locations.
*
* @return The locations indicating the airspace polygon's outer boundary vertices.
*/
- (NSArray*) locations;

/**
* Sets this airspace polygon's outer boundary vertices to the locations in the specified array. See the class level
* documentation for information on how vertex locations are interpreted.
*
* @param locations The locations indicating the airspace polygon's outer boundary vertices.
*
* @exception NSInvalidArgumentException If the specified locations array is nil.
*/
- (void) setLocations:(NSArray*)locations;

/**
* Returns an array of arrays indicating the airspace polygon's inner boundaries. The returned array is empty if this
* airspace polygon has no inner boundaries.
*
* @return An array of NSArray instances indicating the airspace polygon's inner boundaries.
*/
- (NSArray*) innerBoundaries;

/**
* Adds an inner boundary using the locations in the specified array. See the class level documentation for information
* on how vertex locations are interpreted.
*
* @param locations The locations indicating the new inner boundary vertices.
*
* @exception NSInvalidArgumentException If the specified locations array is nil.
*/
- (void) addInnerBoundary:(NSArray*)locations;

/// The lower altitude boundary of the three-dimensional portion of the atmosphere enclosed by this airspace polygon,
/// interpreted according to the lowerAltitudeMode. See the class level documentation for information on how altitudes
/// are interpreted.
@property (nonatomic) double lowerAltitude;

/// The upper altitude boundary of the three-dimensional portion of the atmosphere enclosed by this airspace polygon,
/// interpreted according to the upperAltitudeMode. See the class level documentation for information on how altitudes
/// are interpreted.
@property (nonatomic) double upperAltitude;

/// Indicates the relationship of this airspace polygon's lower altitude boundary to the globe and terrain. One of
/// WW_ALTITUDE_MODE_ABSOLUTE, WW_ALTITUDE_MODE_RELATIVE_TO_GROUND or WW_ALTITUDE_MODE_CLAMP_TO_GROUND. See the class
/// level documentation for information on how altitude modes are interpreted.
@property (nonatomic) NSString* lowerAltitudeMode;

/// Indicates the relationship of this airspace polygon's upper altitude boundary to the globe and terrain. One of
/// WW_ALTITUDE_MODE_ABSOLUTE, WW_ALTITUDE_MODE_RELATIVE_TO_GROUND or WW_ALTITUDE_MODE_CLAMP_TO_GROUND. See the class
/// level documentation for information on how altitude modes are interpreted.
@property (nonatomic) NSString* upperAltitudeMode;

/// @name Initializing Airspace Polygons

/**
* Initializes an airspace polygon with its outer boundary vertices set to the specified locations and its altitudes set
* to the specified lowerAltitude and upperAltitude. See the class level documentation for information on how vertex
* locations and altitudes are interpreted.
*
* @param locations The locations indicating the airspace polygon's outer boundary vertices.
* @param lowerAltitude The lower altitude boundary of the three-dimensional portion of the atmosphere enclosed by this
* airspace polygon, interpreted according to the lowerAltitudeMode.
* @param upperAltitude The upper altitude boundary of the three-dimensional portion of the atmosphere enclosed by this
* airspace polygon, interpreted according to the upperAltitudeMode
*
* @return This airspace polygon initialized with the specified outer boundary vertices and altitudes.
*
* @exception NSInvalidArgumentException If the specified locations array is nil.
*/
- (WWAirspacePolygon*) initWithLocations:(NSArray*)locations lowerAltitude:(double)lowerAltitude upperAltitude:(double)upperAltitude;

/// @name Methods of Interest Only to Subclasses

- (void) tessellatePolygon:(WWDrawContext*)dc;

- (void) tessellatePolygon:(WWDrawContext*)dc combineVertex:(double)x y:(double)y z:(double)z outIndex:(GLushort*)outIndex;

- (void) makeRenderedPolygon:(WWDrawContext*)dc;

@end
