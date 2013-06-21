/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "WorldWind/Shaders/WWBasicTextureProgram.h"
#import "WorldWind/Util/WWUtil.h"
#import "WorldWind/WWLog.h"

#define STRINGIFY(A) #A
#import "WorldWind/Shaders/BasicTextureShader.vert"
#import "WorldWind/Shaders/BasicTextureShader.frag"

@implementation WWBasicTextureProgram

- (WWBasicTextureProgram*) init
{
    self = [super initWithShaderSource:BasicTextureVertexShader fragmentShader:BasicTextureFragmentShader];

    vertexPointLocation = (GLuint) [self attributeLocation:@"vertexPoint"];
    vertexTexCoordLocation = (GLuint) [self attributeLocation:@"vertexTexCoord"];
    mvpMatrixLocation = (GLuint) [self uniformLocation:@"mvpMatrix"];
    colorLocation = (GLuint) [self uniformLocation:@"color"];
    textureEnabledLocation = (GLuint) [self uniformLocation:@"enableTexture"];
    textureUnitLocation = (GLuint) [self uniformLocation:@"textureSampler"];
    textureMatrixLocation = (GLuint) [self uniformLocation:@"texCoordMatrix"];

    [self bind];
    glEnableVertexAttribArray(vertexPointLocation);
    glEnableVertexAttribArray(vertexTexCoordLocation);
    glUniform1i(textureUnitLocation, 0);
    glUseProgram(0);

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