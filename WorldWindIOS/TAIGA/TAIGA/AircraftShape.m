/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "AircraftShape.h"
#import "WorldWind/WWLog.h"
#import "WorldWind/Geometry/WWBoundingSphere.h"
#import "WorldWind/Geometry/WWMatrix.h"
#import "WorldWind/Geometry/WWPosition.h"
#import "WorldWind/Geometry/WWVec4.h"
#import "WorldWind/Navigate/WWNavigatorState.h"
#import "WorldWind/Render/WWDrawContext.h"
#import "WorldWind/Shaders/WWBasicProgram.h"
#import "WorldWind/Terrain/WWTerrain.h"
#import "WorldWind/Util/WWGpuResourceCache.h"
#import "WorldWind/Util/WWMath.h"
#import "WorldWind/WorldWindConstants.h"

static const NSString* AircraftShapeVerticesKey = @"AircraftShape.VerticesKey";
static const GLfloat AircraftShapeVertices[] = {0.0, 0.5, -0.35, -0.5, 0.35, -0.5};
static const GLsizei AircraftShapeVertexCount = 3;

@implementation AircraftShape

- (AircraftShape*) initWithSize:(double)size
{
    self = [super init];

    _size = size;
    _minSize = 0;
    _maxSize = DBL_MAX;
    sizeIsPixels = NO;
    position = [[WWPosition alloc] initWithZeroPosition];

    return self;
}

- (AircraftShape*) initWithSizeInPixels:(double)size
{
    return [self initWithSizeInPixels:size minSize:0 maxSize:DBL_MAX];
}

- (AircraftShape*) initWithSizeInPixels:(double)size minSize:(double)minSize maxSize:(double)maxSize
{
    self = [super init];

    _size = size;
    _minSize = minSize;
    _maxSize = maxSize;
    sizeIsPixels = YES;
    position = [[WWPosition alloc] initWithZeroPosition];

    return self;
}

- (void) setLocation:(CLLocation*)location
{
    if (location == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Position is nil")
    }

    _location = location;

    [position setCLLocation:location altitude:[location altitude]];
    [self setReferencePosition:position];
}

- (void) setSize:(double)size
{
    if (size <= 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Size is less than or equal to 0")
    }

    _size = size;
}

- (BOOL) isSizeInPixels
{
    return sizeIsPixels;
}

- (BOOL) isEnableDepthOffset:(WWDrawContext*)dc
{
    return YES;
}

- (BOOL) mustRegenerateGeometry:(WWDrawContext*)dc
{
    // Geometry generation is done once to create a unit shape that is then scaled and positioned during rendering.
    // Returning YES from this method causes doMakeOrderedRenderable to be called every frame. The shape's Cartesian
    // position and, if appropriate, its screen-space size are updated during that call.

    return YES;
}

- (void) doMakeOrderedRenderable:(WWDrawContext*)dc
{
    // Compute the shape's current reference point and eye distance.
    [[dc terrain] surfacePointAtLatitude:[position latitude]
                               longitude:[position longitude]
                                  offset:[position altitude]
                            altitudeMode:[self altitudeMode]
                                  result:referencePoint];
    double eyeDistance = [[[dc navigatorState] eyePoint] distanceTo3:referencePoint];
    [self setEyeDistance:eyeDistance];

    // Determine the value used to scale the unit-length shape, which if screen dependent could change every frame.
    sizeInMeters = _size;
    if (sizeIsPixels)
    {
        sizeInMeters *= [[dc navigatorState] pixelSizeAtDistance:eyeDistance];
        sizeInMeters = WWCLAMP(sizeInMeters, _minSize, _maxSize);
    }

    if (sizeInMeters <= 0)
    {
        return;
    }

    // Set the transformation matrix to transform the shape's origin and coordinate system to the shape's local
    // coordinate origin on the globe, and scale the shape's unit-length coordinates to their actual size.
    [transformationMatrix setToIdentity];
    [transformationMatrix multiplyByLocalCoordinateTransform:referencePoint onGlobe:[dc globe]];
    [transformationMatrix multiplyByRotationAxis:0 y:0 z:1 angleDegrees:-[_location course]];
    [transformationMatrix multiplyByScale:sizeInMeters y:sizeInMeters z:sizeInMeters];

    // Create the extent.
    [self setExtent:[[WWBoundingSphere alloc] initWithPoint:referencePoint radius:sizeInMeters]];
}

- (BOOL) isOrderedRenderableValid:(WWDrawContext*)dc
{
    return sizeInMeters > 0;
}

- (void) beginDrawing:(WWDrawContext*)dc
{
    [super beginDrawing:dc];

    // Bind vertex attributes and element array buffers.
    [self bindVertexAttributes:dc];
}

- (void) endDrawing:(WWDrawContext*)dc
{
    [super endDrawing:dc];

    // Clean up vertex attribute bindings.
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
}

- (void) bindVertexAttributes:(WWDrawContext*)dc
{
    NSNumber* verticesVboId = (NSNumber*) [[dc gpuResourceCache] resourceForKey:AircraftShapeVerticesKey];
    if (verticesVboId == nil)
    {
        GLuint vboId;
        GLsizei vboSize = 2 * sizeof(GLfloat) * AircraftShapeVertexCount;
        glGenBuffers(1, &vboId);
        glBindBuffer(GL_ARRAY_BUFFER, vboId);
        glBufferData(GL_ARRAY_BUFFER, vboSize, AircraftShapeVertices, GL_STATIC_DRAW);
        verticesVboId = [[NSNumber alloc] initWithInt:vboId];
        [[dc gpuResourceCache] putResource:verticesVboId
                              resourceType:WW_GPU_VBO
                                      size:vboSize
                                    forKey:AircraftShapeVerticesKey];
    }
    else
    {
        glBindBuffer(GL_ARRAY_BUFFER, (GLuint) [verticesVboId intValue]);
    }

    WWBasicProgram* program = (WWBasicProgram*) [dc currentProgram];
    glVertexAttribPointer([program vertexPointLocation], 2, GL_FLOAT, GL_FALSE, 0, 0);
}

- (void) doDrawInterior:(WWDrawContext*)dc
{
    glDrawArrays(GL_TRIANGLES, 0, AircraftShapeVertexCount);
}

- (void) doDrawOutline:(WWDrawContext*)dc
{
    glDrawArrays(GL_LINE_LOOP, 0, AircraftShapeVertexCount);
}

@end