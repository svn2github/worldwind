/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Render/WWGpuShader.h"
#import "WorldWind/WWLog.h"

@implementation WWGpuShader

- (WWGpuShader*) initWithType:(GLuint)shaderType source:(char*)source
{
    if (shaderType != GL_VERTEX_SHADER && shaderType != GL_FRAGMENT_SHADER)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Shader type is invalid")
    }

    if (source == nil || strlen(source) == 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Shader source is empty")
    }

    GLuint shaderId = glCreateShader(shaderType);
    if (shaderId <= 0)
    {
        NSString* msg = [NSString stringWithFormat:@"Unable to create shader of type %d", shaderType];
        WWLOG_AND_THROW(NSInvalidArgumentException, msg);
    }

    if (![self compile:shaderId source:source])
    {
        // Get the info log before deleting the shader.
        GLsizei logSize = 0;
        glGetShaderiv(shaderId, GL_INFO_LOG_LENGTH, &logSize);
        GLchar log[logSize];
        glGetShaderInfoLog(shaderId, logSize, &logSize, log);

        glDeleteShader(shaderId);

        NSString* msg = [NSString stringWithFormat:@"Shader failed to compile: %s", log];
        WWLOG_AND_THROW(NSInvalidArgumentException, msg);
    }

    self->type = shaderType;
    self->estimatedMemorySize = strlen(source);
    _shaderId = shaderId;

    return self;
}

- (void) dispose
{
    if (_shaderId > 0)
    {
        glDeleteShader(_shaderId);
        _shaderId = 0;
    }
}

- (long) getSizeInBytes
{
    return self->estimatedMemorySize;
}

- (BOOL) compile:(GLuint)shaderId source:(const char*)source
{
    GLint const shaderLength [] = {strlen(source)};
    glShaderSource(shaderId, 1, &source, shaderLength);
    glCompileShader(shaderId);

    GLint compileStatus = GL_FALSE;
    glGetShaderiv(shaderId, GL_COMPILE_STATUS, &compileStatus);

    return compileStatus == GL_TRUE;
}

- (NSString*) nameFromShaderType:(GLuint)shaderType
{
    return shaderType == GL_VERTEX_SHADER ? @"Vertex Shader" : shaderType == GL_FRAGMENT_SHADER ? @"Fragment Shader"
            : nil;
}

@end