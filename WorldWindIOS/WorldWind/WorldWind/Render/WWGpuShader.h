/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>
#import <OpenGLES/ES2/gl.h>
#import "WorldWind/Util/WWCacheable.h"
#import "WorldWind/Util/WWDisposable.h"

/**
* Represents an OpenGL shading language (GLSL) shader. This class is used by WWGpuProgram and is not intended to be
* used directly by applications.
*/
@interface WWGpuShader : NSObject <WWCacheable, WWDisposable>
{
@protected
    GLuint type;
    long estimatedMemorySize;
}

/// @name GPU Shader Attributes

/// The OpenGL shader ID for this shader.
@property (readonly, nonatomic) GLuint shaderId;

/// @name Initializing GPU Shaders

/**
* Initializes a GPU shader of a specified type with the specified source.
*
* The shader is compiled and created within this method.
*
* An OpenGL context must be current when this method is called.
*
* If shader compilation fails an exception is thrown and the exception's description contains any compilation messages.
*
* @param shaderType The type of this shader, either GL_VERTEX_SHADER or GL_FRAGMENT_SHADER.
* @param source A null-terminated string containing the shader's source code.
*
* @return This GPU shader instance initialized with the specified source code.
*
* @exception NSInvalidArgumentException If the shader source is nil or empty, the shader cannot be created by OpenGL,
 * or the shader fails to compile.
*/
- (WWGpuShader*) initWithType:(GLuint)shaderType source:(const char*)source;

/// @name Operations on GPU Shaders

/**
* Releases this shader's OpenGL shader by calling glDeleteShader.
*
* Upon return, this shader's shaderId property is 0.
*
* An OpenGL context must be current when this method is called.
*/
- (void) dispose;

/// @name Suppporting Methods

/**
* Compiles the source for this shader.
*
* An OpenGL context must be current when this method is called.
*
* This method is not meant to be invoked by applications. It is invoked internally as needed.
*
* @param shaderType The type of this shader, either GL_VERTEX_SHADER or GL_FRAGMENT_SHADER.
* @param source A null-terminated string containing the shader's source code.
*
* @return YES if the shader compiled successfully, otherwise NO.
*/
- (BOOL) compile:(GLuint)shaderType source:(const char*)source;

@end