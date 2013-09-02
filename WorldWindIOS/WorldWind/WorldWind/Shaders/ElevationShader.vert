const char* ElevationShadingVertexShader = STRINGIFY(
/* Copyright (C) 2013 United States Government as represented by
the Administrator of the National Aeronautics and Space Administration.
All Rights Reserved.
*/

/*
 * version $Id$
 */

attribute vec4 vertexPoint;
attribute float vertexElevation;

uniform mat4 mvpMatrix;

varying mediump float elevation;

void main()
{
    gl_Position = mvpMatrix * vertexPoint;
    elevation = vertexElevation;
}
);