/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "UIKit/UIKit.h"
#import "WorldWind/Render/WWTexture.h"
#import "WorldWind/WWLog.h"
#import "WorldWind/Formats/PVRTC/WWPVRTCImage.h"
#import "WorldWind/WorldWindConstants.h"
#import "WorldWind/Util/WWGpuResourceCache.h"
#import "WorldWind/Util/WWUtil.h"

@implementation WWTexture

- (WWTexture*) initWithImagePath:(NSString*)filePath cache:(WWGpuResourceCache*)cache object:(id)object
{
    if (filePath == nil || [filePath length] == 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Image path is nil or zero length")
    }

    if (cache == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Resource cache is nil")
    }

    self = [super init];

    _filePath = filePath;
    _textureCache = cache;
    _object = object;

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

- (void) main
{
    // Read the texture's image from disk and add it to the texture cache. This is done in a background thread.

    @autoreleasepool
    {
        NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
        [dict setObject:_filePath forKey:WW_FILE_PATH];
        NSNotification* notification = [NSNotification notificationWithName:WW_REQUEST_STATUS object:_object userInfo:dict];

        @try
        {
            if (![self isCancelled])
            {
                [self loadTexture];

                if (!_textureCreationFailed)
                {
                    [_textureCache putTexture:self forKey:_filePath];
                    _textureCache = nil; // don't need the cache anymore
                    [dict setObject:WW_SUCCEEDED forKey:WW_REQUEST_STATUS];
                }
                else
                {
                    [dict setObject:WW_FAILED forKey:WW_REQUEST_STATUS];
                }
            }
            else
            {
                [dict setObject:WW_CANCELED forKey:WW_REQUEST_STATUS];
            }
        }
        @catch (NSException* exception)
        {
            [dict setObject:WW_FAILED forKey:WW_REQUEST_STATUS];

            NSString* msg = [NSString stringWithFormat:@"Opening image file %@", [self filePath]];
            WWLogE(msg, exception);
        }
        @finally
        {
            [[NSNotificationCenter defaultCenter] postNotification:notification];
        }
    }
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

    [self loadGL];

    return _textureID != 0;
}

- (void) loadGL
{
    if ([[_filePath pathExtension] isEqualToString:@"pvr"])
    {
        [self loadGLCompressed];
    }
    else
    {
        glGenTextures(1, &_textureID);
        glBindTexture(GL_TEXTURE_2D, _textureID);

        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, _imageWidth, _imageHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE,
                [self->imageData bytes]);

        glGenerateMipmap(GL_TEXTURE_2D);
    }

    self->imageData = nil; // image bytes are no longer needed
}

- (void) loadGLCompressed // TODO
{
}

- (void) loadTexture
{
    if ([[_filePath pathExtension] isEqualToString:@"pvr"])
    {
        [self loadCompressedTexture];
    }
    else if ([[_filePath pathExtension] isEqualToString:@"raw"])
    {
        [self loadRawTexture];
    }
    else
    {
        [self loadEncodedTexture];
    }
}

- (void) loadCompressedTexture
{
    WWPVRTCImage* image = [[WWPVRTCImage alloc] initWithContentsOfFile:_filePath];

    _imageWidth = [image imageWidth];
    _imageHeight = [image imageHeight];
    _textureSize = [image imageSize];

    // TODO: Assign compressed bits of image to self->imageData.
}

- (void) loadRawTexture
{
    self->imageData = [[NSData alloc] initWithContentsOfFile:_filePath];

    _textureSize = [self->imageData length];
    _imageWidth = (int) sqrt([self->imageData length] / 4);
    _imageHeight = _imageWidth;
}

- (void) loadEncodedTexture
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
    void* data = malloc((size_t) _textureSize); // allocate space for the image

    CGContextRef context;
    @try
    {
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        context = CGBitmapContextCreate(data, (size_t) _imageWidth, (size_t) _imageHeight,
                8, (size_t) (4 * _imageWidth), colorSpace, kCGImageAlphaPremultipliedLast);
        CGRect rect = CGRectMake(0, 0, _imageWidth, _imageHeight);
        CGContextClearRect(context, rect);
        CGContextDrawImage(context, rect, cgImage);

        self->imageData = [[NSData alloc] initWithBytesNoCopy:data length:(NSUInteger) _textureSize];
    }
    @catch (NSException* exception)
    {
        _textureCreationFailed = YES;
        self->imageData = nil;

        NSString* msg = [NSString stringWithFormat:@"loading texture data for file %@", _filePath];
        WWLogE(msg, exception);
    }
    @finally
    {
        // The image has been drawn into the allocated memory, so release the no-longer-needed context.
        CGContextRelease(context);
    }
}

+ (void) convertTextureToRaw:(NSString*)imagePath
{
    NSString* outputPath = [WWUtil replaceSuffixInPath:imagePath newSuffix:@"raw"];

    UIImage* uiImage = [UIImage imageWithContentsOfFile:imagePath];
    if (uiImage == nil)
    {
        WWLog(@"Unable to load image file %@", imagePath);
        return;
    }

    CGImageRef cgImage = [uiImage CGImage];

    int imageWidth = CGImageGetWidth(cgImage);
    int imageHeight = CGImageGetHeight(cgImage);
    if (imageWidth == 0 || imageHeight == 0)
    {
        WWLog(@"Image size is zero for file %@", imagePath);
        return;
    }

    int textureSize = imageWidth * imageHeight * 4; // assume 4 bytes per pixel
    void* imageData = malloc((size_t) textureSize); // allocate space for the image

    CGContextRef context;
    @try
    {
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        context = CGBitmapContextCreate(imageData, (size_t) imageWidth, (size_t) imageHeight,
                8, (size_t) (4 * imageWidth), colorSpace, kCGImageAlphaPremultipliedLast);
        CGRect rect = CGRectMake(0, 0, imageWidth, imageHeight);
        CGContextClearRect(context, rect);
        CGContextDrawImage(context, rect, cgImage);

        NSData* outData = [NSData dataWithBytesNoCopy:imageData length:(NSUInteger) textureSize];
        [outData writeToFile:outputPath atomically:YES];
    }
    @catch (NSException* exception)
    {
        NSString* msg = [NSString stringWithFormat:@"loading texture data for file %@", imagePath];
        WWLogE(msg, exception);
    }
    @finally
    {
        // The image has been drawn into the allocated memory, so release the no-longer-needed context.
        CGContextRelease(context);
    }
}

@end