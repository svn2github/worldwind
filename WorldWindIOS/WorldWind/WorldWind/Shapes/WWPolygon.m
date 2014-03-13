/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <QuartzCore/QuartzCore.h>
#import "WorldWind/Shapes/WWPolygon.h"
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

void WWPolygonTessBegin(GLenum type, void* userData)
{
    [(__bridge WWPolygon*) userData tessBegin:type];
}

void WWPolygonTessVertex(void* vertexData, void* userData)
{
    [(__bridge WWPolygon*) userData tessVertex:vertexData];
}

void WWPolygonTessEnd(void* userData)
{
    [(__bridge WWPolygon*) userData tessEnd];
}

void WWPolygonTessCombine(GLdouble coords[3], void* vertexData[4], GLdouble weight[4], void** outData, void* userData)
{
    [(__bridge WWPolygon*) userData tessCombine:coords vertexData:vertexData weight:weight outData:outData];
}

@implementation WWPolygon

- (WWPolygon*) initWithPositions:(NSArray*)positions
{
    if (positions == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Positions array is nil")
    }

    self = [super init];

    boundaries = [[NSMutableArray alloc] init];
    [boundaries addObject:positions];
    [self setReferencePosition:[positions count] < 1 ? nil : [positions objectAtIndex:0]];

    referenceNormal = [[WWVec4 alloc] initWithZeroVector];
    vertexStride = 3;

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
    indexCount = 0;
}

- (NSArray*) positions
{
    return [boundaries firstObject];
}

- (void) setPositions:(NSArray*)positions
{
    if (positions == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Positions array is nil")
    }

    [boundaries setObject:positions atIndexedSubscript:0];
    [self setReferencePosition:[positions count] < 1 ? nil : [positions objectAtIndex:0]];
    [self reset];
}

- (NSArray*) innerBoundaries
{
    return [boundaries subarrayWithRange:NSMakeRange(1, [boundaries count] - 1)];
}

- (void) addInnerBoundary:(NSArray*)positions
{
    if (positions == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Positions array is nil")
    }

    [boundaries addObject:positions];
    [self reset];
}

- (BOOL) mustRegenerateGeometry:(WWDrawContext*)dc
{
    if (vertices == nil || verticalExaggeration != [dc verticalExaggeration])
    {
        return YES;
    }

    if ([_altitudeMode isEqual:WW_ALTITUDE_MODE_ABSOLUTE])
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
                            altitudeMode:[self altitudeMode]
                                  result:referencePoint];

    // Compute the surface normal at the reference point, then set the transformation matrix and the eye distance to
    // correspond to the reference point.
    WWVec4* p = referencePoint;
    [transformationMatrix setToTranslation:[p x] y:[p y] z:[p z]];
    [[dc globe] surfaceNormalAtPoint:[p x] y:[p y] z:[p z] result:referenceNormal];
    [self setEyeDistance:[[[dc navigatorState] eyePoint] distanceTo3:p]];

    // Create the polygon's model-coordinate points and compute indices that tessellate the interior as a list of
    // triangles.
    [self tessellatePolygon:dc];
    if ([tessIndices count] < 3)
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
    return indices != nil && indexCount >= 3;
}

- (void) beginDrawing:(WWDrawContext*)dc
{
    [super beginDrawing:dc];

    // Bind vertex attributes and element array buffers.
    WWBasicProgram* program = (WWBasicProgram*) [dc currentProgram];
    glVertexAttribPointer([program vertexPointLocation], 3, GL_FLOAT, GL_FALSE, vertexStride * sizeof(GLfloat), vertices);

    // Disable OpenGL backface culling to make both sides of the polygon interior visible, and to make the polygon
    // interior visible regardless its winding order.
    glDisable(GL_CULL_FACE);
}

- (void) endDrawing:(WWDrawContext*)dc
{
    // Restore OpenGL state to the values established by WWSceneController.
    glEnable(GL_CULL_FACE);
}

- (void) doDrawInterior:(WWDrawContext*)dc
{
    glDrawElements(GL_TRIANGLES, indexCount, GL_UNSIGNED_SHORT, indices);
}

- (void) doDrawOutline:(WWDrawContext*)dc
{
    GLint first = 0;
    GLsizei count;

    for (NSArray* __unsafe_unretained positions in boundaries)
    {
        count = [positions count];
        glDrawArrays(GL_LINE_LOOP, first, count);
        first += count;
    }
}

- (void) tessellatePolygon:(WWDrawContext*)dc
{
    tessVertices = [[NSMutableArray alloc] init];
    tessIndices = [[NSMutableArray alloc] init];
    vertexIndices = [[NSMutableArray alloc] init];

    GLUtesselator* tess = gluNewTess();
    gluTessCallback(tess, GLU_TESS_BEGIN_DATA, (_GLUfuncptr) &WWPolygonTessBegin);
    gluTessCallback(tess, GLU_TESS_VERTEX_DATA, (_GLUfuncptr) &WWPolygonTessVertex);
    gluTessCallback(tess, GLU_TESS_END_DATA, (_GLUfuncptr) &WWPolygonTessEnd);
    gluTessCallback(tess, GLU_TESS_COMBINE_DATA, (_GLUfuncptr) &WWPolygonTessCombine);
    gluTessNormal(tess, [referenceNormal x], [referenceNormal y], [referenceNormal z]);
    gluTessBeginPolygon(tess, (__bridge void*) self); // Use self as the polygon user data to enable callbacks to this instance.

    for (NSArray* __unsafe_unretained positions in boundaries)
    {
        gluTessBeginContour(tess);

        for (WWPosition* __unsafe_unretained pos in positions)
        {
            WWVec4* point = [[WWVec4 alloc] initWithZeroVector];
            [[dc terrain] surfacePointAtLatitude:[pos latitude] longitude:[pos longitude] offset:[pos altitude]
                               altitudeMode:[self altitudeMode] result:point];
            [point subtract3:referencePoint];
            [tessVertices addObject:point];

            NSNumber* index = [NSNumber numberWithInt:[tessVertices count] - 1];
            [vertexIndices addObject:index];

            GLdouble coord[3];
            coord[0] = [point x];
            coord[1] = [point y];
            coord[2] = [point z];

            gluTessVertex(tess, coord, (__bridge void*) index); // Associate the vertex with its index in the vertex array.
        }

        gluTessEndContour(tess);
    }

    gluTessEndPolygon(tess);
    gluDeleteTess(tess);
    vertexIndices = nil;
}

- (void) tessBegin:(GLenum)type
{
    // Reset the tessellation primitive type and index count.
    tessPrimType = type;
    tessIndexCount = 0;
}

- (void) tessVertex:(GLvoid*)vertex
{
    NSNumber* index = (__bridge NSNumber*) vertex;
    tessIndexCount++;

    if (tessPrimType == GL_TRIANGLES)
    {
        [tessIndices addObject:index];
    }
    else if (tessPrimType == GL_TRIANGLE_FAN)
    {
        if (tessIndexCount == 1)
            tessIndex1 = index;
        else if (tessIndexCount == 2)
            tessIndex2 = index;
        else // tessIndexCount >= 3
        {
            [tessIndices addObject:tessIndex1];
            [tessIndices addObject:tessIndex2];
            [tessIndices addObject:index];
            tessIndex2 = index;
        }
    }
    else if (tessPrimType == GL_TRIANGLE_STRIP)
    {
        if (tessIndexCount == 1)
            tessIndex1 = index;
        else if (tessIndexCount == 2)
            tessIndex2 = index;
        else // tessIndexCount >= 3
        {
            [tessIndices addObject:(tessIndexCount % 1) == 0 ? tessIndex1 : tessIndex2];
            [tessIndices addObject:(tessIndexCount % 1) == 0 ? tessIndex2 : tessIndex1];
            [tessIndices addObject:index];
            tessIndex1 = tessIndex2;
            tessIndex2 = index;
        }
    }
}

- (void) tessEnd
{
    // Release index pointers using during tessellation.
    tessIndex1 = nil;
    tessIndex2 = nil;
}

- (void) tessCombine:(GLdouble[3])coords vertexData:(void*[4])vertexData weight:(GLdouble[4])weight outData:(void**)outData
{
    // Add a vertex using the coordinates computed by the tessellator.
    WWVec4* point = [[WWVec4 alloc] initWithCoordinates:coords[0] y:coords[1] z:coords[2]];
    [tessVertices addObject:point];

    NSNumber* index = [NSNumber numberWithInt:[tessVertices count] - 1];
    [vertexIndices addObject:index];

    // Associate the tessellated vertex with its index in the vertex array.
    *outData = (__bridge void*) index;
}

- (void) makeRenderedPolygon:(WWDrawContext*)dc
{
    vertexCount = [tessVertices count];
    vertices = malloc((size_t) vertexCount * vertexStride * sizeof(GLfloat));
    GLfloat* vertex = vertices;
    for (WWVec4* __unsafe_unretained tessVertex in tessVertices)
    {
        vertex[0] = (GLfloat) [tessVertex x];
        vertex[1] = (GLfloat) [tessVertex y];
        vertex[2] = (GLfloat) [tessVertex z];
        vertex += vertexStride;
    }

    indexCount = [tessIndices count];
    indices = malloc((size_t) indexCount * sizeof(GLushort));
    GLushort* index = indices;
    for (NSNumber* __unsafe_unretained tessIndex in tessIndices)
    {
        index[0] = [tessIndex unsignedShortValue];
        index++;
    }

    tessVertices = nil;
    tessIndices = nil;
}

@end