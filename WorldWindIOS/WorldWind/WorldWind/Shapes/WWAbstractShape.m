/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Shapes/WWAbstractShape.h"
#import "WorldWind/Shapes/WWShapeAttributes.h"
#import "WorldWind/Util/WWColor.h"
#import "WorldWind/WorldWindConstants.h"
#import "WorldWind/Util/WWUtil.h"
#import "WorldWind/Geometry/WWMatrix.h"
#import "WorldWind/Geometry/WWVec4.h"
#import "WorldWind/Render/WWDrawContext.h"
#import "WorldWind/Geometry/WWExtent.h"
#import "WorldWind/Navigate/WWNavigatorState.h"
#import "WorldWind/Render/WWGpuProgram.h"
#import "WorldWind/Util/WWGpuResourceCache.h"
#import "WorldWind/WWLog.h"

@implementation WWAbstractShape

- (WWAbstractShape*) init
{
    self = [super init];

    self->defaultAttributes = [[WWShapeAttributes alloc] init];
    [self setDefaultAttributes];

    _highlighted = NO;
    _enabled = YES;
    _altitudeMode = WW_ALTITUDE_MODE_ABSOLUTE;

    self->transformationMatrix = [[WWMatrix alloc] initWithIdentity];
    self->programKey = [WWUtil generateUUID];
    self->referencePoint = [[WWVec4 alloc] initWithZeroVector];

    return self;
}

- (void) reset
{
}

- (void) setDefaultAttributes
{
    [self->defaultAttributes setInteriorEnabled:NO];
    [self->defaultAttributes setInteriorColor:[[WWColor alloc] initWithR:0.75 g:0.75 b:0.75 a:1]];

    [self->defaultAttributes setOutlineEnabled:YES];
    [self->defaultAttributes setOutlineColor:[[WWColor alloc] initWithR:0.25 g:0.25 b:0.25 a:1]];
    [self->defaultAttributes setOutlineWidth:1];
}

- (BOOL) isDrawOutline:(WWDrawContext*)dc
{
    return [self mustDrawOutline];
}

- (BOOL) isDrawInterior:(WWDrawContext*)dc
{
    return [self mustDrawInterior];
}

- (void) drawOutline:(WWDrawContext*)dc
{
    [self prepareToDrawOutline:dc attributes:self->activeAttributes];
    [self doDrawOutline:dc];
}

- (void) drawInterior:(WWDrawContext*)dc
{
    [self prepareToDrawInterior:dc attributes:self->activeAttributes];
    [self doDrawInterior:dc];
}

- (BOOL) isEnableDepthOffset:(WWDrawContext*)dc
{
    return NO;
}

- (float) depthOffsetFactor:(WWDrawContext*)dc
{
    return 1;
}

- (float) depthOffsetUnits:(WWDrawContext*)dc
{
    return 1;
}

- (void) render:(WWDrawContext*)dc
{
    if (!_enabled || ![self intersectsFrustum:dc] || [dc isSmall:_extent numPixels:1])
    {
        return;
    }

    if ([dc orderedRenderingMode])
    {
        [self drawOrderedRenderable:dc];
    }
    else
    {
        [self makeOrderedRenderable:dc];
    }
}

- (BOOL) intersectsFrustum:(WWDrawContext*)dc
{
    return _extent == nil || [_extent intersects:[[dc navigatorState] frustumInModelCoordinates]];
}

- (void) makeOrderedRenderable:(WWDrawContext*)dc
{
    [self determineActiveAttributes];
    if (self->activeAttributes == nil)
    {
        return;
    }

    if ([self mustRegenerateGeometry:dc])
    {
        [self doMakeOrderedRenderable:dc];

        // Remember the vertical exaggeration used to make this path.
        self->verticalExaggeration = [dc verticalExaggeration];
    }

    if ([self isOrderedRenderableValid:dc] && [self intersectsFrustum:dc] && ![dc isSmall:_extent numPixels:1])
    {
        [self addOrderedRenderable:dc];
    }
}

- (void) doMakeOrderedRenderable:(WWDrawContext*)dc
{
    // Must be implemented by subclass
}

- (BOOL) isOrderedRenderableValid:(WWDrawContext*)dc
{
    // Must be implemented by subclass

    return NO;
}

- (void) addOrderedRenderable:(WWDrawContext*)dc
{
    [dc addOrderedRenderable:self];
}

- (void) drawOrderedRenderable:(WWDrawContext*)dc
{
    [self beginDrawing:dc];

    @try
    {
        [self doDrawOrderedRenderable:dc];
    }
    @finally
    {
        [self endDrawing:dc];
    }

}

- (void) doDrawOrderedRenderable:(WWDrawContext*)dc
{
    [self applyModelviewProjectionMatrix:dc];
    [dc drawOutlinedShape:self];
}

- (BOOL) mustRegenerateGeometry:(WWDrawContext*)dc
{
    // Should be implemented by subclass

    return YES;
}

- (void) determineActiveAttributes
{
    if (_highlighted && _highlightAttributes != nil)
    {
        self->activeAttributes = _highlightAttributes;
    }
    else if (_attributes != nil)
    {
        self->activeAttributes = _attributes;
    }
    else
    {
        self->activeAttributes = self->defaultAttributes;
    }
}

- (BOOL) mustDrawInterior
{
    return self->activeAttributes != nil && [self->activeAttributes interiorEnabled];
}

- (BOOL) mustDrawOutline
{
    return self->activeAttributes != nil && [self->activeAttributes outlineEnabled];
}

- (void) beginDrawing:(WWDrawContext*)dc
{
    WWGpuProgram* program = [self gpuProgram:dc];
    if (program == nil)
    {
        return;
    }

    [dc setCurrentProgram:program];
    [program bind];

    int attributeLocation = [program getAttributeLocation:@"vertexPoint"];
    if (attributeLocation >= 0)
    {
        glEnableVertexAttribArray((GLuint) attributeLocation);
        glDisable(GL_CULL_FACE);
    }
}

- (void) endDrawing:(WWDrawContext*)dc
{
    WWGpuProgram* program = [dc currentProgram];
    if (program == nil)
    {
        return;
    }

    // Disable the program's vertexPoint attribute. This restores the program state modified in beginDrawing. This
    // must be done while the program is still bound.
    int attributeLocation = [program getAttributeLocation:@"vertexPoint"];
    if (attributeLocation >= 0)
    {
        glDisableVertexAttribArray((GLuint) attributeLocation);
    }

    [dc setCurrentProgram:nil];
    glUseProgram(0);

    // Restore OpenGL state.
    glEnable(GL_CULL_FACE);
    glDepthMask(GL_TRUE);
    glLineWidth(1);
}

- (void) applyModelviewProjectionMatrix:(WWDrawContext*)dc
{
    WWMatrix* mvp = [[WWMatrix alloc] initWithMultiply:[[dc navigatorState] modelviewProjection]
                                               matrixB:self->transformationMatrix];
    [dc.currentProgram loadUniformMatrix:@"mvpMatrix" matrix:mvp];
}

- (void) prepareToDrawInterior:(WWDrawContext*)dc attributes:(WWShapeAttributes*)attributes
{
    if (attributes == nil || ![attributes interiorEnabled])
    {
        return;
    }

    WWColor* color = [[WWColor alloc] initWithColor:[attributes interiorColor]];

    // Disable writing the shape's interior fragments to the depth buffer when the interior is semi-transparent.
    if ([color a] < 1)
    {
        glDepthMask(GL_FALSE);
    }

    // Load the current interior color into the current program's uniform variable. Pass a pre-multiplied color because
    // the scene controller configures the OpenGL blending mode for pre-multiplied colors.
    [color preMultiply];
    [[dc currentProgram] loadUniformColor:@"color" color:color];
}

- (void) doDrawInterior:(WWDrawContext*)dc
{
    // Must be implemented by subclasses.
}

- (void) prepareToDrawOutline:(WWDrawContext*)dc attributes:(WWShapeAttributes*)attributes
{
    if (attributes == nil || ![attributes outlineEnabled])
    {
        return;
    }

    WWColor* color = [[WWColor alloc] initWithColor:[attributes outlineColor]];

    // Load the current outline color into the current program's uniform variable. Pass a pre-multiplied color because
    // the scene controller configures the OpenGL blending mode for pre-multiplied colors.
    [color preMultiply];
    [[dc currentProgram] loadUniformColor:@"color" color:color];

    glLineWidth([attributes outlineWidth]);
}

- (void) doDrawOutline:(WWDrawContext*)dc
{
    // Must be implemented by subclasses.
}

// STRINGIFY is used in the shader files.
#define STRINGIFY(A) #A

#import "WorldWind/Shaders/AbstractShape.vert"
#import "WorldWind/Shaders/AbstractShape.frag"

- (WWGpuProgram*) gpuProgram:(WWDrawContext*)dc
{
    WWGpuProgram* program = [[dc gpuResourceCache] getProgramForKey:self->programKey];
    if (program != nil)
        return program;

    @try
    {
        program = [[WWGpuProgram alloc] initWithShaderSource:AbstractShapeVertexShader
                                              fragmentShader:AbstractShapeFragmentShader];
        [[dc gpuResourceCache] putProgram:program forKey:self->programKey];
    }
    @catch (NSException* exception)
    {
        WWLogE(@"making GPU program", exception);
    }

    return program;
}

@end