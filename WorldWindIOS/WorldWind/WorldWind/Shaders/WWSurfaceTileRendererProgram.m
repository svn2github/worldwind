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

    _vertexPointLocation = (GLuint) [self getAttributeLocation:@"vertexPoint"];
    _vertexTexCoordLocation = (GLuint) [self getAttributeLocation:@"vertexTexCoord"];
    mvpMatrixLocation = (GLuint) [self getUniformLocation:@"mvpMatrix"];
    tileCoordMatrixLocation = (GLuint) [self getUniformLocation:@"tileCoordMatrix"];
    textureUnitLocation = (GLuint) [self getUniformLocation:@"textureSampler"];
    textureMatrixLocation = (GLuint) [self getUniformLocation:@"texCoordMatrix"];
    opacityLocation = (GLuint) [self getUniformLocation:@"opacity"];

    [self bind];
    glEnableVertexAttribArray(_vertexPointLocation);
    glEnableVertexAttribArray(_vertexTexCoordLocation);
    glUniform1i(textureUnitLocation, 0);
    glUseProgram(0);

    return self;
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