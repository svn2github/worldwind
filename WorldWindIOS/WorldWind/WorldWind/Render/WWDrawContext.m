/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Render/WWDrawContext.h"
#import "WorldWind/Render/WWSurfaceTileRenderer.h"
#import "WorldWind/Geometry/WWVec4.h"
#import "WorldWind/Geometry/WWMatrix.h"
#import "WorldWind/Terrain/WWGlobe.h"
#import "WorldWind/Navigate/WWNavigatorState.h"
#import "WorldWind/Geometry/WWPosition.h"
#import "WorldWind/Geometry/WWExtent.h"
#import "WorldWind/Render/WWOrderedRenderable.h"
#import "WorldWind/Shapes/WWOutlinedShape.h"
#import "WorldWind/Terrain/WWTerrain.h"
#import "WorldWind/Terrain/WWBasicTerrain.h"
#import "WorldWind/Util/WWGpuResourceCache.h"
#import "WorldWind/Util/WWUtil.h"
#import "WorldWind/Render/WWGpuProgram.h"
#import "WorldWind/Pick/WWPickedObject.h"
#import "WorldWind/Pick/WWPickedObjectList.h"
#import "WorldWind/Util/WWColor.h"
#import "WorldWind/WorldWindConstants.h"
#import "WorldWind/WWLog.h"

@implementation WWDrawContext

- (WWDrawContext*) init
{
    self = [super init];

    _surfaceTileRenderer = [[WWSurfaceTileRenderer alloc] init];
    _verticalExaggeration = 1;
    _timestamp = [NSDate date];
    _eyePosition = [[WWPosition alloc] initWithDegreesLatitude:0 longitude:0 altitude:0];
    _terrain = [[WWBasicTerrain alloc] initWithDrawContext:self];
    _screenProjection = [[WWMatrix alloc] initWithIdentity];
    _objectsAtPickPoint = [[WWPickedObjectList alloc] init];
    _clearColor = [WWColor makeColorInt:200 g:200 b:200 a:255];

    orderedRenderables = [[NSMutableArray alloc] init];
    defaultProgramKey = [WWUtil generateUUID];
    defaultTextureProgramKey = [WWUtil generateUUID];
    unitQuadKey = [WWUtil generateUUID];

    return self;
}

- (void) reset
{
    _timestamp = [NSDate date];
    _verticalExaggeration = 1;

    [orderedRenderables removeAllObjects];
    [_objectsAtPickPoint clear];
    _pickingMode = NO;
    _pickPoint = CGPointMake(0, 0);

    _numElevationTiles = 0;
    _numImageTiles = 0;
    _numRenderedTiles = 0;
}

- (void) update
{
    WWVec4* ep = [_navigatorState eyePoint];
    [_globe computePositionFromPoint:[ep x] y:[ep y] z:[ep z] outputPosition:_eyePosition];

    CGRect viewport = [_navigatorState viewport];
    [_screenProjection setToScreenProjection:viewport];
}

- (BOOL) isSmall:(id <WWExtent>)extent numPixels:(int)numPixels // TODO: enable when pixelSizeAtDistance implemented
{
//    if (extent == nil)
        return NO;

//    double distance = [[_navigatorState eyePoint] distanceTo3:[extent center]];
//    double extentDiameter = 2 * [extent radius];
//    double pixelsSize = numPixels * [_navigatorState pixelSizeAtDistance:distance];
//
//    return extentDiameter <= pixelsSize;
}

- (void) drawOutlinedShape:(id <WWOutlinedShape>)shape
{
    if (shape == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Shape is nil")
    }

    // Draw the outlined shape using a multi-pass rendering algorithm. The motivation for this is as follows:
    //
    // 1) The outline appears both in front of and behind the shape. If the outline is drawn using GL line smoothing
    // or GL blending, then either the line must be broken into separate parts or rendered in two passes.
    //
    // 2) If depth offset is enabled, we want to draw the shape on top of other intersecting shapes with similar depth
    // values in order to eliminate z-fighting between shapes. However, we don't want to offset both the depth and
    // color values, which would cause a cascading increase in depth offset when many shapes are drawn.
    //
    // These issues are resolved by making several passes for the interior and outline, as follows:

    @try
    {
        // If the outline and interior are enabled, then draw the outline but do not affect the depth buffer. The
        // interior pixels contribute the depth values. When the interior is drawn, it draws on top of these colors,
        // and the outline is visible behind the potentially transparent interior.

        if ([shape isDrawOutline:self] && [shape isDrawOutline:self])
        {
            glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE);
            glDepthMask(GL_FALSE);

            [shape drawOutline:self];
        }

        // If the interior is enabled, make two passes. The first pass draws the interior depth values with a depth
        // offset (likely away from the eye). This enables the shape to contribute to the depth buffer and occlude
        // other geometries as it normally would. The second pass draws the interior color values without a depth
        // offset, and does not affect the depth buffer. This gives the shape outline depth priority over the interior,
        // and gives the interior depth priority over other shapes drawn with depth offset enabled. By drawing colors
        // without depth offset, we avoid the problem of having to use ever increasing depth offsets.

        if ([shape isDrawInterior:self])
        {
            if ([shape isEnableDepthOffset:self])
            {
                // Draw depth.
                glColorMask(GL_FALSE, GL_FALSE, GL_FALSE, GL_FALSE);
                glDepthMask(GL_TRUE);
                glEnable(GL_POLYGON_OFFSET_FILL);
                glPolygonOffset([shape depthOffsetFactor:self], [shape depthOffsetUnits:self]);

                [shape drawInterior:self];

                // Draw color.
                glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE);
                glDepthMask(GL_FALSE);
                glDisable(GL_POLYGON_OFFSET_FILL);

                [shape drawInterior:self];
            }
            else
            {
                glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE);
                glDepthMask(GL_TRUE);

                [shape drawInterior:self];
            }
        }

        // If the outline is enabled, draw the outline color and depth values. This blends outline colors with the
        // interior colors.
        if ([shape isDrawInterior:self])
        {
            glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE);
            glDepthMask(GL_TRUE);

            [shape drawOutline:self];
        }
    }
    @finally
    {
        // Restore the default GL state values modified above.
        glDisable(GL_POLYGON_OFFSET_FILL);
        glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE);
        glDepthMask(GL_TRUE);
        glPolygonOffset(0, 0);
    }
}

- (void) addOrderedRenderable:(id <WWOrderedRenderable>)orderedRenderable
{
    if (orderedRenderable != nil)
    {
        [orderedRenderable setInsertionTime:[NSDate timeIntervalSinceReferenceDate]];
        [orderedRenderables addObject:orderedRenderable];
    }
}

- (void) addOrderedRenderableToBack:(id <WWOrderedRenderable>)orderedRenderable
{
    if (orderedRenderable != nil)
    {
        [orderedRenderable setInsertionTime:[NSDate timeIntervalSinceReferenceDate]];
        [orderedRenderable setEyeDistance:DBL_MAX];
        [orderedRenderables addObject:orderedRenderable];
    }
}

- (id <WWOrderedRenderable>) peekOrderedRenderable
{
    if ([orderedRenderables count] > 0)
    {
        return [orderedRenderables lastObject];
    }
    else
    {
        return nil;
    }
}

- (id <WWOrderedRenderable>) popOrderedRenderable
{
    if ([orderedRenderables count] > 0)
    {
        id <WWOrderedRenderable> lastObject = [orderedRenderables lastObject];
        [orderedRenderables removeLastObject];
        return lastObject;
    }
    else
    {
        return nil;
    }
}

- (void) sortOrderedRenderables
{
    // Sort the ordered renderables by eye distance from front to back and then by insertion time. The ordered
    // renderable list is processed front its last object to its first object below, thereby drawing ordered renderables
    // from front to back.
    [orderedRenderables sortUsingComparator:
            ^(id <WWOrderedRenderable> orA, id <WWOrderedRenderable> orB)
            {
                double eA = [orA eyeDistance];
                double eB = [orB eyeDistance];

                if (eA < eB) // orA is closer to the eye than orB; sort orA before orB
                {
                    return NSOrderedAscending;
                }
                else if (eA > eB) // orA is farther from the eye than orB; sort orB before orA
                {
                    return NSOrderedDescending;
                }
                else // orA and orB are the same distance from the eye; sort them based on insertion time
                {
                    NSTimeInterval tA = [orA insertionTime];
                    NSTimeInterval tB = [orB insertionTime];

                    if (tA > tB)
                    {
                        return NSOrderedAscending;
                    }
                    else if (tA < tB)
                    {
                        return NSOrderedDescending;
                    }
                    else
                    {
                        return NSOrderedSame;
                    }
                }
            }];
}

- (unsigned int) uniquePickColor
{
    ++uniquePickNumber; // causes the pick numbers to start at 1

    if (uniquePickNumber >= 0xffffff) // we have run out of available pick colors
    {
        uniquePickNumber = 1;
    }

    unsigned int pickColor = uniquePickNumber << 8 | 0xff; // add alpha of 255
    if (pickColor == _clearColor)
    {
        pickColor = ++uniquePickNumber << 8 | 0xff; // skip the clear color
    }

    return pickColor;
}

- (unsigned int) readPickColor:(CGPoint)pickPoint
{
    // Convert the point from UIKit coordinates to OpenGL coordinates.
    WWVec4* glPickPoint = [_navigatorState convertPointToViewport:pickPoint];
    GLint x = (GLint) [glPickPoint x];
    GLint y = (GLint) [glPickPoint y];

    GLubyte colorBytes[4];
    glReadPixels(x, y, 1, 1, GL_RGBA, GL_UNSIGNED_BYTE, colorBytes);
    unsigned int colorInt = [WWColor makeColorInt:colorBytes[0] g:colorBytes[1] b:colorBytes[2] a:colorBytes[3]];

    return colorInt != _clearColor ? colorInt : 0;
}

- (void) addPickedObject:(WWPickedObject*)pickedObject
{
    if (pickedObject != nil)
    {
        [_objectsAtPickPoint add:pickedObject];
    }
}

// STRINGIFY is used in the shader files.
#define STRINGIFY(A) #A
#import "WorldWind/Shaders/DefaultShader.vert"
#import "WorldWind/Shaders/DefaultShader.frag"
#import "WorldWind/Shaders/DefaultTextureShader.vert"
#import "WorldWind/Shaders/DefaultTextureShader.frag"

- (WWGpuProgram*) defaultProgram
{
    WWGpuProgram* program = [[self gpuResourceCache] getProgramForKey:defaultProgramKey];
    if (program != nil)
    {
        [program bind];
        [self setCurrentProgram:program];
        return program;
    }

    @try
    {
        program = [[WWGpuProgram alloc] initWithShaderSource:DefaultVertexShader
                                              fragmentShader:DefaultFragmentShader];
        [[self gpuResourceCache] putProgram:program forKey:defaultProgramKey];
        [program bind];
        [self setCurrentProgram:program];
    }
    @catch (NSException* exception)
    {
        WWLogE(@"making GPU program", exception);
    }

    return program;
}

- (WWGpuProgram*) defaultTextureProgram
{
    WWGpuProgram* program = [[self gpuResourceCache] getProgramForKey:defaultTextureProgramKey];
    if (program != nil)
    {
        [program bind];
        [self setCurrentProgram:program];
        return program;
    }

    @try
    {
        program = [[WWGpuProgram alloc] initWithShaderSource:DefaultTextureVertexShader
                                              fragmentShader:DefaultTextureFragmentShader];
        [[self gpuResourceCache] putProgram:program forKey:defaultTextureProgramKey];
        [program bind];
        [self setCurrentProgram:program];
    }
    @catch (NSException* exception)
    {
        WWLogE(@"making GPU program", exception);
    }

    return program;
}

- (GLuint) unitQuadBuffer
{
    NSNumber* vboId = (NSNumber*) [_gpuResourceCache getResourceForKey:unitQuadKey];
    if (vboId != nil)
    {
        return [vboId unsignedIntValue];
    }

    size_t size = (size_t) 8 * sizeof(GLfloat);
    GLfloat* points = malloc(size);

    @try
    {
        GLfloat* point = points;
        // upper left corner
        *point++ = 0;
        *point++ = 1;
        // lower left corner
        *point++ = 0;
        *point++ = 0;
        // upper right corner
        *point++ = 1;
        *point++ = 1;
        // lower right corner
        *point++ = 1;
        *point = 0;

        GLuint id;
        glGenBuffers(1, &id);
        glBindBuffer(GL_ARRAY_BUFFER, id);
        glBufferData(GL_ARRAY_BUFFER, size, points, GL_STATIC_DRAW);

        vboId = [[NSNumber alloc] initWithUnsignedInt:id];
        [_gpuResourceCache putResource:vboId resourceType:WW_GPU_VBO size:size forKey:unitQuadKey];
    }
    @finally
    {
        free(points);
        glBindBuffer(GL_ARRAY_BUFFER, 0);
    }

    return [vboId unsignedIntValue];
}

@end
