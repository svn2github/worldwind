const char* SimpleVertexShader = STRINGIFY(

attribute vec4 Position;
varying vec4 DestinationColor;
uniform mat4 Modelview;

void main(void)
{
    DestinationColor = vec4(1.0, 0.0, 0.0, 1.0);
    gl_Position = Modelview * Position;
}
);
