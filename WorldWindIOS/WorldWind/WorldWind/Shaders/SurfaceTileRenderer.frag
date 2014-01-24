const char* SurfaceTileRendererFragmentShader = STRINGIFY(
/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

precision mediump float;

/* Uniform sampler indicating the texture 2D unit (0, 1, 2, etc.) to use when sampling texture color. */
uniform sampler2D texSampler;
/* Uniform float indicating opacity variable in the range [0,1], although the range is not checked. */
uniform float opacity;
/* Varying vertex indicating the sampler texture coordinate. */
varying vec2 texSamplerCoord;
/* Varying vertex indicating the mask texture coordinate. */
varying vec2 texMaskCoord;

/*
 * Returns 1.0 when the coordinate's s- and t-components are in the range [0,1], and returns 0.0 otherwise. The
 * returned float can be muptilied by a sampled texture color in order to mask fragments of a textured primitive when
 * its texture coordinates result in texels that are either repeated or clamped to the texture's edge.
 */
float texture2DWrapMask(const vec2 coord)
{
    vec2 maskVec = vec2(greaterThanEqual(coord, vec2(0.0))) * vec2(lessThanEqual(coord, vec2(1.0)));
    return maskVec.x * maskVec.y;
}
                                                          
/*
 * OpenGL ES Shading Language v1.00 fragment shader for SurfaceTileRendererProgram. Writes the value of the texture 2D
 * object bound to texSampler at the current transformed texture coordinate, multiplied by the uniform opacity.
 * Writes transparent black (0, 0, 0, 0) if the transformed texture coordinate indicates a texel outside of the texture
 * data's standard range of [0,1].
 */
void main(void)
{
    gl_FragColor = texture2D(texSampler, texSamplerCoord) * texture2DWrapMask(texMaskCoord) * opacity;
}
);
