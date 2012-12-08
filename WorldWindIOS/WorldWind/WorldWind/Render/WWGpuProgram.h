/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>
#import <OpenGLES/ES2/gl.h>
#import "WorldWind/Util/WWCacheable.h"
#import "WorldWind/Util/WWDisposable.h"

@class WWGpuShader;
@class WWMatrix;

@interface WWGpuProgram : NSObject <WWCacheable, WWDisposable>
{
@protected
    WWGpuShader* vertexShader;
    WWGpuShader* fragmentShader;
    NSMutableDictionary* attributeLocations;
    NSMutableDictionary* uniformLocations;
}

@property(readonly, nonatomic) GLuint programId;

- (WWGpuProgram*) initWithVertexShader:(const char*)vertexSource fragmentShader:(const char*)fragmentSource;

- (BOOL) link:(GLuint)program;

- (void) bind;

- (int) getAttributeLocation:(NSString*)attributeName;

- (int) getUniformLocation:(NSString*)uniformName;

- (void) loadUniformMatrix:(NSString*)uniformName matrix:(WWMatrix*)matrix;

- (void) loadUniformSampler:(NSString*)samplerName value:(int)value;

@end