const char* SurfaceTileRendererFragmentShader = STRINGIFY(
/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id: SurfaceTileRenderer.frag 1247 2013-03-27 22:20:26Z tgaskins $
 */

precision mediump float;
precision mediump int;

uniform float opacity;

uniform int numTextures;

uniform sampler2D tileTexture0;
uniform sampler2D tileTexture1;
uniform sampler2D tileTexture2;
uniform sampler2D tileTexture3;

varying vec2 tileCoord0;
varying vec2 tileCoord1;
varying vec2 tileCoord2;
varying vec2 tileCoord3;

varying vec2 texCoord0;
varying vec2 texCoord1;
varying vec2 texCoord2;
varying vec2 texCoord3;

const float FZERO = 0.0;
const float FONE = 1.0;
const vec4 TRANSPARENT = vec4(0.0, 0.0, 0.0, 0.0);

float getFactor(vec2 tileCoord)
{
    return float(tileCoord.s >= FZERO && tileCoord.s <= FONE && tileCoord.t >= FZERO && tileCoord.t <= FONE);
}

void main(void)
{
    if (numTextures == 1)
    float factor = getFactor(tileCoord0);
    if (factor > FZERO)
    {
        gl_FragColor = texture2D(tileTexture0, texCoord0) * factor * opacity;
        return;
    }

    if (numTextures == 1)
    {
        gl_FragColor = TRANSPARENT;
        return;
    }

    factor = getFactor(tileCoord1);
    if (factor > FZERO)
    {
        gl_FragColor = texture2D(tileTexture1, texCoord1) * factor * opacity;
        return;
    }

    if (numTextures == 2)
    {
        gl_FragColor = TRANSPARENT;
        return;
    }

    factor = getFactor(tileCoord2);
    if (factor > FZERO)
    {
        gl_FragColor = texture2D(tileTexture2, texCoord2) * factor * opacity;
        return;
    }

    gl_FragColor = TRANSPARENT;

    if (numTextures == 3)
    {
        gl_FragColor = TRANSPARENT;
        return;
    }

    factor = getFactor(tileCoord3);
    if (factor > FZERO)
    {
        gl_FragColor = texture2D(tileTexture3, texCoord3) * factor * opacity;
        return;
    }

    gl_FragColor = TRANSPARENT;
}
);
