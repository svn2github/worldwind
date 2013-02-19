const char* SimpleFragmentShader = STRINGIFY(

uniform lowp vec4 color;

void main(void)
{
    gl_FragColor = color;
}
);
