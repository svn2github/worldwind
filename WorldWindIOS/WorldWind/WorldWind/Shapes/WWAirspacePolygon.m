/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <QuartzCore/QuartzCore.h>
#import "WorldWind/Shapes/WWAirspacePolygon.h"
#import "WorldWind/Shapes/WWPolygonTessellator.h"
#import "WorldWind/Geometry/WWBoundingBox.h"
#import "WorldWind/Geometry/WWMatrix.h"
#import "WorldWind/Geometry/WWPosition.h"
#import "WorldWind/Geometry/WWVec4.h"
#import "WorldWind/Navigate/WWBasicNavigatorState.h"
#import "WorldWind/Render/WWDrawContext.h"
#import "WorldWind/Shaders/WWBasicProgram.h"
#import "WorldWind/Terrain/WWGlobe.h"
#import "WorldWind/Terrain/WWTerrain.h"
#import "WorldWind/WorldWindConstants.h"
#import "WorldWind/WWLog.h"

@implementation WWAirspacePolygon

- (WWAirspacePolygon*) initWithLocations:(NSArray*)locations lowerAltitude:(double)lowerAltitude upperAltitude:(double)upperAltitude
{
    if (locations == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Locations array is nil")
    }

    self = [super init];

    boundaries = [[NSMutableArray alloc] init];
    [boundaries addObject:locations];
    referenceNormal = [[WWVec4 alloc] initWithZeroVector];
    [self setReferencePosition:[locations count] < 1 ? nil : [[WWPosition alloc] initWithLocation:[locations firstObject] altitude:lowerAltitude]];

    _lowerAltitude = lowerAltitude;
    _upperAltitude = upperAltitude;
    _lowerAltitudeMode = WW_ALTITUDE_MODE_ABSOLUTE;
    _upperAltitudeMode = WW_ALTITUDE_MODE_ABSOLUTE;

    return self;
}

- (void) dealloc
{
    if (vertices != nil)
    {
        free(vertices);
        free(indices);
    }
}

- (void) reset
{
    if (vertices != nil)
    {
        free(vertices);
        free(indices);
        vertices = nil;
        indices = nil;
    }

    vertexCount = 0;
    vertexStride = 0;
    indexCount = 0;
    interiorIndexRange = NSMakeRange(0, 0);
    outlineIndexRange = NSMakeRange(0, 0);
}

- (NSArray*) locations
{
    return [boundaries firstObject];
}

- (void) setLocations:(NSArray*)locations
{
    if (locations == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Locations array is nil")
    }

    [boundaries setObject:locations atIndexedSubscript:0];
    [self setReferencePosition:[locations count] < 1 ? nil : [[WWPosition alloc] initWithLocation:[locations firstObject] altitude:_lowerAltitude]];
    [self reset];
}

- (NSArray*) innerBoundaries
{
    return [boundaries subarrayWithRange:NSMakeRange(1, [boundaries count] - 1)];
}

- (void) addInnerBoundary:(NSArray*)locations
{
    if (locations == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Locations array is nil")
    }

    [boundaries addObject:locations];
    [self reset];
}

- (void) setLowerAltitude:(double)lowerAltitude
{
    _lowerAltitude = lowerAltitude;
    [self reset];
}

- (void) setUpperAltitude:(double)upperAltitude
{
    _upperAltitude = upperAltitude;
    [self reset];
}

- (void) setLowerAltitudeMode:(NSString*)lowerAltitudeMode
{
    if (lowerAltitudeMode == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Lower altitude mode is nil")
    }

    _lowerAltitudeMode = lowerAltitudeMode;
    [self reset];
}

- (void) setUpperAltitudeMode:(NSString*)upperAltitudeMode
{
    if (upperAltitudeMode == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Upper altitude mode is nil")
    }

    _upperAltitudeMode = upperAltitudeMode;
    [self reset];
}

- (BOOL) mustRegenerateGeometry:(WWDrawContext*)dc
{
    if (vertices == nil || verticalExaggeration != [dc verticalExaggeration])
    {
        return YES;
    }

    if ([_lowerAltitudeMode isEqual:WW_ALTITUDE_MODE_ABSOLUTE] && [_upperAltitudeMode isEqual:WW_ALTITUDE_MODE_ABSOLUTE])
    {
        return NO;
    }

    return YES;
}

- (void) doMakeOrderedRenderable:(WWDrawContext*)dc
{
    // A nil reference position is a signal that there are no positions to render.
    WWPosition* refPos = [self referencePosition];
    if (refPos == nil)
    {
        return;
    }

    // Compute the reference point the polygon's model-coordinate points are relative to.
    [[dc terrain] surfacePointAtLatitude:[refPos latitude]
                               longitude:[refPos longitude]
                                  offset:[refPos altitude]
                            altitudeMode:_lowerAltitudeMode
                                  result:referencePoint];

    // Compute the surface normal at the reference point, then set the transformation matrix and the eye distance to
    // correspond to the reference point.
    WWVec4* p = referencePoint;
    [transformationMatrix setToTranslation:[p x] y:[p y] z:[p z]];
    [[dc globe] surfaceNormalAtPoint:[p x] y:[p y] z:[p z] result:referenceNormal];
    [self setEyeDistance:[[[dc navigatorState] eyePoint] distanceTo3:p]];

    // Create the polygon's model-coordinate points, tessellate the polygon's interior regions, and tessellate the
    // boundaries between the polygon's interior regions.
    [self tessellatePolygon:dc];
    if ([[tess boundaryIndices] count] < 2)
    {
        return;
    }

    // Create the polygon's extent from its model-coordinate points. Those points are relative to this polygon's
    // reference point, so translate the computed extent to the reference point.
    WWBoundingBox* box = [[WWBoundingBox alloc] initWithUnitBox];
    [box setToPoints:tessVertices];
    [box translate:referencePoint];
    [self setExtent:box];

    // Create the data structures submitted to OpenGL during rendering. This releases the tessIndices and tessVertices
    // arrays used above.
    [self makeRenderedPolygon:dc];
}

- (BOOL) isOrderedRenderableValid:(WWDrawContext *)dc
{
    return outlineIndexRange.length >= 2;
}

- (void) beginDrawing:(WWDrawContext*)dc
{
    [super beginDrawing:dc];

    // Bind vertex attributes and element array buffers.
    WWBasicProgram* program = (WWBasicProgram*) [dc currentProgram];
    glVertexAttribPointer([program vertexPointLocation], 3, GL_FLOAT, GL_FALSE, vertexStride * sizeof(GLfloat), vertices);
}

- (void) doDrawInterior:(WWDrawContext*)dc
{
    glDrawElements(GL_TRIANGLES, interiorIndexRange.length, GL_UNSIGNED_SHORT, &indices[interiorIndexRange.location]);
}

- (void) doDrawOutline:(WWDrawContext*)dc
{
    glDrawElements(GL_LINES, outlineIndexRange.length, GL_UNSIGNED_SHORT, &indices[outlineIndexRange.location]);
}

- (void) tessellatePolygon:(WWDrawContext*)dc
{
    tess = [[WWPolygonTessellator alloc] init];
    tessVertices = [[NSMutableArray alloc] init];

    [tess setCombineBlock:^(double x, double y, double z, GLushort* outIndex) {
        [self tessellatePolygon:dc combineVertex:x y:y z:z outIndex:outIndex];
    }];
    [tess setPolygonNormal:[referenceNormal x] y:[referenceNormal y] z:[referenceNormal z]];
    [tess beginPolygon];

    for (NSArray* __unsafe_unretained boundaryLocation in boundaries)
    {
        [tess beginContour];

        for (WWPosition* __unsafe_unretained loc in boundaryLocation)
        {
            // Add two vertices at each boundary location: one at this polygon's upper altitude and another at this
            // polygon's the lower altitude.
            WWVec4* point = [[WWVec4 alloc] initWithZeroVector];
            [[dc terrain] surfacePointAtLatitude:[loc latitude] longitude:[loc longitude] offset:_upperAltitude
                                    altitudeMode:_upperAltitudeMode result:point];
            [point subtract3:referencePoint];
            [tessVertices addObject:point];
            [tess addVertex:[point x] y:[point y] z:[point z] withIndex:(GLushort) [tessVertices count] - 1];

            point = [[WWVec4 alloc] initWithZeroVector];
            [[dc terrain] surfacePointAtLatitude:[loc latitude] longitude:[loc longitude] offset:_lowerAltitude
                                    altitudeMode:_lowerAltitudeMode result:point];
            [point subtract3:referencePoint];
            [tessVertices addObject:point];
        }

        [tess endContour];
    }

    [tess endPolygon];
}

- (void) tessellatePolygon:(WWDrawContext*)dc combineVertex:(double)x y:(double)y z:(double)z outIndex:(GLushort*)outIndex
{
    // Compute the model coordinate point identified by the tessellator, and compute its corresponding geographic
    // position.
    WWVec4* point = [[WWVec4 alloc] initWithCoordinates:x y:y z:z];
    [point add3:referencePoint];
    WWPosition* pos = [[WWPosition alloc] initWithZeroPosition];
    [[dc globe] computePositionFromPoint:[point x] y:[point y] z:[point z] outputPosition:pos];

    // Add two vertices at the coordinates computed by the tessellator: one at this polygon's upper altitude and another
    // at this polygon's the lower altitude.
    [[dc terrain] surfacePointAtLatitude:[pos latitude] longitude:[pos longitude] offset:_upperAltitude
                                         altitudeMode:_upperAltitudeMode result:point];
    [point subtract3:referencePoint];
    [tessVertices addObject:point];
    *outIndex = (GLushort) [tessVertices count] - 1;

    point = [[WWVec4 alloc] initWithZeroVector];
    [[dc terrain] surfacePointAtLatitude:[pos latitude] longitude:[pos longitude] offset:_lowerAltitude
                                         altitudeMode:_lowerAltitudeMode result:point];
    [point subtract3:referencePoint];
    [tessVertices addObject:point];
}

- (void) makeRenderedPolygon:(WWDrawContext*)dc
{
    vertexCount = [tessVertices count];
    vertexStride = 3;
    vertices = malloc((size_t) vertexCount * vertexStride * sizeof(GLfloat));

    GLfloat* vertex = vertices;
    for (WWVec4* __unsafe_unretained tessVertex in tessVertices)
    {
        vertex[0] = (GLfloat) [tessVertex x];
        vertex[1] = (GLfloat) [tessVertex y];
        vertex[2] = (GLfloat) [tessVertex z];
        vertex += vertexStride;
    }

    interiorIndexRange = NSMakeRange(0, 2 * [[tess interiorIndices] count] + 3 * [[tess boundaryIndices] count]);
    outlineIndexRange = NSMakeRange(0, 3 * [[tess boundaryIndices] count]);
    indexCount = interiorIndexRange.length + outlineIndexRange.length;
    indices = malloc((size_t) indexCount * sizeof(GLushort));

    GLushort* index = indices;
    interiorIndexRange.location = index - indices;
    for (NSUInteger i = 0; i < [[tess interiorIndices] count]; i += 3)
    {
        GLushort i1 = [[[tess interiorIndices] objectAtIndex:i] unsignedShortValue];
        GLushort i2 = [[[tess interiorIndices] objectAtIndex:i + 1] unsignedShortValue];
        GLushort i3 = [[[tess interiorIndices] objectAtIndex:i + 2] unsignedShortValue];
        // upper altitude triangle
        *index++ = i1;
        *index++ = i2;
        *index++ = i3;
        // lower altitude triangle
        *index++ = i3 + 1;
        *index++ = i2 + 1;
        *index++ = i1 + 1;
    }

    for (NSUInteger i = 0 ; i < [[tess boundaryIndices] count]; i += 2)
    {
        GLushort i1 = [[[tess boundaryIndices] objectAtIndex:i] unsignedShortValue];
        GLushort i2 = [[[tess boundaryIndices] objectAtIndex:i + 1] unsignedShortValue];
        // side upper left triangle
        *index++ = i1;
        *index++ = i1 + 1;
        *index++ = i2;
        // side lower right triangle
        *index++ = i2;
        *index++ = i1 + 1;
        *index++ = i2 + 1;
    }

    outlineIndexRange.location = index - indices;
    for (NSUInteger i = 0 ; i < [[tess boundaryIndices] count]; i += 2)
    {
        GLushort i1 = [[[tess boundaryIndices] objectAtIndex:i] unsignedShortValue];
        GLushort i2 = [[[tess boundaryIndices] objectAtIndex:i + 1] unsignedShortValue];
        // upper altitude horizontal line
        *index++ = i1;
        *index++ = i2;
        // lower altitude horizontal line
        *index++ = i1 + 1;
        *index++ = i2 + 1;
        // vertical line
        *index++ = i1;
        *index++ = i1 + 1;
    }

    tess = nil;
    tessVertices = nil;
}

@end