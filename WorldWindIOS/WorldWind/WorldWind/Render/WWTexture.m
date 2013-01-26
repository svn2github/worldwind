/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "UIKit/UIKit.h"
#import "WorldWind/Render/WWTexture.h"
#import "WorldWind/WWLog.h"
#import "WorldWind/Formats/PVRTC/WWPVRTCImage.h"

@implementation WWTexture

- (WWTexture*) initWithImagePath:(NSString*)filePath
{
    if (filePath == nil || [filePath length] == 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Image path is nil or zero length")
    }

    self = [super init];

    _filePath = filePath;

    return self;
}

- (void) dispose
{
    if (_textureID != 0)
    {
        glDeleteTextures(1, &_textureID);
        _textureID = 0;
    }
}

- (long) sizeInBytes
{
    return _textureSize;
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

    if (![[NSFileManager defaultManager] fileExistsAtPath:_filePath])
    {
        return NO;
    }

    if ([[_filePath pathExtension] isEqualToString:@"pvr"])
    {
        [self loadCompressedTexture];
    }
    else
    {
        [self loadTexture];
    }

    if (_textureCreationFailed)
    {
        return NO;
    }

    return _textureID != 0;
}

- (void) loadTexture
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

    _textureSize = _imageWidth * _imageHeight * 4; // assume 4 bytes per pixel
    void* imageData = malloc((size_t) _textureSize); // allocate space for the image

    CGContextRef context;
    @try
    {
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        context = CGBitmapContextCreate(imageData, (size_t) _imageWidth, (size_t) _imageHeight,
                8, (size_t) (4 * _imageWidth), colorSpace, kCGImageAlphaPremultipliedLast);
        CGRect rect = CGRectMake(0, 0, _imageWidth, _imageHeight);
        CGContextClearRect(context, rect);
        CGContextDrawImage(context, rect, cgImage);

        glGenTextures(1, &_textureID);
        glBindTexture(GL_TEXTURE_2D, _textureID);

        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, _imageWidth, _imageHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData);

        glGenerateMipmap(GL_TEXTURE_2D);
    }
    @catch (NSException* exception)
    {
        _textureCreationFailed = YES;

        NSString* msg = [NSString stringWithFormat:@"loading texture data for file %@", _filePath];
        WWLogE(msg, exception);
    }
    @finally
    {
        free(imageData);

        // The image has been drawn into the allocated memory, so release the no-longer-needed context.
        CGContextRelease(context);
    }
}

- (void) loadCompressedTexture
{
    WWPVRTCImage* image = [[WWPVRTCImage alloc] initWithContentsOfFile:_filePath];

    _imageWidth = [image imageWidth];
    _imageHeight = [image imageHeight];
    _textureSize = [image imageSize];

    int tid = [image loadGL];
    if (tid >= 0)
        _textureID = (GLuint) tid;
    else
        _textureCreationFailed = YES;
}

@end