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
#import "WorldWind/WWLog.h"
#import "WorldWind/Util/WWGpuResourceCache.h"
#import "WorldWind/Util/WWUtil.h"
#import "WorldWind/Render/WWGpuProgram.h"

@implementation WWDrawContext

- (WWDrawContext*) init
{
    self = [super init];

    _surfaceTileRenderer = [[WWSurfaceTileRenderer alloc] init];
    _verticalExaggeration = 1;
    _timestamp = [NSDate date];
    _eyePosition = [[WWPosition alloc] initWithDegreesLatitude:0 longitude:0 altitude:0];
    _terrain = [[WWBasicTerrain alloc] initWithDrawContext:self];
    _orderedRenderables = [[NSMutableArray alloc] init];
    _screenProjection = [[WWMatrix alloc] initWithIdentity];

    programKey = [WWUtil generateUUID];

    return self;
}

- (void) reset
{
    _timestamp = [NSDate date];
    _verticalExaggeration = 1;

    [_orderedRenderables removeAllObjects];
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

- (void) addOrderedRenderable:(id <WWOrderedRenderable>)orderedRenderable
{
    if (orderedRenderable != nil)
    {
        [orderedRenderable setInsertionTime:[NSDate timeIntervalSinceReferenceDate]];
        [_orderedRenderables addObject:orderedRenderable];
    }
}

- (void) addOrderedRenderableToBack:(id <WWOrderedRenderable>)orderedRenderable
{
    if (orderedRenderable != nil)
    {
        [orderedRenderable setEyeDistance:DBL_MAX];
        [_orderedRenderables addObject:orderedRenderable];
    }
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

// STRINGIFY is used in the shader files.
#define STRINGIFY(A) #A
#import "WorldWind/Shaders/DefaultShader.vert"
#import "WorldWind/Shaders/DefaultShader.frag"

- (WWGpuProgram*) defaultProgram
{
    WWGpuProgram* program = [[self gpuResourceCache] getProgramForKey:programKey];
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
        [[self gpuResourceCache] putProgram:program forKey:self->programKey];
        [program bind];
        [self setCurrentProgram:program];
    }
    @catch (NSException* exception)
    {
        WWLogE(@"making GPU program", exception);
    }

    return program;
}

@end
