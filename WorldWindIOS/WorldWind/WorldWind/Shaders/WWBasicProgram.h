/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>
#import <OpenGLES/ES2/gl.h>
#import "WorldWind/Render/WWGpuProgram.h"

@class WWColor;
@class WWMatrix;

/**
* WWBasicProgram is a GLSL program that draws geometry in a solid color. WWBasicProgram exposes the following vertex
* attributes and uniform variables to configure its behavior:
*
* ###Vertex Attributes###
*
* `vec4 vertexPoint` - The geometry's vertex points, in model coordinates. This attribute's location is provided by
* the vertexPointLocation property.
*
* ###Uniform Variables###
*
* `mat4 mvpMatrix` - The modelview-projection matrix used to transform the `vertexPoint` attribute. Specified using
* loadModelviewProjection:.
*
* `vec4 color` - The RGBA color used to draw the geometry. Specified using either of loadColor: or loadPickColor:.
*/
@interface WWBasicProgram : WWGpuProgram
{
@protected
    GLuint vertexPointLocation;
    GLuint mvpMatrixLocation;
    GLuint colorLocation;
}

/// @name Initializing GPU Programs

/**
* Initializes, compiles and links this GLSL program with the source code for its vertex and fragment shaders.
*
* An OpenGL context must be current when this method is called.
*
* This method creates OpenGL shaders for the program's shader sources and attaches them to a new GLSL program. This
* method then compiles the shaders and links the program if compilation is successful. Use the bind method to make the
* program current during rendering.
*
* @return This GLSL program linked with its shaders.
*
* @exception NSInvalidArgumentException If the shaders cannot be compiled, or linking of the compiled shaders into a
* program fails.
*/
- (WWBasicProgram*) init;

/// @name Accessing Vertex Attributes

/**
 * Indicates the OpenGL location index for this program's `vertexPoint` vertex attribute.
 *
 * The returned value is suitable for use as the index argument in glVertexAttribPointer.
 *
 * @return The location index for this program's `vertexPoint` vertex attribute.
 */
- (GLuint) vertexPointLocation;

/// @name Accessing Uniform Variables

/**
* Loads the specified matrix as the value of this program's `mvpMatrix` uniform variable.
*
* An OpenGL context must be current when this method is called, and this program must be bound. The result of this
* method is undefined if there is no current OpenGL context or if this program is not bound.
*
* @param matrix The matrix to set the uniform variable to.
*
* @exception NSInvalidArgumentException If the matrix is nil.
*/
- (void) loadModelviewProjection:(WWMatrix*)matrix;

/**
* Loads the specified color as the value of this program's `color` uniform variable.
*
* An OpenGL context must be current when this method is called, and this program must be bound. The result of this
* method is undefined if there is no current OpenGL context or if this program is not bound.
*
* The color must be defined in the standard RGBA color space and must not be pre-multiplied.
*
* @param color The color to set the uniform variable to.
*
* @exception NSInvalidArgumentException If the color is nil.
*/
- (void) loadColor:(WWColor*)color;

/**
* Loads the specified pick color as the value of this program's `color` uniform variable.
*
* An OpenGL context must be current when this method is called, and this program must be bound. The result of this
* method is undefined if there is no current OpenGL context or if this program is not bound.
*
* @param color The color to set the uniform variable to.
*/
- (void) loadPickColor:(unsigned int)color;

@end