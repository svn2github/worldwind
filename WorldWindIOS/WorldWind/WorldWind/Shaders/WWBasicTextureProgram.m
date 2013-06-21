/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "WorldWind/Shaders/WWBasicTextureProgram.h"
#import "WorldWind/WWLog.h"

#define STRINGIFY(A) #A
#import "WorldWind/Shaders/BasicTextureShader.vert"
#import "WorldWind/Shaders/BasicTextureShader.frag"

@implementation WWBasicTextureProgram

- (WWBasicTextureProgram*) init
{
    self = [super initWithShaderSource:BasicTextureVertexShader fragmentShader:BasicTextureFragmentShader];

    _vertexPointLocation = (GLuint) [self getAttributeLocation:@"vertexPoint"];
    _vertexTexCoordLocation = (GLuint) [self getAttributeLocation:@"vertexTexCoord"];
    mvpMatrixLocation = (GLuint) [self getUniformLocation:@"mvpMatrix"];
    colorLocation = (GLuint) [self getUniformLocation:@"color"];
    textureEnabledLocation = (GLuint) [self getUniformLocation:@"enableTexture"];
    textureUnitLocation = (GLuint) [self getUniformLocation:@"textureSampler"];
    textureMatrixLocation = (GLuint) [self getUniformLocation:@"texCoordMatrix"];

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

- (void) loadColor:(WWColor* __unsafe_unretained)color
{
    if (color == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Color is nil")
    }

    [WWGpuProgram loadUniformColor:color location:colorLocation];
}

- (void) loadPickColor:(unsigned int)color
{
    [WWGpuProgram loadUniformPickColor:color location:colorLocation];
}

- (void) loadTextureEnabled:(BOOL)enable
{
    glUniform1i(textureEnabledLocation, enable);
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

@end