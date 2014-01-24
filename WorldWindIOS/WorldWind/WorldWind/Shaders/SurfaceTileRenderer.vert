const char* SurfaceTileRendererVertexShader = STRINGIFY(
/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

/* Vertex attribute indicating the primitive's vertex point in model coordinates. */
attribute vec4 vertexPoint;
/* Vertex attribute indicating the primitive's vertex texture coordinate. */
attribute vec4 vertexTexCoord;
/* Uniform matrix that transforms model coordinates to clip coordinates. */
uniform mat4 mvpMatrix;
/* Uniform matrix that transforms vertex texture coordinates to sampler texture coordinates. */
uniform mat4 texSamplerMatrix;
/* Uniform matrix that transforms vertex texture coordinates to mask texture coordinates. */
uniform mat4 texMaskMatrix;
/* Varying vertex indicating the sampler texture coordinate. */
varying vec2 texSamplerCoord;
/* Varying vertex indicating the mask texture coordinate. */
varying vec2 texMaskCoord;

/*
 * OpenGL ES Shading Language v1.00 vertex shader for SurfaceTileRendererProgram. Transforms primitive vertex points
 * from model coordinates to clip coordinates, and transforms primitive vertex texture coordinates to sampler texture
 * coordinates and mask texture coordinates.
 */
void main(void)
{
    /* Transform the vertex point from model coordinates to clip coordinates. */
    gl_Position = mvpMatrix * vertexPoint;

    /* Transform the vertex texture coordinate into sampler texture coordinates. */
    texSamplerCoord = (texSamplerMatrix * vertexTexCoord).st;

    /* Transform the vertex texture coordinate into mask texture coordinates. */
    texMaskCoord = (texMaskMatrix * vertexTexCoord).st;
}
);
