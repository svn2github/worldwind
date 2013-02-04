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

/// The texture's width.
@property(readonly, nonatomic) int imageWidth;

/// The texture's height.
@property(readonly, nonatomic) int imageHeight;

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

+ (void) convertTextureToRaw:(NSString*)imagePath;

@end