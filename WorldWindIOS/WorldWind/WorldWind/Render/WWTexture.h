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
@class WWGpuResourceCache;

/**
* Represents a texture. This class is used to wrap images used as textures. It handles loading of the image from
* disk, conversion of the image to an OpenGL texture, and binding of the texture during rendering.
*
* This class is an NSOperation so that it can load its image file from disk on a non-main thread.
*
* Applications typically do not interact directly with WWTexture instances. They are created and used internally as
* needed.
*
* ### Non-Power-of-Two Dimensions ###
*
* As of Apple iOS version 6.x, iOS OpenGL drivers do not support mipmapping for textures with non-power-of-two
* dimensions. This limitation is documented in the OpenGL extension APPLE_texture_2D_limited_npot at
* http://www.khronos.org/registry/gles/extensions/APPLE/APPLE_texture_2D_limited_npot.txt.
*
* When WWTexture encounters an image with non-power-of-two dimensions, it allocates an OpenGL texture with power-of-two
* dimensions large enough to fit the original image. The only exceptions to this behavior are images in the PVRTC, 8888
* or 5551 formats, which are loaded unmodified into an OpenGL texture with the dimensions and internal format
* corresponding to the original image data.
*
* WWTexture aligns the image data in the top-left corner of the larger texture. Empty texels appear to the right of and
* beneath the image data as necessary, and are initialized to 0. The OpenGL texture dimensions are indicated by the
* imageWidth and imageHeight properties, whereas the original image dimensions are indicated by originalImageWidth and
* originalImageHeight. The WWMatrix class provides the method [WWMatrix multiplyByTextureTransform:] which concatenates
* a texture coordinate transform appropriate for mapping the portion of a texture's image data to the range [0,1].
*/
@interface WWTexture : NSOperation <WWDisposable, WWCacheable>
{
@protected
    NSData* imageData; // holds image bits between the time they're read from disk and the time they're passed to
    // OpenGL
}

/// @name Texture Attributes

/// The full file system path to the image used as a texture.
@property(nonatomic) NSString* filePath;

/// The texture's width, in texels.
///
/// The texture always has power-of-two dimensions, so this value may be greater than the corresponding
/// originalImageWidth if the image specifying the texture's data has non-power-of-two dimensions.
@property(readonly, nonatomic) int imageWidth;

/// The texture's height, in texels.
///
/// The texture always has power-of-two dimensions, so this value may be greater than the corresponding
/// originalImageHeight if the image specifying the texture's data has non-power-of-two dimensions.
@property(readonly, nonatomic) int imageHeight;

/// The width of the image specifying the texture's data, in pixels.
///
/// The texture always has power-of-two dimensions, so this value may be less than the corresponding textureWidth if the
/// image specifying the texture's data has non-power-of-two dimensions.
@property(readonly, nonatomic) int originalImageWidth;

/// The height of the image specifying the texture's data, in pixels.
///
/// The texture always has power-of-two dimensions, so this value may be less than the corresponding textureHeight if
/// the image specifying the texture's data has non-power-of-two dimensions.
@property(readonly, nonatomic) int originalImageHeight;

/// The number of mipmap levels for compressed textures. (Will be 0 for uncompressed textures.)
@property (nonatomic, readonly) int numLevels;

/// The OpenGL textureID for the texture. Available only after the bind method is called at least once.
@property(readonly, nonatomic) GLuint textureID;

/// The size of the texture in bytes.
@property(readonly, nonatomic) long textureSize;

/// If YES, indicates that texture creation failed. This flag is set if texture creation fails during the first call
/// to the bind method.
@property(readonly, nonatomic) BOOL textureCreationFailed;

/// The object to send notification to when the image file is read.
@property(nonatomic, readonly) id object;

/// The texture cache to add this texture to when its image file is read.
@property(nonatomic, readonly) WWGpuResourceCache* textureCache;

/// The date and time of the texture's image file in the file cache when the image was last loaded into a texture.
// Indicates when the image was last downloaded.
@property (nonatomic, readonly) NSDate* fileModificationDate;

/// @name Initializing Textures

/**
* Initialize a texture using an image at a specified file system location.
*
* @param filePath The full file-system path to the image.
* @param cache The GPU resource cache into which this texture should add itself when its image file is read.
* @param object The object to send notification to when the image file is read.
*
* @return This texture initialized with the specified image.
*
* @exception NSInvalidArgumentException If the file path is nil or empty.
*/
- (WWTexture*) initWithImagePath:(NSString*)filePath cache:(WWGpuResourceCache*)cache object:(id)object;

/// @name Operations on Textures

/**
* Bind the texture in OpenGL, thus making it the current texture.
*
* An OpenGL context must be current when this method is called.
*
* This method causes the texture image to be passed to OpenGL the first time it is called.
 *
 * @param dc The current draw context.
*/
- (BOOL) bind:(WWDrawContext*)dc;

/**
* Release the OpenGL texture ID for this texture.
*
* The OpenGL context associated with the texture must be current when this method is called.
*/
- (void) dispose;

/// @name Supporting Methods of Interest only to Subclasses

/**
* Loads the texture from disk and converts it to a form suitable for use as an OpenGL texture.
*
* This method does not pass the texture to OpenGL because it is typically performed on a non-main thread. The texture
 * is passed to OpenGL in the bind method.
*
* If texture creation fails, this instance's textureCreationFailed flag is set to YES.
*/
- (void) loadEncodedTexture;

/**
* Loads the texture from a PVRTC image file on disk and converts it to a form suitable for use as an OpenGL texture.
*
* This method does not pass the texture to OpenGL because it is typically performed on a non-main thread. The texture
 * is passed to OpenGL in the bind method.
*
* If texture creation fails, this instance's textureCreationFailed flag is set to YES.
*/
- (void) loadCompressedTexture;

/**
* Loads the texture from a raw RGBA image file on disk and converts it to a form suitable for use as an OpenGL texture.
*
* This method does not pass the texture to OpenGL because it is typically performed on a non-main thread. The texture
 * is passed to OpenGL in the bind method.
*
* If texture creation fails, this instance's textureCreationFailed flag is set to YES.
*/
- (void) loadRawTexture;

/**
* Passes the texture to OpenGL. This method is called by the bind method the first time the texture is displayed.
*/
- (void) loadGL;

/**
* Passes the PVRTC texture to OpenGL. This method is called via the bind method the first time the texture is
* displayed.
*/
- (void) loadGLCompressed;

/// @name Converting Textures

/**
* Convert this texture to RGBA 8 bits per pixel.
*
* This method writes the converted image to the same location and name as the incoming image but with the filename
* suffix replaced by "8888".
*
* @param imagePath The full path and filename of the image to convert.
*
* @exception NSInvalidArgumentException If the specified path is nil or zero length.
*/
+ (void) convertTextureTo8888:(NSString*)imagePath;

/**
* Convert this texture to RGBA 5 bits per pixel for RGB and 1 bit for alpha.
*
* This method writes the converted image to the same location and name as the incoming image but with the filename
* suffix replaced by "5551".
*
* @param imagePath The full path and filename of the image to convert.
*
* @exception NSInvalidArgumentException If the specified path is nil or zero length.
*/
+ (void) convertTextureTo5551:(NSString*)imagePath;

@end