/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Shapes/WWSphere.h"
#import "WorldWind/Geometry/WWPosition.h"
#import "WorldWind/WWLog.h"
#import "WorldWind/Render/WWDrawContext.h"
#import "WorldWind/Terrain/WWTerrain.h"
#import "WorldWind/Geometry/WWMatrix.h"
#import "WorldWind/Geometry/WWVec4.h"
#import "WorldWind/Util/WWGpuResourceCache.h"
#import "WorldWind/WorldWindConstants.h"
#import "WorldWind/Render/WWGpuProgram.h"
#import "WorldWind/Navigate/WWNavigatorState.h"
#import "WorldWind/Geometry/WWBoundingSphere.h"

@implementation WWSphere

static int numVertices; // the number of vertices in the sphere
static int numIndices; // the number of indices defining the sphere

- (WWSphere*) initWithPosition:(WWPosition*)position radius:(double)radius
{
    if (position == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Position is nil")
    }

    if (radius <= 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Radius is less than or equal to 0")
    }

    self = [super init];

    _position = position;
    _radius = radius;

    [self setReferencePosition:position];

    verticesVboCacheKey = @"VerticesVboCacheKey.WWSphere";
    indicesVboCacheKey = @"IndicesVboCacheKey.WWSphere";

    return self;
}

- (WWSphere*) initWithPosition:(WWPosition*)position radiusInPixels:(double)radius
{
    radiusIsPixels = YES;

    return [self initWithPosition:position radius:radius];
}

- (void) setPosition:(WWPosition*)position
{
    if (position == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Position is nil")
    }

    _position = position;

    [self setReferencePosition:position];
}

- (void) setRadius:(double)radius
{
    if (radius <= 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Radius is less than or equal to 0")
    }

    _radius = radius;
}

- (BOOL) isRadiusInPixels
{
    return radiusIsPixels;
}

- (BOOL) mustDrawOutline
{
    return NO; // spheres do not have an outline
}

- (BOOL) mustRegenerateGeometry:(WWDrawContext*)dc
{
    // Geometry generation is done once to create a unit sphere that is then scaled and positioned during rendering.
    // Returning YES from this method causes doMakeOrderedRenderable to be called every frame. The shape's Cartesian
    // position and, if appropriate, its screen-space radius are updated during that call.

    return YES;
}

- (void) doMakeOrderedRenderable:(WWDrawContext*)dc
{
    // Set the transformation matrix to correspond to the sphere's position and the current altitude mode and terrain.
    [[dc terrain] surfacePointAtLatitude:[_position latitude]
                               longitude:[_position longitude]
                                  offset:[_position altitude]
                            altitudeMode:[self altitudeMode]
                                  result:referencePoint];
    WWVec4* rpt = referencePoint;
    [transformationMatrix setTranslation:[rpt x] y:[rpt y] z:[rpt z]];

    // Determine the actual radius in meters, which if screen dependent could change every frame.
    radiusInMeters = _radius;

    if (radiusIsPixels)
    {
        double d = [[[dc navigatorState] eyePoint] distanceTo3:referencePoint];
        double ps = [[dc navigatorState] pixelSizeAtDistance:d];
        radiusInMeters *= ps;
    }

    double r = radiusInMeters;
    if (r <= 0)
    {
        return;
    }

    // Scale the unit sphere to the actual radius.
    [transformationMatrix setScale:r y:r z:r];

    // Create the extent.
    [self setExtent:[[WWBoundingSphere alloc] initWithPoint:rpt radius:r]];
}

- (BOOL) isOrderedRenderableValid:(WWDrawContext*)dc
{
    return radiusInMeters > 0;
}

- (void) doDrawInterior:(WWDrawContext*)dc
{
    [self bindVbos:dc];

    int location = [[dc currentProgram] getAttributeLocation:@"vertexPoint"];
    glVertexAttribPointer((GLuint) location, 3, GL_FLOAT, GL_FALSE, 0, 0);

    glDrawElements(GL_TRIANGLE_STRIP, numIndices, GL_UNSIGNED_SHORT, 0);

    // Clean up
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
}

- (void) bindVbos:(WWDrawContext*)dc
{
    WWGpuResourceCache* gpuResourceCache = [dc gpuResourceCache];

    NSNumber* verticesVboId = (NSNumber*) [gpuResourceCache getResourceForKey:verticesVboCacheKey];
    NSNumber* indicesVboId = (NSNumber*) [gpuResourceCache getResourceForKey:indicesVboCacheKey];

    if (verticesVboId == nil || indicesVboId == nil)
    {
        [self tessellateSphere:dc];

        verticesVboId = (NSNumber*) [gpuResourceCache getResourceForKey:verticesVboCacheKey];
        indicesVboId = (NSNumber*) [gpuResourceCache getResourceForKey:indicesVboCacheKey];
    }

    glBindBuffer(GL_ARRAY_BUFFER, (GLuint) [verticesVboId intValue]);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, (GLuint) [indicesVboId intValue]);
}

- (void) tessellateSphere:(WWDrawContext*)dc
{
    int nLatIntervals = 30;
    int nLonIntervals = 60;

    // Compute the unit sphere's vertices.
    numVertices = (nLatIntervals + 1) * (nLonIntervals + 1);
    float* vertices = (float*) malloc((size_t) numVertices * 3 * sizeof(float));

    @try
    {
        double dLat = M_PI / nLatIntervals;
        double dLon = 2 * M_PI / nLonIntervals;

        float* vertex = vertices;
        for (int it = 0; it <= nLatIntervals; it++)
        {
            double t = it * dLat;

            for (int ip = 0; ip <= nLonIntervals; ip++)
            {
                double p = ip * dLon;

                *vertex++ = (float) (sin(t) * sin(p));
                *vertex++ = (float) cos(t);
                *vertex++ = (float) (sin(t) * cos(p));
            }
        }

        // Fill the vertex VBO.
        GLuint verticesVboId;
        glGenBuffers(1, &verticesVboId);
        glBindBuffer(GL_ARRAY_BUFFER, verticesVboId);
        glBufferData(GL_ARRAY_BUFFER, numVertices * 3 * sizeof(float), vertices, GL_STATIC_DRAW);
        [[dc gpuResourceCache] putResource:[[NSNumber alloc] initWithInt:verticesVboId]
                              resourceType:WW_GPU_VBO
                                      size:numVertices * 3 * sizeof(float)
                                    forKey:verticesVboCacheKey];
    }
    @finally
    {
        glBindBuffer(GL_ARRAY_BUFFER, 0);
        free(vertices);
    }

    // Compute the indices such that they define one triangle strip defining the whole sphere at once. This requires
    // duplicating the last index of each row and the first index of the subsequent row in order to define degenerate
    // triangles that effectively link the strips together.
    numIndices = nLatIntervals * (2 * nLonIntervals + 2) + 2 * (nLatIntervals - 1);
    short* indices = (short*) malloc((size_t) numIndices * sizeof(short));

    @try
    {
        short* index = indices;
        for (int j = 0; j < nLatIntervals; j++)
        {
            if (j != 0) // add redundant vertices
            {
                *index++ = index[-1];
                *index++ = (short) (j * (nLonIntervals + 1));
            }

            for (int i = 0; i <= nLonIntervals; i++)
            {
                short k1 = (short) (i + j * (nLonIntervals + 1));
                short k2 = k1 + (short) (nLonIntervals + 1);
                *index++ = k1;
                *index++ = k2;
            }
        }

        // Fill the index VBO.
        GLuint indicesVboId;
        glGenBuffers(1, &indicesVboId);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indicesVboId);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, numIndices * sizeof(short), indices, GL_STATIC_DRAW);
        [[dc gpuResourceCache] putResource:[[NSNumber alloc] initWithInt:indicesVboId]
                              resourceType:WW_GPU_VBO
                                      size:numIndices * sizeof(short)
                                    forKey:indicesVboCacheKey];
    }
    @finally
    {
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
        free(indices);
    }
}

@end