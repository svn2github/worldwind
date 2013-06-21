const char* BasicTextureFragmentShader = STRINGIFY(
/* Copyright (C) 2013 United States Government as represented by
the Administrator of the National Aeronautics and Space Administration.
All Rights Reserved.
*/

/*
 * OpenGL ES Shading Language v1.00 fragment shader for drawing simple textured geometry.
 *
 * version $Id$
 */

precision mediump float;

/*
 * Input uniform vec4 defining the current color. The texture color is multiplied by this color.
 */
uniform vec4 color;
/*
 * Input uniform bool indicating whether or not texturing is enabled. When true the fragment color is computed as the
 * product of the texture color and the uniform color. When false the uniform color indicates the fragment color.
 */
uniform bool enableTexture;
/*
 * Input uniform sampler defining the 2D texture sampler. This variable's value represents the texture unit
 * (0, 1, 2, etc.) that the tile's texture is bound to.
 */
uniform sampler2D textureSampler;
/*
 * Input varying vector from the vertex shader defining the texture coordinate for the current fragment. This texture
 coordinate is associated with the texture uniform sampler.
 */
varying vec2 texCoord;

/*
 * OpenGL ES fragment shader entry point. Called for each fragment rasterized when this shader's program is bound.
 */
void main()
{
    /* Compute the product of the texture color and the uniform color. This is (0, 0, 0, 0) if no texture is bound. */
    vec4 textureColor = texture2D(textureSampler, texCoord) * color;

    /* Select either the uniform color or the texture and uniform color. Avoid branching by mixing on the enable flag. */
    gl_FragColor = mix(color, textureColor, float(enableTexture));
}
);
