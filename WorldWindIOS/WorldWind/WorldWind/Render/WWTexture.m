/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "UIKit/UIKit.h"
#import "WorldWind/Render/WWTexture.h"
#import "WorldWInd/WWLog.h"

@implementation WWTexture

- (WWTexture*) initWithContentsOfFile:(NSString*)filePath
{
    if (filePath == nil || [filePath length] == 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Image path is nil or zero length")
    }

    self = [super init];

    _filePath = filePath;

    return self;
}

- (BOOL) bind:(WWDrawContext*)dc
{
    if (_textureID != 0)
    {
        glBindTexture(GL_TEXTURE_2D, _textureID);
        return YES;
    }

    if (_textureCreationFailed)
    {
        return NO;
    }

    [self loadTextureDataFromFile];
    [self establishTexture]; // also performs the bind

    return _textureID != 0;
}

- (void) loadTextureDataFromFile
{
    UIImage* uiImage = [UIImage imageWithContentsOfFile:_filePath];
    if (uiImage == nil)
    {
        _textureCreationFailed = YES;
        WWLog(@"Unable to load image file %@", _filePath);
        return;
    }

    CGImageRef cgImage = [uiImage CGImage];

    _imageWidth = CGImageGetWidth(cgImage);
    _imageHeight = CGImageGetHeight(cgImage);
    if (_imageWidth == 0 || _imageHeight == 0)
    {
        _textureCreationFailed = YES;
        WWLog(@"Image size is zero for file %@", _filePath);
        return;
    }

    self->imageData = malloc((size_t) (_imageWidth * _imageHeight * 4)); // allocate space for the image, 4byte per pxl

    CGContextRef context;
    @try
    {
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        context = CGBitmapContextCreate(self->imageData, (size_t) _imageWidth, (size_t) _imageHeight,
                8, (size_t) (4 * _imageWidth), colorSpace, kCGImageAlphaPremultipliedLast);
        CGRect rect = CGRectMake(0, 0, _imageWidth, _imageHeight);
        CGContextClearRect(context, rect);
        CGContextDrawImage(context, rect, cgImage);

    }
    @catch (NSException* exception)
    {
        free(self->imageData); // release the memory allocated for the image
        _textureCreationFailed = YES;

        NSString* msg = [NSString stringWithFormat:@"loading texture data for file %@", _filePath];
        WWLogE(msg, exception);
    }
    @finally
    {
        // The image has been drawn into the allocated memory, so release the no-longer-needed context.
        CGContextRelease(context);
    }
}

- (void) establishTexture
{
    glGenTextures(1, &_textureID);
    glBindTexture(GL_TEXTURE_2D, _textureID);

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, _imageWidth, _imageHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, self->imageData);

    // The image data is no longer needed.
    free(self->imageData);
    self->imageData = nil;

    glGenerateMipmap(GL_TEXTURE_2D);
}

@end