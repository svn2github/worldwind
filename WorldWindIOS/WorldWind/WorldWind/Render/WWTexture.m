/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <UIKit/UIKit.h>
#import "WorldWind/Render/WWTexture.h"
#import "WorldWind/Formats/PVRTC/WWPVRTCImage.h"
#import "WorldWind/Render/WWDrawContext.h"
#import "WorldWind/Util/WWFrameStatistics.h"
#import "WorldWind/Util/WWGpuResourceCache.h"
#import "WorldWind/Util/WWMath.h"
#import "WorldWind/Util/WWUtil.h"
#import "WorldWind/WorldWindConstants.h"
#import "WorldWind/WWLog.h"

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
            _textureCache = nil; // don't need the cache anymore
            _object = nil; // don't need the object anymore
        }
    }
}

- (BOOL) bind:(WWDrawContext* __unsafe_unretained)dc
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
    [[dc frameStatistics] incrementTextureLoadCount:1];

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

        GLuint format = GL_UNSIGNED_BYTE;

        if ([[_filePath pathExtension] isEqualToString:@"5551"])
        {
            format = GL_UNSIGNED_SHORT_5_5_5_1;
        }

        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, _imageWidth, _imageHeight, 0, GL_RGBA, format, [self->imageData bytes]);

        glGenerateMipmap(GL_TEXTURE_2D);
    }

    self->imageData = nil; // image bytes are no longer needed
}

- (void) loadGLCompressed
{
    glGenTextures(1, &_textureID);
    glBindTexture(GL_TEXTURE_2D, _textureID);

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

    int levelWidth = _imageWidth;
    int levelHeight = _imageHeight;
    void* levelBits = ((void*) [self->imageData bytes]) + 13 * sizeof(int);

    for (int levelNum = 0; levelNum < _numLevels; levelNum++)
    {
        int levelSize = (int) fmax(levelWidth * levelHeight / 2, 32); // 4 bits per pixel

        glCompressedTexImage2D(GL_TEXTURE_2D, levelNum, GL_COMPRESSED_RGBA_PVRTC_4BPPV1_IMG,
                levelWidth, levelHeight, 0, levelSize, levelBits);

        levelWidth = levelWidth >> 1;
        levelHeight = levelHeight >> 1;
        levelBits += levelSize;
    }

    self->imageData = nil; // image bytes are no longer needed
}

- (void) loadTexture
{
    if ([[_filePath pathExtension] isEqualToString:@"pvr"])
    {
        [self loadCompressedTexture];
    }
    else if ([[_filePath pathExtension] isEqualToString:@"5551"] | [[_filePath pathExtension] isEqualToString:@"8888"])
    {
        [self loadRawTexture];
    }
    else
    {
        [self loadEncodedTexture];
    }

    NSDictionary* fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:_filePath error:nil];
    _fileModificationDate = [fileAttributes objectForKey:NSFileModificationDate];
}

- (void) loadCompressedTexture
{
    WWPVRTCImage* image = [[WWPVRTCImage alloc] initWithContentsOfFile:_filePath];

    self->imageData = [image imageBits];

    _textureSize = [self->imageData length];
    _imageWidth = [image imageWidth];
    _imageHeight = [image imageHeight];
    _originalImageWidth = _imageWidth;
    _originalImageHeight = _imageHeight;
    _numLevels = [image numLevels];
}

- (void) loadRawTexture
{
    self->imageData = [[NSData alloc] initWithContentsOfFile:_filePath];

    int bytesPerPixel = [_filePath hasSuffix:@"5551"] ? 2 : 4;

    _textureSize = [self->imageData length];
    _imageWidth = (int) sqrt([self->imageData length] / bytesPerPixel);
    _imageHeight = _imageWidth;
    _originalImageWidth = _imageWidth;
    _originalImageHeight = _imageHeight;
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

    _originalImageWidth = CGImageGetWidth(cgImage);
    _originalImageHeight = CGImageGetHeight(cgImage);
    if (_originalImageWidth == 0 || _originalImageHeight == 0)
    {
        _textureCreationFailed = YES;
        WWLog(@"Image size is zero for file %@", _filePath);
        return;
    }

    _imageWidth = [WWMath powerOfTwoCeiling:_originalImageWidth];
    _imageHeight = [WWMath powerOfTwoCeiling:_originalImageHeight];
    _textureSize = _imageWidth * _imageHeight * 4; // assume 4 bytes per pixel
    void* data = malloc((size_t) _textureSize); // allocate space for the image

    CGContextRef context;
    @try
    {
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        context = CGBitmapContextCreate(data, (size_t) _imageWidth, (size_t) _imageHeight,
                8, (size_t) (4 * _imageWidth), colorSpace, kCGImageAlphaPremultipliedLast);
        CGRect clearRect = CGRectMake(0, 0, _imageWidth, _imageHeight);
        CGRect drawRect = CGRectMake(0, _imageHeight - _originalImageHeight, _originalImageWidth, _originalImageHeight);
        CGContextClearRect(context, clearRect);
        CGContextDrawImage(context, drawRect, cgImage);

        imageData = [[NSData alloc] initWithBytesNoCopy:data length:(NSUInteger) _textureSize];
    }
    @catch (NSException* exception)
    {
        _textureCreationFailed = YES;
        imageData = nil;

        NSString* msg = [NSString stringWithFormat:@"loading texture data for file %@", _filePath];
        WWLogE(msg, exception);
    }
    @finally
    {
        // The image has been drawn into the allocated memory, so release the no-longer-needed context.
        CGContextRelease(context);
    }
}

+ (void) convertTextureTo8888:(NSString*)imagePath
{
    if (imagePath == nil || [imagePath length] == 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Image path is nil or zero length")
    }

    NSString* outputPath = [WWUtil replaceSuffixInPath:imagePath newSuffix:@"8888"];

    UIImage* uiImage = [UIImage imageWithContentsOfFile:imagePath];
    if (uiImage == nil)
    {
        NSString* msg = [[NSString alloc] initWithFormat:@"Unable to load image file %@", imagePath];
        WWLOG_AND_THROW(NSInvalidArgumentException, msg)
    }

    CGImageRef cgImage = [uiImage CGImage];

    int imageWidth = CGImageGetWidth(cgImage);
    int imageHeight = CGImageGetHeight(cgImage);
    if (imageWidth == 0 || imageHeight == 0)
    {
        NSString* msg = [[NSString alloc] initWithFormat:@"Image size is zero for file %@", imagePath];
        WWLOG_AND_THROW(NSInvalidArgumentException, msg)
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

        NSData* outData = [[NSData alloc] initWithBytesNoCopy:imageData length:(NSUInteger) textureSize];
        [outData writeToFile:outputPath atomically:YES];
    }
    @finally
    {
        // The image has been drawn into the allocated memory, so release the no-longer-needed context.
        CGContextRelease(context);
    }
}

+ (void) convertTextureTo5551:(NSString*)imagePath
{
    if (imagePath == nil || [imagePath length] == 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Image path is nil or zero length")
    }

    NSString* outputPath = [WWUtil replaceSuffixInPath:imagePath newSuffix:@"5551"];

    UIImage* uiImage = [UIImage imageWithContentsOfFile:imagePath];
    if (uiImage == nil)
    {
        NSString* msg = [[NSString alloc] initWithFormat:@"Unable to load image file %@", imagePath];
        WWLOG_AND_THROW(NSInvalidArgumentException, msg)
    }

    CGImageRef cgImage = [uiImage CGImage];

    int imageWidth = CGImageGetWidth(cgImage);
    int imageHeight = CGImageGetHeight(cgImage);
    if (imageWidth == 0 || imageHeight == 0)
    {
        NSString* msg = [[NSString alloc] initWithFormat:@"Image size is zero for file %@", imagePath];
        WWLOG_AND_THROW(NSInvalidArgumentException, msg)
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

        NSData* outData = [self convertPixelsTo5551:imageData numPixels:(imageWidth * imageHeight)];
        [outData writeToFile:outputPath atomically:YES];
    }
    @finally
    {
        // The image has been drawn into the allocated memory, so release the no-longer-needed context.
        CGContextRelease(context);

        free(imageData);
    }
}

+ (NSData*) convertPixelsTo5551:(void*)image numPixels:(int)numPixels
{
    uint16_t* outImage = malloc((size_t) numPixels * sizeof(uint16_t));
    uint32_t* pixels = (uint32_t*) image;

    for (int i = 0; i < numPixels; i++)
    {
        uint8_t* inPixel = (uint8_t*) &pixels[i];
        int r = (int) (inPixel[0] * 31.0 / 255.0 + 0.5);
        int g = (int) (inPixel[1] * 31.0 / 255.0 + 0.5);
        int b = (int) (inPixel[2] * 31.0 / 255.0 + 0.5);

        uint16_t outPixel = 0;
        outPixel |= r;
        outPixel <<= 5;
        outPixel |= g;
        outPixel <<= 5;
        outPixel |= b;
        outPixel <<= 1;
        if (inPixel[3] == 255) // set output alpha to 1 only if input alpha is max alpha
            outPixel |= 1;

        outImage[i] = outPixel;
    }

    return [[NSData alloc] initWithBytesNoCopy:outImage length:(NSUInteger) (numPixels * sizeof(uint16_t))];
}

@end