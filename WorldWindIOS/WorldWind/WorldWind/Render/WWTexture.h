/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>
#import <OpenGLES/ES2/gl.h>
#import "WorldWind/Util/WWDisposable.h"
#import "WorldWind/Util/WWCacheable.h"

@class WWDrawContext;

@interface WWTexture : NSObject <WWDisposable, WWCacheable>
{
    void* imageData;
}

@property (nonatomic) NSString* filePath;
@property (readonly, nonatomic) int imageWidth;
@property (readonly, nonatomic) int imageHeight;
@property (readonly, nonatomic) GLuint textureID;
@property (readonly, nonatomic) long textureSize;
@property (readonly, nonatomic) BOOL textureCreationFailed;

- (WWTexture*) initWithImagePath:(NSString*)filePath;

- (BOOL) bind:(WWDrawContext*)dc;

- (void) loadTextureDataFromFile;

- (void) establishTexture;

@end