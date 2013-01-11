/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WorldWind/Layer/WWLayer.h"

@class WWSurfaceImage;
@class WWDrawContext;

/**
* Provides a layer containing a single image of Earth. The layer has only one resolution. This class is typically
* used as the base image on a globe.
*/
@interface WWBMNGOneImageLayer : WWLayer

/// @name Attributes

/// The WWSurfaceImage instance used to represent this layer's image.
@property (readonly, nonatomic) WWSurfaceImage* surfaceImage;

/// @name Initializing

/**
* Initializes the layer by retrieving the image from either the local cache or the image's remote location.
*
* @return This instance with the image downloaded, stored locally and initialized,
* or nil if the image could not be retrieved and stored in the cache.
*/
- (WWBMNGOneImageLayer*) init;

/// @name Methods of Interest Only to Subclasses

/**
* Retrieves this layer's image from the internet.
*
* Applications do not need to call this method. It is called
* internally when the layer is initialized. Subclasses may override this method to retrieve the image from a location
 * other than the default. By default, this method retrieves the image from a World Wind site and stores it locally
 * in the application user's cache directory.
 *
 * If an error occurs during retrieval or local storage, a message describing the error is written to the log and the
  * layer's surfaceImage property is nil.
 *
 * @param fileName The name of the file containing the image.
 * @param atLocation The URL at which to find the image.
 * @param toFilePath The full path to a local directory in which to save the retrieved image.
*/
- (void) retrieveImageWithName:(NSString*)fileName atLocation:(NSString*)atLocation toFilePath:(NSString*)toFilePath;

/**
* Overrides the doRender method of the WWLayer base class in order to draw the image.
*
* @param dc The current draw context.
*/
- (void) doRender:(WWDrawContext*)dc;

@end