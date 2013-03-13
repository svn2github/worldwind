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
    return NO;
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
    double r = _radius;

    if (radiusIsPixels)
    {
        double d = [[[dc navigatorState] eyePoint] distanceTo3:referencePoint];
        double ps = [[dc navigatorState] pixelSizeAtDistance:d];
        r *= ps;
    }

    // Scale the unit sphere to the actual radius.
    [transformationMatrix setScale:r y:r z:r];

    // Create the extent.
    [self setExtent:[[WWBoundingSphere alloc] initWithPoint:rpt radius:r]];
}

- (void) doDrawInterior:(WWDrawContext*)dc
{
    [self bindVbos:dc];

    int location = [[dc defaultProgram] getAttributeLocation:@"vertexPoint"];
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
    float x = 0.525731112119133606f;
    float z = 0.850650808352039932f;

    float vertices[] =
            {
                    -x, 0, z,
                    x, 0, z,
                    -x, 0, -z,
                    x, 0, -z,
                    0, z, x,
                    0, z, -x,
                    0, -z, x,
                    0, -z, -x,
                    z, x, 0,
                    -z, x, 0,
                    z, -x, 0,
                    -z, -x, 0
            };

    size_t verticesSize  = sizeof(vertices);
    numVertices = verticesSize / sizeof(float);

    short indices[] =
            {
                    1, 4, 0,
                    4, 9, 0,
                    4, 5, 9,
                    8, 5, 4,
                    1, 8, 4,
                    1, 10, 8,
                    10, 3, 8,
                    8, 3, 5,
                    3, 2, 5,
                    3, 7, 2,
                    3, 10, 7,
                    10, 6, 7,
                    6, 11, 7,
                    6, 0, 11,
                    6, 1, 0,
                    10, 1, 6,
                    11, 0, 9,
                    2, 11, 9,
                    5, 2, 9,
                    11, 2, 7
            };

    size_t indicesSize = sizeof(indices);
    numIndices = indicesSize / sizeof(indices[0]);

    WWGpuResourceCache* gpuResourceCache = [dc gpuResourceCache];

    GLuint verticesVboId;
    glGenBuffers(1, &verticesVboId);
    glBindBuffer(GL_ARRAY_BUFFER, verticesVboId);
    glBufferData(GL_ARRAY_BUFFER, numVertices * 3 * sizeof(float), vertices, GL_STATIC_DRAW);
    [gpuResourceCache putResource:[[NSNumber alloc] initWithInt:verticesVboId]
                     resourceType:WW_GPU_VBO
                             size:numVertices * 3 * sizeof(float)
                           forKey:verticesVboCacheKey];
    glBindBuffer(GL_ARRAY_BUFFER, 0);

    GLuint indicesVboId;
    glGenBuffers(1, &indicesVboId);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indicesVboId);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, numIndices * sizeof(short), indices, GL_STATIC_DRAW);
    [gpuResourceCache putResource:[[NSNumber alloc] initWithInt:indicesVboId]
                     resourceType:WW_GPU_VBO
                             size:numIndices * sizeof(short)
                           forKey:indicesVboCacheKey];
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
}

@end