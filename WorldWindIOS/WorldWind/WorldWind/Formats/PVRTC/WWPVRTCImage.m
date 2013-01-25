/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <UIKit/UIKit.h>
#import "WorldWind/Formats/PVRTC/WWPVRTCImage.h"
#import "WorldWind/WWLog.h"
#import "WWUtil.h"

@implementation WWPVRTCImage

- (WWPVRTCImage*) initWithContentsOfFile:(NSString*)filePath // TODO
{
    self = [super init];

    if (filePath == nil || [filePath length] == 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"File path is nil or zero length")
    }

    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath])
    {
        NSString* msg = [NSString stringWithFormat:@"File %@ does not exist", filePath];
        WWLOG_AND_THROW(NSInvalidArgumentException, msg);
    }

    // TODO: Throw an exception if the file is not a PVRTC image.

    // TODO: Open file, extract the size and the bits. Prepare for call to loadGL to move the bits to the GPU.

    // TODO: compute the overall image size property (number of bytes). This value is needed by the texture cache.

    return self;
}

- (int) loadGL
{
    // TODO: Make the necessary calls to glGenTextures, glTexParameter and glCompressedTexImage2D to pass the mipmap
    // levels to the GPU. See GpuTexture.doCreateFromCompressedData() in the WWAndroid code for an example.

    return -1; // return the texture ID for this texture.
}

+ (BOOL) compressFile:(NSString*)filePath
{
    if (filePath == nil || [filePath length] == 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"File path is nil or zero length")
    }

    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath])
    {
        NSString* msg = [NSString stringWithFormat:@"File %@ does not exist", filePath];
        WWLOG_AND_THROW(NSInvalidArgumentException, msg);
    }

    // Read the image as a UIImage, get its bits and pass them to the pvrtc compressor,
    // which writes the pvrtc image to a file of the same name and in the same location as the input file,
    // but with a .pvr extension.

    UIImage* uiImage = [UIImage imageWithContentsOfFile:filePath];
    if (uiImage == nil)
    {
        WWLog(@"Unable to load image file %@", filePath);
        return NO;
    }

    CGImageRef cgImage = [uiImage CGImage];

    int imageWidth = CGImageGetWidth(cgImage);
    int imageHeight = CGImageGetHeight(cgImage);
    if (imageWidth == 0 || imageHeight == 0)
    {
        WWLog(@"Image size is zero for file %@", filePath);
        return NO;
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

        NSString* outputPath = [WWUtil replaceSuffixInPath:filePath newSuffix:@"pvr"];
        [self doCompress:imageWidth height:imageHeight bits:imageData ouputPath:outputPath];
        return YES;
    }
    @catch (NSException* exception)
    {

        NSString* msg = [NSString stringWithFormat:@"loading texture data for file %@", filePath];
        WWLogE(msg, exception);
        return NO;
    }
    @finally
    {
        free(imageData); // release the memory allocated for the image
        CGContextRelease(context);
        CGImageRelease(cgImage);
    }
}

#import <stdio.h>
#import <math.h>

typedef struct
{
    float r;
    float g;
    float b;
} RawPixel;

typedef struct
{
    int width;      // actual width of image (>= 8)
    int height;     // actual height of image (>= 8)
    int widthBase;  // requested width of image
    int heightBase; // requested height of image
    void* bits;
} RawImage;

// Per PVRTC file format documentation at
// http://www.imgtec.com/powervr/insider/docs/PVR%20File%20Format.Specification.1.0.11.External.pdf
typedef struct
{
    int version;
    int flags;
    int pixel_format_lsb;
    int pixel_format_msb;
    int color_space;
    int channel_type;
    int height;
    int width;
    int depth;
    int num_surfaces;
    int num_faces;
    int num_mipmaps;
    int size_metadata;
} PVR_Header;

#define PVR_VERSION 0x03525650
#define PVR_FORMAT_PVRTC_4_RGBA 3

// TODO: All the functions below need to be converted to class methods to limit the scope of their name. Small
// functions can get by with simply prefixing their name with WW.

RawImage* NewImage(int width, int height);

void FreeImage(RawImage* image);

int EncodePvrImage(RawImage* src, long** pvrImage);

int EncodePvrMipmap(RawImage* src, long*** pvrMipmap, int** blockCounts);

void WritePvrFile(long** pvrBlocks, int* blockCounts, int levelCount, int dx, int dy, const char* name);

+ (void) doCompress:(int)width height:(int)height bits:(void*)bits ouputPath:(NSString*)outputPath
{
    RawImage rawImage;

    rawImage.width = width;
    rawImage.height = height;
    rawImage.widthBase = width;
    rawImage.heightBase = height;
    rawImage.bits = bits;

    long** pvrMipmap;
    int* blockSizes;
    int levels = EncodePvrMipmap(&rawImage, &pvrMipmap, &blockSizes);

    WritePvrFile(pvrMipmap, blockSizes, levels, width, height, [outputPath cStringUsingEncoding:NSUTF8StringEncoding]);
}
// Quick and dirty test for power of 2.
bool

IsPow2(int n)
{
    if (n <= 0) return false;

    while (n > 1)
    {
        if (n & 1) return false;

        n >>= 1;
    }

    return true;
}

// Get a pixel from an image.
void GetPixel(RawImage* image, int x, int y, RawPixel* pixel)
{
    uint8_t* pix = ((uint8_t*) image->bits) + (image->width * y + x) * 3;

    pixel->r = (float) pix[0];
    pixel->g = (float) pix[1];
    pixel->b = (float) pix[2];
}

// Set a pixel in an image.
void SetPixel(RawImage* image, int x, int y, RawPixel* pixel)
{
    uint8_t* pix = ((uint8_t*) image->bits) + (image->width * y + x) * 3;

    pix[0] = (char) (pixel->r + 0.5);
    pix[1] = (char) (pixel->g + 0.5);
    pix[2] = (char) (pixel->b + 0.5);
}

// initialize a pixel color.
void InitPixel(RawPixel* pixel, float r, float g, float b)
{
    pixel->r = r;
    pixel->g = g;
    pixel->b = b;
}

// Add two pixel colors.
void AddPixel(RawPixel* pixelDst, RawPixel* pixelSrc0, RawPixel* pixelSrc1)
{
    pixelDst->r = pixelSrc0->r + pixelSrc1->r;
    pixelDst->g = pixelSrc0->g + pixelSrc1->g;
    pixelDst->b = pixelSrc0->b + pixelSrc1->b;
}

// Subtract two pixel colors.
void SubPixel(RawPixel* pixelDst, RawPixel* pixelSrc0, RawPixel* pixelSrc1)
{
    pixelDst->r = pixelSrc0->r - pixelSrc1->r;
    pixelDst->g = pixelSrc0->g - pixelSrc1->g;
    pixelDst->b = pixelSrc0->b - pixelSrc1->b;
}

// Compute the difference between two pixels and rescale to fit into a byte pixel.
void DeltaPixel(RawPixel* pixelDst, RawPixel* pixelSrc0, RawPixel* pixelSrc1)
{
    pixelDst->r = 0.5 * (pixelSrc0->r - pixelSrc1->r) + 128.0;
    pixelDst->g = 0.5 * (pixelSrc0->g - pixelSrc1->g) + 128.0;
    pixelDst->b = 0.5 * (pixelSrc0->b - pixelSrc1->b) + 128.0;
}

// Scale a pixel color.
void ScalePixel(RawPixel* pixelDst, RawPixel* pixelSrc, float scale)
{
    pixelDst->r = pixelSrc->r * scale;
    pixelDst->g = pixelSrc->g * scale;
    pixelDst->b = pixelSrc->b * scale;
}

// Interpolate a pixel color.
void LerpPixel(RawPixel* pixelDst, RawPixel* pixelSrc0, RawPixel* pixelSrc1, float wt0, float wt1)
{
    RawPixel pixTmp0;
    ScalePixel(&pixTmp0, pixelSrc0, wt0);

    RawPixel pixTmp1;
    ScalePixel(&pixTmp1, pixelSrc1, wt1);

    AddPixel(pixelDst, &pixTmp0, &pixTmp1);
}

// Compute the dot product of pixel components.
float DotPixel(RawPixel* pixel0, RawPixel* pixel1)
{
    return pixel0->r * pixel1->r + pixel0->g * pixel1->g + pixel0->b * pixel1->b;
}

// Limit value to bounds.
float Clamp(float value, float min, float max)
{
    if (value < min)
        return min;

    if (value > max)
        return max;

    return value;
}

// Prevent pixel under/overflow.
void ClampPixel(RawPixel* pixelDst, RawPixel* pixelSrc)
{
    pixelDst->r = Clamp(pixelSrc->r, 0, 255);
    pixelDst->g = Clamp(pixelSrc->g, 0, 255);
    pixelDst->b = Clamp(pixelSrc->b, 0, 255);
}

// Principal compoment analysis based on:
// http://en.wikipedia.org/wiki/Principal_component_analysis
void PCAPixel(RawPixel* pixelDst, RawPixel* pixelsSrc, int cpixels)
{
    float root3 = 0.577350269189623;
    InitPixel(pixelDst, root3, root3, root3);

    for (int iter = 0; iter < 8; ++iter)
    {
        RawPixel pixelAccum;
        InitPixel(&pixelAccum, 0.0, 0.0, 0.0);

        for (int ipixel = 0; ipixel < cpixels; ++ipixel)
        {
            RawPixel* pixelCur = &pixelsSrc[ipixel];
            float dot = DotPixel(pixelDst, pixelCur);
            pixelAccum.r += dot * pixelCur->r;
            pixelAccum.g += dot * pixelCur->g;
            pixelAccum.b += dot * pixelCur->b;
        }

        // Normalize axis vector.
        float mag2 = DotPixel(&pixelAccum, &pixelAccum);
        float mag = sqrtf(mag2);
        if (mag > 0.0)
        {
            pixelDst->r = pixelAccum.r / mag;
            pixelDst->g = pixelAccum.g / mag;
            pixelDst->b = pixelAccum.b / mag;
        }
        else
            return;
    }
}

// Gather neighboring pixels into an array.
void NeighborhoodPixels(RawImage* image, int xCenter, int yCenter, RawPixel* pixels)
{
    for (int yCur = yCenter - 2; yCur < yCenter + 2; ++yCur)
    {
        for (int xCur = xCenter - 2; xCur < xCenter + 2; ++xCur)
        {
            RawPixel pixelSrc;
            GetPixel(image, xCur, yCur, &pixelSrc);

            InitPixel(pixels,
                    2.0 * (pixelSrc.r - 128.0),
                    2.0 * (pixelSrc.g - 128.0),
                    2.0 * (pixelSrc.b - 128.0));
            ++pixels;
        }
    }
}

// Construct an image that identifies the primary color axis for blocks of 4x4 pixels using Pricipal Component Analysis (PCA).
void PCAImage(RawImage* imageDstHi, RawImage* imageDstLo, RawImage* imageDelta, RawImage* imageSrc, RawImage* imageLowpass)
{
    RawPixel pixelOffset;
    InitPixel(&pixelOffset, 256.0, 256.0, 256.0);

    for (int y = 2; y < imageSrc->height; y += 4)
    {
        for (int x = 2; x < imageSrc->width; x += 4)
        {
            RawPixel pixelLowpass;
            GetPixel(imageLowpass, x >> 2, y >> 2, &pixelLowpass);

            RawPixel pixels[16];
            NeighborhoodPixels(imageDelta, x, y, pixels);

            RawPixel pixelAxis;
            PCAPixel(&pixelAxis, pixels, 16);

            float wMin = 1.0e10;
            float wMax = -1.0e10;
            for (int yInner = -2; yInner < 2; ++yInner)
            {
                for (int xInner = -2; xInner < 2; ++xInner)
                {
                    // Project imageDelta onto PCA.
                    RawPixel pixelDelta;
                    GetPixel(imageDelta, x + xInner, y + yInner, &pixelDelta);

                    // Restore range from 0..256 to -256..256.
                    ScalePixel(&pixelDelta, &pixelDelta, 2.0);
                    SubPixel(&pixelDelta, &pixelDelta, &pixelOffset);

                    float w = DotPixel(&pixelAxis, &pixelDelta);

                    ScalePixel(&pixelDelta, &pixelAxis, w);
                    AddPixel(&pixelDelta, &pixelDelta, &pixelLowpass);

                    // TODO: compute clamped w for each case,
                    // then finally scale and add after best w found.
                    // If color over/underflow detected, ...
                    /*
                     if (pixelDelta.r > 255.0)
                     {
                     w *= (255.0 - pixelLowpass.r) / (pixelDelta.r - pixelLowpass.r);
                     ScalePixel(&pixelDelta, &pixelAxis, w);
                     AddPixel(&pixelDelta, &pixelDelta, &pixelLowpass);
                     }
                     else if (pixelDelta.r < 0.0)
                     {
                     w *= (0.0 - pixelLowpass.r) / (pixelDelta.r - pixelLowpass.r);
                     ScalePixel(&pixelDelta, &pixelAxis, w);
                     AddPixel(&pixelDelta, &pixelDelta, &pixelLowpass);
                     }

                     if (pixelDelta.g > 255.0)
                     {
                     w *= (255.0 - pixelLowpass.g) / (pixelDelta.g - pixelLowpass.g);
                     ScalePixel(&pixelDelta, &pixelAxis, w);
                     AddPixel(&pixelDelta, &pixelDelta, &pixelLowpass);
                     }
                     else if (pixelDelta.g < 0.0)
                     {
                     w *= (0.0 - pixelLowpass.g) / (pixelDelta.g - pixelLowpass.g);
                     ScalePixel(&pixelDelta, &pixelAxis, w);
                     AddPixel(&pixelDelta, &pixelDelta, &pixelLowpass);
                     }

                     if (pixelDelta.b > 255.0)
                     {
                     w *= (255.0 - pixelLowpass.b) / (pixelDelta.b - pixelLowpass.b);
                     ScalePixel(&pixelDelta, &pixelAxis, w);
                     AddPixel(&pixelDelta, &pixelDelta, &pixelLowpass);
                     }
                     else if (pixelDelta.b < 0.0)
                     {
                     w *= (0.0 - pixelLowpass.b) / (pixelDelta.b - pixelLowpass.b);
                     AddPixel(&pixelDelta, &pixelDelta, &pixelLowpass);
                     ScalePixel(&pixelDelta, &pixelAxis, w);
                     }
                     */

                    // Record weight extrema.
                    if (w > wMax) wMax = w;
                    if (w < wMin) wMin = w;
                }
            }

            RawPixel pixelSrc;
            GetPixel(imageLowpass, x >> 2, y >> 2, &pixelSrc);

            RawPixel pixelMin;
            ScalePixel(&pixelMin, &pixelAxis, wMin);
            AddPixel(&pixelMin, &pixelMin, &pixelSrc);
            ClampPixel(&pixelMin, &pixelMin);

            RawPixel pixelMax;
            ScalePixel(&pixelMax, &pixelAxis, wMax);
            AddPixel(&pixelMax, &pixelMax, &pixelSrc);
            ClampPixel(&pixelMax, &pixelMax);

            SetPixel(imageDstLo, x >> 2, y >> 2, &pixelMin);
            SetPixel(imageDstHi, x >> 2, y >> 2, &pixelMax);
        }
    }
}

// Compute the size of an image in bytes.
long SizeImage(int dx, int dy)
{
    // Each pixel fits into 3 bytes.
    return dx * dy * 3;
}

// Allocate a new image.
RawImage* NewImage(int width, int height)
{
    RawImage* image = (RawImage*) malloc(sizeof(RawImage));
    image->widthBase = width;
    image->heightBase = height;
    image->width = (width < 8) ? 8 : width;
    image->height = (height < 8) ? 8 : height;
    image->bits = (char*) malloc(SizeImage(image->width, image->height));

    return image;
}

// Deallocate a previously allocated image.
void FreeImage(RawImage* image)
{
    free(image->bits);
    image->bits = NULL;
    free(image);
}

// Expand actual size to valid legal size if too small
void ExpandImageX(RawImage* image)
{
    if (image->width != image->widthBase)
    {
        for (int y = 0; y < image->height; ++y)
        {
            for (int x = image->widthBase; x < image->width; ++x)
            {
                RawPixel pixel;
                GetPixel(image, x % image->widthBase, y, &pixel);
                SetPixel(image, x, y, &pixel);
            }
        }
    }
}

// Expand actual size to valid legal size if too small
void ExpandImageY(RawImage* image)
{
    if (image->height != image->heightBase)
    {
        for (int y = image->heightBase; y < image->height; ++y)
        {
            for (int x = 0; x < image->width; ++x)
            {
                RawPixel pixel;
                GetPixel(image, x, y % image->heightBase, &pixel);
                SetPixel(image, x, y, &pixel);
            }
        }
    }
}

// Expand actual size to valid legal size if too small
void ExpandImage(RawImage* image)
{
    ExpandImageX(image);
    ExpandImageY(image);
}

// Write a raw image to a file.
void WriteImage(RawImage* image, const char* name)
{
    FILE* file = fopen(name, "wb");

    fwrite(image->bits, 1, SizeImage(image->width, image->height), file);

    fclose(file);
}

// Downsample an image by a factor of 4 in both x and y directions.
void Downsample4Image(RawImage* dst, RawImage* src)
{
    int xBlockMax = (src->width > 2) ? 4 : (src->width > 1) ? 2 : 1;
    int yBlockMax = (src->height > 2) ? 4 : (src->height > 1) ? 2 : 1;

    for (int y = 0; y < src->height; y += 4)
    {
        for (int x = 0; x < src->width; x += 4)
        {
            RawPixel pixAccum;
            InitPixel(&pixAccum, 0.0, 0.0, 0.0);

            for (int xBlock = 0; xBlock < xBlockMax; ++xBlock)
            {
                for (int yBlock = 0; yBlock < yBlockMax; ++yBlock)
                {
                    RawPixel pixCur;
                    GetPixel(src, x + xBlock, y + yBlock, &pixCur);
                    AddPixel(&pixAccum, &pixAccum, &pixCur);
                }
            }
            ScalePixel(&pixAccum, &pixAccum, (1.0 / ((float) xBlockMax * yBlockMax)));
            SetPixel(dst, x >> 2, y >> 2, &pixAccum);
        }
    }
}

// Downsample an image by a factor of 2 in both x and y directions.
void Downsample2Image(RawImage* dst, RawImage* src)
{
    int xBlockMax = (src->width > 1) ? 2 : 1;
    int yBlockMax = (src->height > 1) ? 2 : 1;

    for (int y = 0; y < dst->height; ++y)
    {
        for (int x = 0; x < dst->width; ++x)
        {
            RawPixel pixAccum;
            InitPixel(&pixAccum, 0.0, 0.0, 0.0);

            for (int xBlock = 0; xBlock < xBlockMax; ++xBlock)
            {
                for (int yBlock = 0; yBlock < yBlockMax; ++yBlock)
                {
                    RawPixel pixCur;
                    GetPixel(src, (x << 1) + xBlock, (y << 1) + yBlock, &pixCur);
                    AddPixel(&pixAccum, &pixAccum, &pixCur);
                }
            }
            ScalePixel(&pixAccum, &pixAccum, (1.0 / ((float) xBlockMax * yBlockMax)));
            SetPixel(dst, x, y, &pixAccum);
        }
    }
}

// Upsample an image by a factor of 2 in the x direction.
void UpsampleXImage(RawImage* dst, RawImage* src)
{
    for (int yDst = 0; yDst < dst->height; ++yDst)
    {
        for (int xDst = 0; xDst < dst->width; ++xDst)
        {
            RawPixel pixelDst;
            RawPixel pixelSrc0;
            RawPixel pixelSrc1;

            int xSrc = xDst >> 1;
            int ySrc = yDst;

            GetPixel(src, xSrc, ySrc, &pixelSrc0);

            if (src->width == 1)
            {
                InitPixel(&pixelDst, pixelSrc0.r, pixelSrc0.g, pixelSrc0.b);
            }
            else if (xDst == 0)
            {
                GetPixel(src, xSrc + 1, ySrc, &pixelSrc1);

                LerpPixel(&pixelDst, &pixelSrc0, &pixelSrc1, (5.0 / 4.0), (-1.0 / 4.0));

                // Since we are extrapolating, we may over/underflow.
                ClampPixel(&pixelDst, &pixelDst);
            }
            else if (xDst == dst->width - 1)
            {
                GetPixel(src, xSrc - 1, ySrc, &pixelSrc1);

                LerpPixel(&pixelDst, &pixelSrc0, &pixelSrc1, (5.0 / 4.0), (-1.0 / 4.0));

                // Since we are extrapolating, we may over/underflow.
                ClampPixel(&pixelDst, &pixelDst);
            }
            else if (xDst & 1)
            {
                GetPixel(src, xSrc + 1, ySrc, &pixelSrc1);

                LerpPixel(&pixelDst, &pixelSrc0, &pixelSrc1, (3.0 / 4.0), (1.0 / 4.0));

            }
            else
            {
                GetPixel(src, xSrc - 1, ySrc, &pixelSrc1);

                LerpPixel(&pixelDst, &pixelSrc0, &pixelSrc1, (3.0 / 4.0), (1.0 / 4.0));
            }

            SetPixel(dst, xDst, yDst, &pixelDst);
        }
    }
}

// Upsample an image by a factor of 2 in the y direction.
void UpsampleYImage(RawImage* dst, RawImage* src)
{
    for (int yDst = 0; yDst < dst->height; ++yDst)
    {
        for (int xDst = 0; xDst < dst->width; ++xDst)
        {
            RawPixel pixelDst;
            RawPixel pixelSrc0;
            RawPixel pixelSrc1;

            int xSrc = xDst;
            int ySrc = yDst >> 1;

            GetPixel(src, xSrc, ySrc, &pixelSrc0);

            if (src->height == 1)
            {
                InitPixel(&pixelDst, pixelSrc0.r, pixelSrc0.g, pixelSrc0.b);
            }
            else if (yDst == 0)
            {
                GetPixel(src, xSrc, ySrc + 1, &pixelSrc1);

                LerpPixel(&pixelDst, &pixelSrc0, &pixelSrc1, (5.0 / 4.0), (-1.0 / 4.0));

                // Since we are extrapolating, we may over/underflow.
                ClampPixel(&pixelDst, &pixelDst);
            }
            else if (yDst == dst->height - 1)
            {
                GetPixel(src, xSrc, ySrc - 1, &pixelSrc1);

                LerpPixel(&pixelDst, &pixelSrc0, &pixelSrc1, (5.0 / 4.0), (-1.0 / 4.0));

                // Since we are extrapolating, we may over/underflow.
                ClampPixel(&pixelDst, &pixelDst);
            }
            else if (yDst & 1)
            {
                GetPixel(src, xSrc, ySrc + 1, &pixelSrc1);

                LerpPixel(&pixelDst, &pixelSrc0, &pixelSrc1, (3.0 / 4.0), (1.0 / 4.0));

            }
            else
            {
                GetPixel(src, xSrc, ySrc - 1, &pixelSrc1);

                LerpPixel(&pixelDst, &pixelSrc0, &pixelSrc1, (3.0 / 4.0), (1.0 / 4.0));
            }

            SetPixel(dst, xDst, yDst, &pixelDst);
        }
    }
}

// Upsample an image by a factor of 2 in both the x and y directions.
void Upsample2Image(RawImage* dst, RawImage* src)
{
    int dx = src->width;
    int dy = src->height;

    RawImage* upX2 = NewImage(dx << 1, dy);

    UpsampleXImage(upX2, src);

    UpsampleYImage(dst, upX2);

    FreeImage(upX2);

}

// Upsample an image by a factor of 4 in both the x and y directions.
void Upsample4Image(RawImage* dst, RawImage* src)
{
    int dx = src->width;
    int dy = src->height;

    RawImage* up2 = NewImage(dx << 1, dy << 1);

    Upsample2Image(up2, src);

    Upsample2Image(dst, up2);

    FreeImage(up2);
}

// Compute the difference of two images.
void DeltaImage(RawImage* dst, RawImage* src0, RawImage* src1)
{
    for (int yDst = 0; yDst < dst->height; ++yDst)
    {
        for (int xDst = 0; xDst < dst->width; ++xDst)
        {
            int xSrc = xDst;
            int ySrc = yDst;

            RawPixel pixelSrc0;
            GetPixel(src0, xSrc, ySrc, &pixelSrc0);

            RawPixel pixelSrc1;
            GetPixel(src1, xSrc, ySrc, &pixelSrc1);

            RawPixel pixelDst;
            DeltaPixel(&pixelDst, &pixelSrc0, &pixelSrc1);

            SetPixel(dst, xDst, yDst, &pixelDst);
        }
    }
}

// Compute the interpolation weight at each pixel and encode in an "iamge".
void WtImage(RawImage* wt, RawImage* src, RawImage* lo, RawImage* hi)
{
    int dx = wt->width;
    int dy = wt->height;

    for (int y = 0; y < dy; ++y)
    {
        for (int x = 0; x < dx; ++x)
        {
            RawPixel pixelLo;
            GetPixel(lo, x, y, &pixelLo);

            RawPixel pixelHi;
            GetPixel(hi, x, y, &pixelHi);

            RawPixel pixelSrc;
            GetPixel(src, x, y, &pixelSrc);

            RawPixel pixelSubSrc;
            SubPixel(&pixelSubSrc, &pixelSrc, &pixelLo);

            RawPixel pixelSubHi;
            SubPixel(&pixelSubHi, &pixelHi, &pixelLo);

            float lenSubHi = DotPixel(&pixelSubHi, &pixelSubHi);

            RawPixel pixelWt;
            float w = 0.0;

            if (lenSubHi > 0.0)
            {
                float lenSubSrc = DotPixel(&pixelSubSrc, &pixelSubHi);

                w = Clamp(lenSubSrc / lenSubHi, 0, 1);
            }

            w *= 255.0;

            InitPixel(&pixelWt, w, w, w);

            SetPixel(wt, x, y, &pixelWt);
        }
    }
}

// Interpolate two images with a weight "image"..
void LerpImage(RawImage* dst, RawImage* src0, RawImage* src1, RawImage* wt)
{
    int dx = dst->width;
    int dy = dst->height;

    for (int y = 0; y < dy; ++y)
    {
        for (int x = 0; x < dx; ++x)
        {
            RawPixel pixel0;
            GetPixel(src0, x, y, &pixel0);

            RawPixel pixel1;
            GetPixel(src1, x, y, &pixel1);

            RawPixel pixelWt;
            GetPixel(wt, x, y, &pixelWt);

            RawPixel pixelDst;
            SubPixel(&pixelDst, &pixel1, &pixel0);
            ScalePixel(&pixelDst, &pixelDst, pixelWt.r / 255.0);
            AddPixel(&pixelDst, &pixelDst, &pixel0);

            SetPixel(dst, x, y, &pixelDst);
        }
    }
}

// Initialize of PVRTC file header.
void InitPvrHeader(PVR_Header* header, int dx, int dy, int levels)
{
    memset(header, 0, sizeof(PVR_Header));

    header->version = PVR_VERSION;
    header->pixel_format_lsb = PVR_FORMAT_PVRTC_4_RGBA;
    header->width = dx;
    header->height = dy;
    header->depth = 1;
    header->num_surfaces = 1;
    header->num_faces = 1;
    header->num_mipmaps = levels;
}

// Compute (x,y) from Morton index. See description at:
// http://en.wikipedia.org/wiki/Z-order_curve
void IndexToXY(unsigned int idx, int* x, int* y)
{
    int xCur = 0;
    int yCur = 0;

    int mask = 1;

    while (idx != 0)
    {
        if (idx & 2)
            xCur |= mask;

        if (idx & 1)
            yCur |= mask;

        mask <<= 1;
        idx >>= 2;
    }

    *x = xCur;
    *y = yCur;
}

// Encode an RGB888 pixel as RBG555.
unsigned short RGB555FromPixel(RawPixel* pixel)
{
    int r = (int) (pixel->r * 31.0 / 255.0 + 0.5);
    int g = (int) (pixel->g * 31.0 / 255.0 + 0.5);
    int b = (int) (pixel->b * 31.0 / 255.0 + 0.5);

    unsigned short rgb = 0;

    rgb |= 1;
    rgb <<= 5;
    rgb |= r;
    rgb <<= 5;
    rgb |= g;
    rgb <<= 5;
    rgb |= b;

    return rgb;
}

// Encode a 4x4 pixel block by 2 RGB555 pixel extrema and 2-bit weights for each pixel.
unsigned long PackPvrBlock(RawImage* imageLo, RawImage* imageHi, RawImage* imageWt, int x, int y)
{
    RawPixel pixelLo;
    RawPixel pixelHi;

    GetPixel(imageLo, x, y, &pixelLo);
    GetPixel(imageHi, x, y, &pixelHi);

    unsigned short rgbLo = RGB555FromPixel(&pixelLo);
    unsigned short rgbHi = RGB555FromPixel(&pixelHi);

    // Clear "modulation mode" bit
    rgbLo &= ~1;

    // Accumulator for 2-bit pixel weights.
    unsigned int wts = 0;

    for (int iy = 3; iy >= 0; --iy)
    {
        for (int ix = 3; ix >= 0; --ix)
        {
            wts <<= 2;

            RawPixel pixelWt;
            GetPixel(imageWt, (x << 2) + ix, (y << 2) + iy, &pixelWt);

            // Map intensity to interpolation bits
            // 0..1/4, 1/4..1/2, 1/2..3/4, 3/4..1 => 00, 01, 10, 11
            unsigned int wt = pixelWt.r;
            wts |= (wt >> 6);
        }
    }

    unsigned long block = ((unsigned long) wts) | (((unsigned long) rgbHi) << 48) | (((unsigned long) rgbLo) << 32);
    return block;
}

// Encode an image as a PVRTC image.
int EncodePvrImage(RawImage* src, long** pvrImage)
{
    int dx = src->width;
    int dy = src->height;

    // PVRTC only works for powers of 2!
    if (!IsPow2(dx) || !IsPow2(dy))
    {
        *pvrImage = NULL;
        return 0;
    }

    RawImage* down4 = NewImage(dx >> 2, dy >> 2);
    Downsample4Image(down4, src);

    // DEBUG: Dump low pass image.
    //WriteImage(down4, "/Users/danm/Pictures/testLopass.raw");

    RawImage* up4 = NewImage(dx, dy);
    Upsample4Image(up4, down4);

    // DEBUG: Dump upsampled low pass image.
    //WriteImage(up4, "/Users/danm/Pictures/testLopass4.raw");

    RawImage* delta = NewImage(dx, dy);
    DeltaImage(delta, src, up4);

    // DEBUG: Dump delta image.
    //WriteImage(delta, "/Users/danm/Pictures/testDelta.raw");

    RawImage* lo = NewImage(dx >> 2, dy >> 2);
    RawImage* hi = NewImage(dx >> 2, dy >> 2);
    PCAImage(hi, lo, delta, src, down4);

    RawImage* lo4 = NewImage(dx, dy);
    Upsample4Image(lo4, lo);

    RawImage* hi4 = NewImage(dx, dy);
    Upsample4Image(hi4, hi);

    // DEBUG: Dump color extrema images in both downsampled and upsampled form.
    //WriteImage(hi, "testHi.raw");
    //WriteImage(lo, "testLo.raw");
    //WriteImage(hi4, "testHi4.raw");
    //WriteImage(lo4, "testLo4.raw");

    // Using a full RawImage for the wieghts is overkill, since all we
    // really need is an 8-bit integer quantity. This simply reuses existing
    // machinery rather than defining a completely new one.
    RawImage* wt = NewImage(dx, dy);
    WtImage(wt, src, lo4, hi4);

    // DEBUG: Simulate and dump interpolated image.
    //RawImage* pvrtc = NewImage(dx, dy);
    //LerpImage(pvrtc, lo4, hi4, wt);
    //WriteImage(pvrtc, "testPvrtc.raw");

    // DEBUG: Dump error image.
    //RawImage* error = NewImage(dx, dy);
    //DeltaImage(error, src, pvrtc);
    //WriteImage(error, "testError.raw");

    int blockCount = (dx >> 2) * (dy >> 2);
    *pvrImage = (long*) malloc(blockCount * sizeof(long));
    long* blockDst = *pvrImage;
    int blockCur = 0;

    for (unsigned int idx = 0; ; ++idx)
    {
        int x;
        int y;

        IndexToXY(idx, &x, &y);

        if (x < (dx >> 2) && y < (dy >> 2))
        {
            long block = PackPvrBlock(lo, hi, wt, x, y);
            *blockDst++ = block;
            ++blockCur;
        }

        if (x >= (dx >> 2) && y >= (dy >> 2))
            break;
    }

    //assert(blockCount == blockCur);

    FreeImage(wt);
    FreeImage(hi4);
    FreeImage(lo4);
    FreeImage(lo);
    FreeImage(hi);
    FreeImage(delta);
    FreeImage(up4);
    FreeImage(down4);

    return blockCount;
}

// Encode an image mipmap as a PVRTC image.
int EncodePvrMipmap(RawImage* src, long*** pvrMipmap, int** blockCounts)
{
    int levelMax = 0;
    int xyMax = (src->widthBase > src->heightBase) ? src->widthBase : src->heightBase;

    while (xyMax != 0)
    {
        ++levelMax;
        xyMax >>= 1;
    }

    *blockCounts = (int*) malloc(levelMax * sizeof(int));
    *pvrMipmap = (long**) malloc(levelMax * sizeof(long*));

    int* blockCount = *blockCounts;
    long** pvrImage = *pvrMipmap;

    RawImage* imageCur = src;

    for (int level = 0; level < levelMax; ++level)
    {
        *blockCount = EncodePvrImage(imageCur, pvrImage);
        ++blockCount;
        ++pvrImage;

        int width = imageCur->widthBase >> 1;
        if (width == 0)
            width = 1;

        int height = imageCur->heightBase >> 1;
        if (height == 0)
            height = 1;

        RawImage* imageNxt = NewImage(width, height);

        Downsample2Image(imageNxt, imageCur);

        if (imageCur != src)
            FreeImage(imageCur);

        imageCur = imageNxt;
    }

    if (imageCur != src)
        FreeImage(imageCur);

    return levelMax;
}

// Write a PVRTC file.
void WritePvrFile(long** pvrBlocks, int* blockCounts, int levelCount, int dx, int dy, const char* name)
{
    // TODO: This function should be using framework (NS) methods for file I/O and catching and logging I/O
    // exceptions.

    PVR_Header header;

    InitPvrHeader(&header, dx, dy, levelCount);

    FILE* file = fopen(name, "wb");

    fwrite(&header, 1, sizeof(PVR_Header), file);

    for (int level = 0; level < levelCount; ++level)
    {
        long* blocks = pvrBlocks[level];
        int count = blockCounts[level];
        fwrite(blocks, sizeof(long), count, file);
    }

    fclose(file);
}
@end