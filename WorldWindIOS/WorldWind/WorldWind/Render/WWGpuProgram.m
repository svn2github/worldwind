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

- (int) attributeLocation:(NSString*)attributeName
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

- (int) uniformLocation:(NSString*)uniformName
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

+ (void) loadUniformMatrix:(WWMatrix* __unsafe_unretained)matrix location:(GLuint)location
{
    if (matrix == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Matrix is nil")
    }

    static GLfloat components[16];
    [matrix columnMajorComponents:components];

    glUniformMatrix4fv(location, 1, GL_FALSE, components);
}

+ (void) loadUniformColor:(WWColor* __unsafe_unretained)color location:(GLuint)location
{
    if (color == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Color is nil")
    }

    static GLfloat components[4];
    [color premultipliedComponents:components];

    glUniform4fv(location, 1, components);
}

+ (void) loadUniformPickColor:(unsigned int)color location:(GLuint)location
{
    // Convert the color from a packed int.
    GLfloat r = ((color >> 24) & 0xff) / 255.0;
    GLfloat g = ((color >> 16) & 0xff) / 255.0;
    GLfloat b = ((color >> 8) & 0xff) / 255.0;
    GLfloat a = (color & 0xff) / 255.0;

    glUniform4f(location, r, g, b, a);
}

+ (void) loadUniformFloat:(float)value location:(GLuint)location
{
    glUniform1f(location, value);
}

@end