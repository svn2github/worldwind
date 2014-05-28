/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <QuartzCore/QuartzCore.h>
#import "WorldWind/Shapes/WWPolygon.h"
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

    // Disable OpenGL backface culling to make both sides of the polygon interior visible regardless of its winding
    // order.
    glDisable(GL_CULL_FACE);
}

- (void) endDrawing:(WWDrawContext*)dc
{
    [super endDrawing:dc];

    // Restore OpenGL state to the values established by WWSceneController.
    glEnable(GL_CULL_FACE);
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

    for (NSArray* __unsafe_unretained boundaryPositions in boundaries)
    {
        [tess beginContour];

        for (WWPosition* __unsafe_unretained pos in boundaryPositions)
        {
            WWVec4* point = [[WWVec4 alloc] initWithZeroVector];
            [[dc terrain] surfacePointAtLatitude:[pos latitude] longitude:[pos longitude] offset:[pos altitude]
                               altitudeMode:[self altitudeMode] result:point];
            [point subtract3:referencePoint];
            [tessVertices addObject:point];
            [tess addVertex:[point x] y:[point y] z:[point z] withIndex:(GLushort) [tessVertices count] - 1];
        }

        [tess endContour];
    }

    [tess endPolygon];
}

- (void) tessellatePolygon:(WWDrawContext*)dc combineVertex:(double)x y:(double)y z:(double)z outIndex:(GLushort*)outIndex
{
    // Add a vertex using the coordinates computed by the tessellator.
    WWVec4* point = [[WWVec4 alloc] initWithCoordinates:x y:y z:z];
    [tessVertices addObject:point];

    *outIndex = (GLushort) [tessVertices count] - 1;
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

    interiorIndexRange = NSMakeRange(0, [[tess interiorIndices] count]);
    outlineIndexRange = NSMakeRange(0, [[tess boundaryIndices] count]);
    indexCount = interiorIndexRange.length + outlineIndexRange.length;
    indices = malloc((size_t) indexCount * sizeof(GLushort));

    GLushort* index = indices;
    interiorIndexRange.location = index - indices;
    for (NSNumber* __unsafe_unretained tessIndex in [tess interiorIndices])
    {
        *index++ = [tessIndex unsignedShortValue];
    }

    outlineIndexRange.location = index - indices;
    for (NSNumber* __unsafe_unretained tessIndex in [tess boundaryIndices])
    {
        *index++ = [tessIndex unsignedShortValue];
    }

    tessVertices = nil;
}

@end