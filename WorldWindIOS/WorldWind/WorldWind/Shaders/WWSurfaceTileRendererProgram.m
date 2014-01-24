/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "WorldWind/Shaders/WWSurfaceTileRendererProgram.h"
#import "WorldWind/Util/WWUtil.h"
#import "WorldWind/WWLog.h"

#define STRINGIFY(A) #A
#import "WorldWind/Shaders/SurfaceTileRenderer.frag"
#import "WorldWind/Shaders/SurfaceTileRenderer.vert"

@implementation WWSurfaceTileRendererProgram

- (WWSurfaceTileRendererProgram*) init
{
    self = [super initWithShaderSource:SurfaceTileRendererVertexShader fragmentShader:SurfaceTileRendererFragmentShader];

    vertexPointLocation = (GLuint) [self attributeLocation:@"vertexPoint"];
    vertexTexCoordLocation = (GLuint) [self attributeLocation:@"vertexTexCoord"];
    mvpMatrixLocation = (GLuint) [self uniformLocation:@"mvpMatrix"];
    texSamplerMatrixLocation = (GLuint) [self uniformLocation:@"texSamplerMatrix"];
    texMaskMatrixLocation = (GLuint) [self uniformLocation:@"texMaskMatrix"];
    texSamplerLocation = (GLuint) [self uniformLocation:@"texSampler"];
    opacityLocation = (GLuint) [self uniformLocation:@"opacity"];

    return self;
}

+ (NSString*) programKey
{
    static NSString* key = nil;
    if (key == nil)
    {
        key = [WWUtil generateUUID];
    }

    return key;
}

- (GLuint) vertexPointLocation
{
    return vertexPointLocation;
}

- (GLuint) vertexTexCoordLocation
{
    return vertexTexCoordLocation;
}

- (void) loadModelviewProjection:(WWMatrix* __unsafe_unretained)matrix
{
    if (matrix == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Matrix is nil")
    }

    [WWGpuProgram loadUniformMatrix:matrix location:mvpMatrixLocation];
}

- (void) loadTexSamplerMatrix:(WWMatrix* __unsafe_unretained)matrix
{
    if (matrix == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Matrix is nil")
    }

    [WWGpuProgram loadUniformMatrix:matrix location:texSamplerMatrixLocation];
}

- (void) loadTexMaskMatrix:(WWMatrix* __unsafe_unretained)matrix
{
    if (matrix == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Matrix is nil")
    }

    [WWGpuProgram loadUniformMatrix:matrix location:texMaskMatrixLocation];
}

- (void) loadTexSampler:(GLenum)unit
{
    glUniform1i(texSamplerLocation, unit - GL_TEXTURE0);
}

- (void) loadOpacity:(GLfloat)opacity
{
    glUniform1f(opacityLocation, opacity);
}

@end