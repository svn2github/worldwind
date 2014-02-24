/*
 Copyright (C) 2014 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "ZView.h"

@implementation ZView
{
    UIImage* uiImage;
}

- (void) drawRect:(CGRect)rect
{
    if (uiImage == nil)
    {
        uiImage = [[UIImage alloc] initWithContentsOfFile:_imageFilePath];
    }

    int textureSize = 256;
    int textureDataSize = textureSize * textureSize * 4;
    CGRect textureRect = CGRectMake(0, 0, textureSize, textureSize);

    int subRegionSize = 1024;
    CGRect subRegion = CGRectMake(10000, 3000, subRegionSize, subRegionSize);

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

    NSDate* start = [[NSDate alloc] init];
    for (int i = 0; i < 10; i++)
    {
        CGImageRef subImage = CGImageCreateWithImageInRect([uiImage CGImage], subRegion);

        void* data = malloc((size_t) textureDataSize); // allocate space for the image
        CGContextRef context = CGBitmapContextCreate(data, (size_t) textureSize, (size_t) textureSize,
                8, (size_t) (4 * textureSize), colorSpace, kCGImageAlphaPremultipliedLast);

//        CGContextClearRect(context, textureRect);
        CGContextDrawImage(context, textureRect, subImage);
//
//        NSData* textureData = [[NSData alloc] initWithBytesNoCopy:data length:(NSUInteger) textureSize];

        CGContextRelease(context);
        CGImageRelease(subImage);
    }
    NSDate* end = [[NSDate alloc] init];

    NSTimeInterval delta = [end timeIntervalSinceDate:start];
    NSLog(@"TIME: %f", delta);

    CGImageRef cgImage = CGImageCreateWithImageInRect([uiImage CGImage], subRegion);

    CGContextDrawImage(UIGraphicsGetCurrentContext(), rect, cgImage);

    NSLog(@"IMAGE DRAWN");

    CGImageRelease(cgImage);
}
@end