/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Render/WWGpuProgram.h"
#import "WorldWind/Render/WWGpuShader.h"
#import "WorldWind/Geometry/WWMatrix.h"
#import "WorldWind/WWLog.h"
#import "WorldWind/Util/WWColor.h"


@implementation WWGpuProgram

- (WWGpuProgram*) initWithShaderSource:(const char*)vertexSource fragmentShader:(const char*)fragmentSource
{
    self = [super init];

    if (vertexSource == nil || strlen(vertexSource) == 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Vertex shader source is empty")
    }

    if (fragmentSource == nil || strlen(fragmentSource) == 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Fragment shader source is empty")
    }

    WWGpuShader* vShader = nil;
    WWGpuShader* fShader = nil;

    @try
    {
        vShader = [[WWGpuShader alloc] initWithType:GL_VERTEX_SHADER source:vertexSource];
        fShader = [[WWGpuShader alloc] initWithType:GL_FRAGMENT_SHADER source:fragmentSource];
    }
    @catch (NSException* exception)
    {
        if (vShader != nil)
            [vShader dispose];
        if (fShader != nil)
            [fShader dispose];

        @throw exception;
    }

    GLuint program = glCreateProgram();
    if (program <= 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Unable to create shader program.")
    }

    glAttachShader(program, vShader.shaderId);
    glAttachShader(program, fShader.shaderId);

    if (![self link:program])
    {
        // Get the info log before deleting the program.
        GLsizei logSize = 0;
        glGetProgramiv(program, GL_INFO_LOG_LENGTH, &logSize);
        GLchar infoLog[logSize];
        glGetProgramInfoLog(program, logSize, &logSize, infoLog);

        glDetachShader(program, vShader.shaderId);
        glDetachShader(program, fShader.shaderId);
        glDeleteProgram(program);
        [vShader dispose];
        [fShader dispose];

        NSString* msg = [NSString stringWithFormat:@"Unable to link program: %s", infoLog];
        WWLOG_AND_THROW(NSInvalidArgumentException, msg)
    }

    self->attributeLocations = [[NSMutableDictionary alloc] init];
    self->uniformLocations = [[NSMutableDictionary alloc] init];

    _programId = program;
    self->vertexShader = vShader;
    self->fragmentShader = fShader;

    return self;
}

- (long) sizeInBytes
{
    long size = 0;

    size += self->vertexShader != nil ? [self->vertexShader sizeInBytes] : 0;
    size += self->fragmentShader != nil ? [self->fragmentShader sizeInBytes] : 0;

    return size;
}

- (void) dispose
{
    if (_programId != 0)
    {
        if (self->vertexShader != nil)
            glDetachShader(_programId, self->vertexShader.shaderId);
        if (self->fragmentShader != nil)
            glDetachShader(_programId, self->fragmentShader.shaderId);

        glDeleteProgram(_programId);
        _programId = 0;
    }

    if (self->vertexShader != nil)
    {
        [self->vertexShader dispose];
        self->vertexShader = nil;
    }

    if (self->fragmentShader != nil)
    {
        [self->fragmentShader dispose];
        self->fragmentShader = nil;
    }

    [self->attributeLocations removeAllObjects];
    [self->uniformLocations removeAllObjects];
}

- (BOOL) link:(GLuint)program
{
    GLint linkStatus[] = {0};

    glLinkProgram(program);
    glGetProgramiv(program, GL_LINK_STATUS, linkStatus);

    return linkStatus[0] == GL_TRUE;
}

- (void) bind
{
    glUseProgram(_programId);
}

- (int) getAttributeLocation:(NSString*)attributeName
{
    if (attributeName == nil || attributeName.length == 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Attribute name is empty")
    }

    NSNumber* location = [self->attributeLocations objectForKey:attributeName];
    if (location == nil)
    {
        // glGetAttributeLocation returns -1 if the name does not correspond to an active attribute, or if the name
        // starts with "gl_". In either case, we store the value -1 in our map since the return value does not change
        // until the program is linked again.
        int actualLocation = glGetAttribLocation(_programId, attributeName.UTF8String);
        location = [NSNumber numberWithInt:actualLocation];
        [self->attributeLocations setValue:location forKey:attributeName];
    }

    return location.intValue;
}

- (int) getUniformLocation:(NSString*)uniformName
{
    if (uniformName == nil || uniformName.length == 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Uniform name is empty")
    }

    NSNumber* location = [self->uniformLocations objectForKey:uniformName];
    if (location == nil)
    {
        // glGetUniformLocation returns -1 if the name does not correspond to an active uniform, or if the name
        // starts with "gl_". In either case, we store the value -1 in our map since the return value does not change
        // until the program is linked again.
        int actualLocation = glGetUniformLocation(_programId, uniformName.UTF8String);
        location = [NSNumber numberWithInt:actualLocation];
        [self->uniformLocations setValue:location forKey:uniformName];
    }

    return location.intValue;
}

- (void) loadUniformMatrix:(NSString*)uniformName matrix:(WWMatrix*)matrix
{
    if (uniformName == nil || uniformName.length == 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Uniform matrix name is empty")
    }

    int location = [self getUniformLocation:uniformName];
    if (location < 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Uniform name is invalid")
    }

    if (matrix == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Uniform matrix is nil")
    }

    float m[16];

    // Column 1
    m[0] = (float) matrix->m[0];
    m[1] = (float) matrix->m[4];
    m[2] = (float) matrix->m[8];
    m[3] = (float) matrix->m[12];

    // Column 2
    m[4] = (float) matrix->m[1];
    m[5] = (float) matrix->m[5];
    m[6] = (float) matrix->m[9];
    m[7] = (float) matrix->m[13];

    // Column 3
    m[8] = (float) matrix->m[2];
    m[9] = (float) matrix->m[6];
    m[10] = (float) matrix->m[10];
    m[11] = (float) matrix->m[14];

    // Column 4
    m[12] = (float) matrix->m[3];
    m[13] = (float) matrix->m[7];
    m[14] = (float) matrix->m[11];
    m[15] = (float) matrix->m[15];

    glUniformMatrix4fv(location, 1, GL_FALSE, m);
}

- (void) loadUniformSampler:(NSString*)samplerName value:(int)value
{
    if (samplerName == nil || samplerName.length == 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Uniform sampler name is empty")
    }

    int location = [self getUniformLocation:samplerName];
    if (location < 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Uniform sampler name is invalid")
    }

    glUniform1i(location, value);
}

- (void) loadUniformColor:(NSString*)colorName color:(WWColor*)color
{
    if (colorName == nil || colorName.length == 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Color name is empty")
    }

    int location = [self getUniformLocation:colorName];
    if (location < 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Color name is invalid")
    }

    if (color == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Color is nil")
    }

    glUniform4f(location, [color r], [color g], [color b], [color a]);
}

- (void) loadUniformFloat:(NSString*)uniformName value:(float)value
{
    if (uniformName == nil || uniformName.length == 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Uniform name is empty")
    }

    int location = [self getUniformLocation:uniformName];
    if (location < 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Uniform name is invalid")
    }

    glUniform1f(location, value);
}

@end