const char* SurfaceTileRendererVertexShader = STRINGIFY(
/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id: SurfaceTileRenderer.vert 988 2012-12-14 21:32:33Z tgaskins $
 */

attribute vec4 vertexPoint;

attribute vec4 vertexTexCoord;

uniform mat4 mvpMatrix;

uniform mat4 tileCoordMatrix0;
uniform mat4 tileCoordMatrix1;
uniform mat4 tileCoordMatrix2;
uniform mat4 tileCoordMatrix3;

uniform mat4 texCoordMatrix0;
uniform mat4 texCoordMatrix1;
uniform mat4 texCoordMatrix2;
uniform mat4 texCoordMatrix3;

varying vec2 tileCoord0;
varying vec2 tileCoord1;
varying vec2 tileCoord2;
varying vec2 tileCoord3;

varying vec2 texCoord0;
varying vec2 texCoord1;
varying vec2 texCoord2;
varying vec2 texCoord3;

void main(void)
{
    gl_Position = mvpMatrix * vertexPoint;

    tileCoord0 = (tileCoordMatrix0 * vertexTexCoord).st;
    texCoord0 = (texCoordMatrix0 * vertexTexCoord).st;

    tileCoord1 = (tileCoordMatrix1 * vertexTexCoord).st;
    texCoord1 = (texCoordMatrix1 * vertexTexCoord).st;

    tileCoord2 = (tileCoordMatrix2 * vertexTexCoord).st;
    texCoord2 = (texCoordMatrix2 * vertexTexCoord).st;

    tileCoord3 = (tileCoordMatrix3 * vertexTexCoord).st;
    texCoord3 = (texCoordMatrix3 * vertexTexCoord).st;
}
);
