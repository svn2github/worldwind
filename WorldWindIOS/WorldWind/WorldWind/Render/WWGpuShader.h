/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>
#import <OpenGLES/ES2/gl.h>
#import "WorldWind/Util/WWCacheable.h"
#import "WorldWind/Util/WWDisposable.h"

@interface WWGpuShader : NSObject <WWCacheable, WWDisposable>
{
@protected
    GLuint type;
    long estimatedMemorySize;
}

@property(readonly, nonatomic) GLuint shaderId;

- (WWGpuShader*) initWithType:(GLuint)shaderType source:(const char*)source;
- (BOOL) compile:(GLuint)shaderType source:(const char*)source;
- (NSString*) nameFromShaderType:(GLuint)shaderType;

@end