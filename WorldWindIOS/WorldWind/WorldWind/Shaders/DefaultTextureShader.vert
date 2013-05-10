const char* DefaultTextureVertexShader = STRINGIFY(
/* Copyright (C) 2013 United States Government as represented by
the Administrator of the National Aeronautics and Space Administration.
All Rights Reserved.
*/

/*
 * OpenGL ES Shading Language v1.00 vertex shader for drawing simple textured geometry. Transforms vertex points from
 * model coordinates to eye coordinates and passes texture coordinates to the fragment shader as-is.
 *
 * version $Id$
 */

/*
 * Input vertex attribute defining the vertex point in model coordinates.
 */
attribute vec4 vertexPoint;
/*
 * Input vertex attribute defining the vertex texture coordinate.
 */
attribute vec4 vertexTexCoord;
/*
 * Input uniform matrix defining the current modelview-projection transform matrix. Maps model coordinates to eye
 * coordinates.
 */
uniform mat4 mvpMatrix;
/*
 * Output variable vector to the fragment shader defining the texture coordinate for each fragment. This is specified
 * for each vertex and is interpolated for each rasterized fragment of each primitive. Although the input attribute used
 * to compute this value is a vec4, we output this as a vec2 to avoid unnecessary swizzling in the fragment shader.
 */
varying vec2 texCoord;

/*
 * OpenGL ES vertex shader entry point. Called for each vertex processed when this shader's program is bound.
 */
void main()
{
    /* Transform the shape vertex point from model coordinates to eye coordinates. */
    gl_Position = mvpMatrix * vertexPoint;

    /* Pass the s- and t-coordinates in the vertex texture coordinate directly to the fragment shader. */
    texCoord = vertexTexCoord.st;
}
);
