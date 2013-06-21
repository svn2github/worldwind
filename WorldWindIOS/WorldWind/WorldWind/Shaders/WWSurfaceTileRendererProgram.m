/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "WorldWind/Shaders/WWSurfaceTileRendererProgram.h"
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
    tileCoordMatrixLocation = (GLuint) [self uniformLocation:@"tileCoordMatrix"];
    textureUnitLocation = (GLuint) [self uniformLocation:@"textureSampler"];
    textureMatrixLocation = (GLuint) [self uniformLocation:@"texCoordMatrix"];
    opacityLocation = (GLuint) [self uniformLocation:@"opacity"];

    [self bind];
    glEnableVertexAttribArray(vertexPointLocation);
    glEnableVertexAttribArray(vertexTexCoordLocation);
    glUniform1i(textureUnitLocation, 0);
    glUseProgram(0);

    return self;
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

- (void) loadTileCoordMatrix:(WWMatrix* __unsafe_unretained)matrix
{
    if (matrix == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Matrix is nil")
    }

    [WWGpuProgram loadUniformMatrix:matrix location:tileCoordMatrixLocation];
}

- (void) loadTextureUnit:(GLenum)unit
{
    glUniform1i(textureUnitLocation, unit - GL_TEXTURE0);
}

- (void) loadTextureMatrix:(WWMatrix* __unsafe_unretained)matrix
{
    if (matrix == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Matrix is nil")
    }

    [WWGpuProgram loadUniformMatrix:matrix location:textureMatrixLocation];
}

- (void) loadOpacity:(GLfloat)opacity
{
    glUniform1f(opacityLocation, opacity);
}

@end