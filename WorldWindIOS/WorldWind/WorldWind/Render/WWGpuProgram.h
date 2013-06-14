/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>
#import <OpenGLES/ES2/gl.h>
#import "WorldWind/Util/WWCacheable.h"
#import "WorldWind/Util/WWDisposable.h"

@class WWGpuShader;
@class WWMatrix;
@class WWColor;

/**
* Represents an OpenGL shading language (GLSL) shader program and provides methods for identifying and accessing shader
* variables. Shader programs are created by instances of this class and made current when the instance's bind
* method is invoked.
*/
@interface WWGpuProgram : NSObject <WWCacheable, WWDisposable>
{
@protected
    WWGpuShader* vertexShader;
    WWGpuShader* fragmentShader;
    NSMutableDictionary* attributeLocations;
    NSMutableDictionary* uniformLocations;
}

/// @name GPU Program Attributes

/// The OpenGL program ID of this shader.
@property(readonly, nonatomic) GLuint programId;

/// @name Initializing GPU Programs

/**
* Initializes a GPU program with specified source code for vertex and fragment shaders.
*
* An OpenGL context must be current when this method is called.
*
* This method creates OpenGL shaders for the specified shader sources and attaches them to a new GLSL program. The
* method compiles the shaders and links the program if compilation is successful. Use the bind method to make the
* program current during rendering.
*
* @param vertexSource A null-terminated string containing the source code for the vertex shader.
* @param fragmentSource A null-terminated string containing the source code for the fragment shader.
*
* @return This GPU program linked with the specified shaders.
*
* @exception NSInvalidArgumentException If either shader source is nil or empty, the shaders cannot be compiled, or
* linking of the compiled shaders into a program fails.
*/
- (WWGpuProgram*) initWithShaderSource:(const char*)vertexSource fragmentShader:(const char*)fragmentSource;

/// @name Operations on GPU Programs

/**
* Makes this GPU program the current program in the current OpenGL context.
*
* An OpenGL context must be current when this method is called.
*/
- (void) bind;

/**
* Releases this GPU program's OpenGL program and associated shaders. Upon return this GPU program's OpenGL program ID
 * is 0 as is that of its associated shaders.
 *
 * An OpenGL context must be current when this method is called.
*/
- (void) dispose;

/// @name Accessing Shader Variables

/**
* Returns the GLSL attribute location of a specified attribute name.
*
* An OpenGL context must be current when this method is called.
*
* @param attributeName The name of the attribute whose location is determined.
*
* @return The OpenGL attribute location of the specified attribute, or -1 if the attribute is not found.
*
* @exception NSInvalidArgumentException If the specified name is nil or empty.
*/
- (int) getAttributeLocation:(NSString*)attributeName;

/**
* Returns the GLSL uniform variable location of a specified uniform name.
*
* An OpenGL context must be current when this method is called.
*
* @param uniformName The name of the uniform variable whose location is determined.
*
* @return The OpenGL location of the specified uniform variable, or -1 if the name is not found.
*
* @exception NSInvalidArgumentException If the specified name is nil or empty.
*/
- (int) getUniformLocation:(NSString*)uniformName;

/**
* Sets the values of a named uniform matrix variable to those of a specified matrix.
*
* An OpenGL context must be current when this method is called.
*
* @param uniformName The name of the uniform matrix variable.
* @param matrix The values to set the uniform matrix variable to.
*
* @exception NSInvalidArgumentException If the uniform variable's name is nil or empty, the specified matrix is nil,
* or the named uniform variable does not exist.
*/
- (void) loadUniformMatrix:(NSString*)uniformName matrix:(WWMatrix*)matrix;

/**
* Sets the value of a named uniform sampler to a specified value.
*
* An OpenGL context must be current when this method is called.
*
* @param samplerName The name of the uniform sampler.
* @param value The value to set the sampler to.
*
* @exception NSInvalidArgumentException If the specified sampler name is nil or empty or the sampler does not exist
* in the program.
*/
- (void) loadUniformSampler:(NSString*)samplerName value:(int)value;

/**
* Sets the value of a named uniform color to a specified value.
*
* An OpenGL context must be current when this method is called.
*
* @param colorName The name of the uniform color.
* @param color The value to set the color to.
*
* @exception NSInvalidArgumentException If the specified color name is nil or empty,
* the color does not exist in the program or the specified color is nil.
*/
- (void) loadUniformColor:(NSString*)colorName color:(WWColor*)color;

/**
* Sets the value of a named uniform color to a value specified as a packed RGBA 32-bit unsigned integer.
*
* @param colorName The name of the uniform color.
* @param color The value to set the color to, in the form of a packed RGBA 32-bit unsigned integer.
*
* @exception NSInvalidArgumentException If the specified color name is nil or empty.
*/
- (void) loadUniformColorInt:(NSString*)colorName color:(unsigned int)color;

/**
* Sets the value of a named uniform float to a specified value.
*
* An OpenGL context must be current when this method is called.
*
* @param uniformName The name of the uniform variable.
* @param value The value to set the uniform variable to.
*
* @exception NSInvalidArgumentException If the specified uniform name is nil or empty or the uniform variable does
* not exist in the program.
*/
- (void) loadUniformFloat:(NSString*)uniformName value:(float)value;

/**
* Sets the value of a named uniform int to a specified value.
*
* An OpenGL context must be current when this method is called.
*
* @param uniformName The name of the uniform variable.
* @param value The value to set the uniform variable to.
*
* @exception NSInvalidArgumentException If the specified uniform name is nil or empty or the uniform variable does
* not exist in the program.
*/
- (void) loadUniformInt:(NSString*)uniformName value:(int)value;

/**
* Sets the value of a named uniform bool to a specified value.
*
* An OpenGL context must be current when this method is called.
*
* @param uniformName The name of the uniform variable.
* @param value The value to set the uniform variable to.
*
* @exception NSInvalidArgumentException If the specified uniform name is nil or empty or the uniform variable does
* not exist in the program.
*/
- (void) loadUniformBool:(NSString*)uniformName value:(BOOL)value;

/// @name Supporting Methods

/**
* Links the specified GLSL program.
*
* An OpenGL context must be current when this method is called.
*
* This method is not meant to be invoked by applications. It is invoked internally as needed.
*
* @param program The OpenGL program ID of the program to link.
*
* @return YES if linking was successful, otherwise NO.
*/
- (BOOL) link:(GLuint)program;

@end