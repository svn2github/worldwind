const char* SimpleVertexShader = STRINGIFY(

attribute vec4 vertexPoint;
varying vec4 DestinationColor;
uniform mat4 mvpMatrix;

void main(void)
{
    DestinationColor = vec4(1.0, 0.0, 0.0, 1.0);
    gl_Position = mvpMatrix * vertexPoint;
}
);
