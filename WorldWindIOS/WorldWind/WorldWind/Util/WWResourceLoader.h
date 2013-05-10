/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WorldWind/Util/WWDisposable.h"

@class WWGpuResourceCache;
@class WWTexture;

/**
* Encapsulates the pattern of asynchronously loading resources from the file-system or network to a memory cache.
*
* WWResourceLoader provides methods for requesting individual resource types. For example, the method
* textureForImagePath:cache: requests that a texture resource associated should be loaded from an image path, converted
* to a texture object, then placed in a specified memory cache.
*
* Callers should use WWResourceLoader's request methods as their sole mechanism for accessing resources. Each method
* implements the pattern of asynchronously loading resources from the file-system or network and placing them in a
* specified memory cache. By calling these methods whenever a resource is needed, the resource is returned only when it
* is available in memory and would not cause the caller to block the current thread.
*/
@interface WWResourceLoader : NSObject <WWDisposable>
{
@protected
    NSMutableSet* currentLoads; // Used to prevent duplicate loads.
}

/// @name Initializing Resource Loaders

/**
* Initializes a resource loader to its default state.
*
* Adds observers to the default notification center in order to receive resource retrieval and load event notifications.
* These observers are automatically removed when resource loader is deallocated, and can be removed explicitly by
* calling dispose.
*/
- (WWResourceLoader*) init;

/// @name Operations on Resource Loaders

/**
* Removes any observers added to the default notification center during initialization.
*/
- (void) dispose;

/**
* Requests a texture for the specified imagePath, loading the texture from the file-system if necessary.
*
* Searches the cache for a texture associated with the imagePath and returns it if one is found. Otherwise, this
* initiates an asynchronous operation to load the texture from the file-system and returns nil without waiting for the
* load to complete. This prevents duplicate load operations for the same imagePath.
*
* Callers should use this method as their sole mechanism for accessing a textures from a file-system path. This method
* is designed to be called whenever a texture is needed without concern for whether the texture is in memory, is
* currently loading, or has not been loaded.
*
* @param imagePath The full file-system path to the image.
* @param cache The GPU resource cache the texture is added to after loading completes.
*
* @return The texture for the imagePath, or nil if the texture is loading.
*
* @exception NSInvalidArgumentException If any argument is nil.
*/
- (WWTexture*) textureForImagePath:(NSString*)imagePath cache:(WWGpuResourceCache*)cache;

@end