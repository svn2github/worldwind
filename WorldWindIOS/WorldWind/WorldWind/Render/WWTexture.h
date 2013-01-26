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

/**
* Represents a texture. This class is used to wrap images used as textures. It handles loading of the image from
* disk, conversion of the image to an OpenGL texture, and binding of the texture during rendering.
*
* Applications typically do not interact directly with WWTexture instances. They are created and used internally as
* needed.
*/
@interface WWTexture : NSObject <WWDisposable, WWCacheable>

/// @name Texture Attributes

/// The full file system path to the image used as a texture.
@property (nonatomic) NSString* filePath;

/// The texture's width.
@property (readonly, nonatomic) int imageWidth;

/// The texture's height.
@property (readonly, nonatomic) int imageHeight;

/// The OpenGL textureID for the texture. Available only after the bind method is called at least once.
@property (readonly, nonatomic) GLuint textureID;

/// The size of the texture in bytes.
@property (readonly, nonatomic) long textureSize;

/// If YES, indicates that texture creation failed. This flag is set if texture creation fails during the first call
/// to the bind method.
@property (readonly, nonatomic) BOOL textureCreationFailed;

/// @name Initializing Textures

/**
* Initialize a texture using an image at a specified file system location.
*
* @param filePath The full file-system path to the image.
*
* @return This texture initialized with the specified image.
*
* @exception NSInvalidArgumentException If the file path is nil or empty.
*/
- (WWTexture*) initWithImagePath:(NSString*)filePath;

/// @name Operations on Textures

/**
* Bind the texture in OpenGL, thus making it the current texture.
*
* An OpenGL context must be current when this method is called.
*
* This method causes the texture image to be loaded from disk and converted to an OpenGL texture the first time it is
 * called.
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
* Load the texture image from disk and pass it to the GPU.
*
* Called by the bind method the first time that method is called. This method loads the texture from disk and
* converts it to a form suitable for use as an OpenGL texture.
*
* If texture creation fails, this instance's textureCreationFailed flag is set to YES.
*/
- (void) loadTexture;

/**
* Load the compressed texture from disk and pass it to the GPU.
*
* Called by the bind method the first time that method is called. This method loads the texture from disk and
* converts it to a form suitable for use as an OpenGL texture.
*
* If texture creation fails, this instance's textureCreationFailed flag is set to YES.
*/
- (void) loadCompressedTexture;

@end