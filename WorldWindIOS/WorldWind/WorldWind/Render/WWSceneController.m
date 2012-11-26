/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration.
 All Rights Reserved.
 
 * @version $Id$
 */

#import "WorldWind/Render/WWSceneController.h"

// STRINGIFY is used in the shader files.
#define STRINGIFY(A) #A
#import "WorldWind/Shaders/Simple.vert"
#import "WorldWind/Shaders/Simple.frag"

@implementation WWSceneController
{
}

- (void) render:(CGRect) bounds
{
    @try
    {
        glViewport(0, 0, CGRectGetWidth(bounds), CGRectGetHeight(bounds));
        
        [self testRender];
    }
    @catch (NSException *exception)
    {
        WWLogE(@"Rendering Scene", exception);
    }
}

typedef struct Vertex
{
    float Position[2];
    float Color[4];
} Vertex;

struct Vertex Vertices[] =
{
    {{-0.5, -0.866}, {1, 1, 0.5f, 1}},
    {{0.5, -0.866}, {1, 1, 0.5f, 1}},
    {{0, 1}, {1, 1, 0.5f, 1}},
    {{-0.5, -0.866}, {0.5f, 0.5f, 0.5f}},
    {{0.5, -0.866}, {0.5f, 0.5f, 0.5f}},
    {{0, -0.4f}, {0.5f, 0.5f, 0.5f}},
};

- (void) testRender
{
    if (self->program == 0)
        self->program = [self buildProgram:SimpleVertexShader fragmentSource:SimpleFragmentShader];
    glUseProgram(self->program);
    
    [self applyOrtho:2 maxY:3];
    
    glClearColor(0.5f, 0.5, 0.5f, 1);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    [self applyRotation:0];
    
    GLuint positionSlot = glGetAttribLocation(self->program, "Position");
    GLuint colorSlot = glGetAttribLocation(self->program, "SourceColor");
    
    glEnableVertexAttribArray(positionSlot);
    glEnableVertexAttribArray(colorSlot);
    
    GLsizei stride = sizeof(Vertex);
    GLvoid *pCoords = &Vertices[0].Position[0];
    GLvoid *pColors = &Vertices[0].Color[0];
    
    glVertexAttribPointer(positionSlot, 2, GL_FLOAT, GL_FALSE, stride, pCoords);
    glVertexAttribPointer(colorSlot, 4, GL_FLOAT, GL_FALSE, stride, pColors);
    
    GLsizei vertexCount = sizeof(Vertices) / sizeof(Vertices[0]);
    glDrawArrays(GL_TRIANGLES, 0, vertexCount);
    
    glDisableVertexAttribArray(positionSlot);
    glDisableVertexAttribArray(colorSlot);
}

- (void) handleMemoryWarning
{
}

- (void) dispose
{
    if (self->program != 0)
    {
        glDeleteProgram(self->program);
        self->program = 0;
    }
}

- (void) applyRotation:(float) degrees
{
    float radians = degrees * 3.14159f / 180.0f;
    float s = sinf(radians);
    float c = cosf(radians);
    float zRotation[16] =
    {
        c, s, 0, 0,
        -s, c, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1
    };
    
    GLint modelviewUniform = glGetUniformLocation(self->program, "Modelview");
    glUniformMatrix4fv(modelviewUniform, 1, 0, &zRotation[0]);
}

- (void) applyOrtho:(float) maxX maxY:(float) maxY
{
    float a = 1.0f / maxX;
    float b = 1.0f / maxY;
    float ortho[16] =
    {
        a, 0, 0, 0,
        0, b, 0, 0,
        0, 0, -1, 0,
        0, 0, 0, 1
    };
    
    GLint projectionUniform = glGetUniformLocation(self->program, "Projection");
    glUniformMatrix4fv(projectionUniform, 1, 0, &ortho[0]);
}

- (GLuint) buildShader:(const char *) source ofType:(GLenum) shaderType
{
    GLuint shaderHandle = glCreateShader(shaderType);
    glShaderSource(shaderHandle, 1, &source, 0);
    glCompileShader(shaderHandle);
    
    GLint compileSuccess;
    glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &compileSuccess);
    if (compileSuccess == GL_FALSE)
    {
        GLchar messages[256];
        glGetShaderInfoLog(shaderHandle, sizeof(messages), 0, &messages[0]);
        WWLog(@"%s", messages);
    }
    
    return shaderHandle;
}

- (GLuint) buildProgram:(const char *) vertexShaderSource fragmentSource:(const char *) fragmentShaderSource
{
    GLuint vertexShader = [self buildShader:vertexShaderSource ofType:GL_VERTEX_SHADER];
    GLuint fragmentShader = [self buildShader:fragmentShaderSource ofType:GL_FRAGMENT_SHADER];
    
    GLuint programHandle = glCreateProgram();
    glAttachShader(programHandle, vertexShader);
    glAttachShader(programHandle, fragmentShader);
    glLinkProgram(programHandle);
    
    GLint success;
    glGetProgramiv(programHandle, GL_LINK_STATUS, &success);
    if (success == GL_FALSE)
    {
        GLchar messages[256];
        glGetProgramInfoLog(programHandle, sizeof(messages), 0, &messages[0]);
        NSLog(@"%s", messages);
    }
    
    return programHandle;
}

@end