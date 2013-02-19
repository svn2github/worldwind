const char* SimpleVertexShader = STRINGIFY(

attribute vec4 vertexPoint;
uniform mat4 mvpMatrix;

void main(void)
{
    gl_Position = mvpMatrix * vertexPoint;
}
);
