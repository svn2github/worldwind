const char* BasicFragmentShader = STRINGIFY(
/* Copyright (C) 2001, 2012 United States Government as represented by
the Administrator of the National Aeronautics and Space Administration.
All Rights Reserved.
*/

/*
 * OpenGL ES Shading Language v1.00 fragment shader for basic rendering. Draws fragments in a solid color.
 *
 * version $Id$
 */

precision mediump float;

/*
 * Input uniform vec4 defining the current color. Every fragment rasterized by this fragment shader is displayed in this
 * color.
 */
uniform vec4 color;

/*
 * OpenGL ES fragment shader entry point. Called for each fragment rasterized when this shader's program is bound.
 */
void main()
{
    gl_FragColor = color;
}
);