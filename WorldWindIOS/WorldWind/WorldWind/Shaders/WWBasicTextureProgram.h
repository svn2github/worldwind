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
@class WWTexture;

/**
* WWBasicTextureProgram is a GLSL program that draws geometry with a texture and solid color. When the texture is
* enabled the final fragment color is determined by multiplying the texture color with the solid color. Otherwise the
* fragment color is that of the solid color. WWBasicTextureProgram exposes the following vertex attributes and uniform
* variables to configure its behavior:
*
* ###Vertex Attributes###
*
* `vec4 vertexPoint` - The geometry's vertex points, in model coordinates. This attribute's location is provided by
* the vertexPointLocation property.
*
* `vec4 vertexTexCoord` - The geometry's vertex texture coordinates. This attribute's location is provided by
* the vertexTexCoordLocation property.
*
* ###Uniform Variables###
*
* `mat4 mvpMatrix` - The modelview-projection matrix used to transform the `vertexPoint` attribute. Specified using
* loadModelviewProjection:.
*
* `mat4 texCoordMatrix` - The matrix used to transform the `vertexTexCoord` attribute. Specified using
* loadTextureMatrix:.
*
* `vec4 color` - The RGBA color used to draw the geometry. Specified using either of loadColor: or loadPickColor:.
*
* `bool enableTexture` - YES to enable texturing; otherwise NO. Specified using loadTextureEnabled:.
*
* `sampler2D textureSampler` - The texture unit the texture is bound to (GL_TEXTURE0, GL_TEXTURE1, GL_TEXTURE2, etc.).
* Specified using loadTextureUnit:.
*/
@interface WWBasicTextureProgram : WWGpuProgram
{
@protected
    GLuint vertexPointLocation;
    GLuint vertexTexCoordLocation;
    GLuint mvpMatrixLocation;
    GLuint colorLocation;
    GLuint textureEnabledLocation;
    GLuint textureUnitLocation;
    GLuint textureMatrixLocation;
}

/// @name GPU Program Attributes

/**
* Returns a unique string appropriate for identifying a shared instance of WWBasicTextureProgram in a
* WWGpuResourceCache.
*
* @return A unique string identifier for WWBasicTextureProgram.
*/
+ (NSString*) programKey;

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
- (WWBasicTextureProgram*) init;

/// @name Accessing Vertex Attributes

/**
 * Indicates the OpenGL location index for this program's `vertexPoint` vertex attribute.
 *
 * The returned value is suitable for use as the index argument in glVertexAttribPointer.
 *
 * @return The location index for this program's `vertexPoint` vertex attribute.
 */
- (GLuint) vertexPointLocation;

/**
 * Indicates the OpenGL location index for this program's `vertexTexCoord` vertex attribute.
 *
 * The returned value is suitable for use as the index argument in glVertexAttribPointer.
 *
 * @return The location index for this program's `vertexTexCoord` vertex attribute.
 */
- (GLuint) vertexTexCoordLocation;

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

/**
* Loads the specified boolean as the value of this program's `enableTexture` uniform variable.
*
* An OpenGL context must be current when this method is called, and this program must be bound. The result of this
* method is undefined if there is no current OpenGL context or if this program is not bound.
*
* Specifying YES causes this program to sample the currently bound texture at the texture unit indicated by the
* `textureSampler` uniform variable. The fragment color is determined by multiplying the texture color with the `color`
* uniform variable. Specifying NO causes this program to ignore the currently bound texture. The fragment color is then
* equivalent to the `color` uniform variable.
*
* @param enable YES to enable texturing; otherwise NO.
*/
- (void) loadTextureEnabled:(BOOL)enable;

/**
* Loads the specified OpenGL texture unit enumeration as the value of this program's `textureSampler` uniform variable.
*
* An OpenGL context must be current when this method is called, and this program must be bound. The result of this
* method is undefined if there is no current OpenGL context or if this program is not bound.
*
* The specified unit must be one of the GL_TEXTUREi OpenGL enumerations, where i ranges from 0 to
* (GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS - 1). The value is converted from an enumeration to a GLSL texture unit index
* prior to loading the unit in the GLSL uniform variable.
*
* @param unit The OpenGL texture unit to sample. Must be one of GL_TEXTUREi, where i ranges from 0 to
* (GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS - 1)
*/
- (void) loadTextureUnit:(GLenum)unit;

/**
* Loads the specified matrix as the value of this program's `texCoordMatrix` uniform variable.
*
* An OpenGL context must be current when this method is called, and this program must be bound. The result of this
* method is undefined if there is no current OpenGL context or if this program is not bound.
*
* @param matrix The matrix to set the uniform variable to.
*
* @exception NSInvalidArgumentException If the matrix is nil.
*/
- (void) loadTextureMatrix:(WWMatrix*)matrix;

@end