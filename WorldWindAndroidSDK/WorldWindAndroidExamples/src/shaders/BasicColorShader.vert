/*
 * Copyright (C) 2012 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 *
 * OpenGL ES Shading Language v1.00 vertex shader for rendering a shape with a uniform color. Transforms surface
 * geometry vertices from model coordinates to eye coordinates.
 *
 * version $Id$
 */

/*
 * Input vertex attribute defining the vertex point in model coordinates.
 */
attribute vec4 vertexPoint;
/*
 * Input uniform matrix defining the current modelview-projection transform matrix. Maps model coordinates to eye
 * coordinates.
 */
uniform mat4 mvpMatrix;

/*
 * OpenGL ES vertex shader entry point. Called for each vertex processed when this shader's program is bound.
 */
void main()
{
    /* Transform the surface vertex point from model coordinates to eye coordinates. */
    gl_Position = mvpMatrix * vertexPoint;
}
