/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Render/WWSceneController.h"
#import "WorldWind/Terrain/WWGLobe.h"
#import "WorldWind/Layer/WWLayerList.h"
#import "WorldWInd/Layer/WWLayer.h"
#import "WorldWind/Render/WWDrawContext.h"
#import "WorldWind/Terrain/WWTerrainTileList.h"
#import "WorldWind/WWLog.h"

// STRINGIFY is used in the shader files.
#define STRINGIFY(A) #A
#import "WorldWind/Shaders/Simple.vert"
#import "WorldWind/Shaders/Simple.frag"

@implementation WWSceneController

- (WWSceneController*)init
{
    self = [super init];

    _globe = [[WWGlobe alloc] init];
    _layers = [[WWLayerList alloc] init];
    
    self->drawContext = [[WWDrawContext alloc] init];
    
    return self;
}

- (void) dispose
{
    if (self->program != 0)
    {
        glDeleteProgram(self->program);
        self->program = 0;
    }
}

- (void) handleMemoryWarning
{
}

- (void) render:(CGRect) bounds
{
    @try
    {
        [self resetDrawContext];
        [self drawFrame:bounds];
    }
    @catch (NSException *exception)
    {
        WWLogE(@"Rendering Scene", exception);
    }
}

- (void) resetDrawContext
{
    [self->drawContext reset];
    [self->drawContext setGlobe:_globe];
    [self->drawContext setLayers:_layers];
}

- (void) drawFrame:(CGRect) bounds
{
    @try {
        [self beginFrame:bounds];
        [self applyView];
        [self createTerrain];
        [self clearFrame];
        [self draw];
    }
    @finally {
        [self endFrame];
    }
}

- (void) beginFrame:(CGRect) bounds
{
    glViewport(bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height);
    
    glEnable(GL_BLEND);
    glEnable(GL_CULL_FACE);
    glEnable(GL_DEPTH_TEST);
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    glDepthFunc(GL_LEQUAL);
}

- (void) endFrame
{
    glDisable(GL_BLEND);
    glDisable(GL_CULL_FACE);
    glDisable(GL_DEPTH_TEST);
    glBlendFunc(GL_ONE, GL_ZERO);
    glDepthFunc(GL_LESS);
    glClearColor(0, 0, 0, 0);
}

- (void) clearFrame
{
    glClearColor(0, 0, 0, 1);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}

- (void) applyView
{
}

- (void) createTerrain
{
    WWTerrainTileList* surfaceGeometry = [_globe tessellate:self->drawContext];
    
    // If there's no surface geometry, just log a warning and keep going. Some layers may have meaning without it.
    if (surfaceGeometry == nil || [surfaceGeometry count] == 0)
    {
        WWLog(@"No surface geometry");
    }
    
    [self->drawContext setSurfaceGeometry:surfaceGeometry];
    [self->drawContext setVisibleSector:surfaceGeometry.sector];
}

- (void) draw
{
    [self drawLayers];
    [self drawOrderedRenderables];
}

- (void) drawLayers
{
    int nLayers = _layers.count;
    for (int i = 0; i < nLayers; i++)
    {
        WWLayer* layer = [_layers layerAtIndex:i];
        if (layer != nil)
        {
            [layer render];
        }
    }
}

- (void) drawOrderedRenderables
{
    [self testRender];
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