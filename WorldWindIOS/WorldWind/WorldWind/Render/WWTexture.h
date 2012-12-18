/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>
#import <OpenGLES/ES2/gl.h>

@class WWDrawContext;

@interface WWTexture : NSObject
{
    void* imageData;
}

@property (nonatomic) NSString* filePath;
@property (readonly, nonatomic) int imageWidth;
@property (readonly, nonatomic) int imageHeight;
@property (readonly, nonatomic) GLuint textureID;
@property (readonly, nonatomic) BOOL textureCreationFailed;

- (WWTexture*) initWithContentsOfFile:(NSString*)filePath;

- (BOOL) bind:(WWDrawContext*)dc;

- (void) loadTextureDataFromFile;

- (void) establishTexture;

@end