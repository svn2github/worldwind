/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WorldWind/Util/WWCacheable.h"

@class WWMemoryCache;
@class WWSector;

@interface WWElevationImage : NSOperation <WWCacheable>

/// @name Elevation Image Attributes

/** The full file system path to the image containing elevation values. */
@property(nonatomic) NSString* filePath;

/**
 * The sector defining the image's geographic coverage area. This sector need not have the same aspect ratio as the
 * image itself.
 */
@property(nonatomic, readonly) WWSector* sector;

/** The image's width, in number of samples. */
@property(nonatomic, readonly) int imageWidth;

/** The image's height, in number of samples. */
@property(nonatomic, readonly) int imageHeight;

/** The object to send notification to when the image file is read. */
@property(nonatomic, readonly) id object;

/** The memory cache to add this elevation data to when its image file is read. */
@property(nonatomic, readonly) WWMemoryCache* memoryCache;

/// @name Initializing an Elevation Image

/**
* Initialize an elevation image using a specified file system location.
*
* The file path must reference a raw image containing signed 16-bit integers, and must be large enough to contain
* imageWidth x imageHeight 16-bit integers.
*
* @param filePath The full file-system path to the image.
* @param sector The sector defining the image's geographic coverage area. This sector need not have the same aspect
* ratio as the  image itself.
* @param imageWidth The image's width, in number of samples.
* @param imageHeight The image's height, in number of samples.
* @param cache The memory cache into which this image should add itself when its file is read.
* @param object The object to send notification to when the file is read.
*
* @return This elevation image initialized with the specified file.
*
* @exception NSInvalidArgumentException If the file path is nil or empty, if the sector or cache are nil, or if either
* of the the imageWidth or imageHeight are less than or equal to zero.
*/
- (WWElevationImage*) initWithImagePath:(NSString*)filePath
                                 sector:(WWSector*)sector
                             imageWidth:(int)imageWidth
                            imageHeight:(int)imageHeight
                                  cache:(WWMemoryCache*)cache
                                 object:(id)object;

/// @name Operations on Elevation Images

- (void) elevationForLatitude:(double)latitude
                    longitude:(double)longitude
                       result:(double*)result;

- (void) elevationsForSector:(WWSector*)sector
                      numLat:(int)numLat
                      numLon:(int)numLon
        verticalExaggeration:(double)verticalExaggeration
                      result:(double[])result;

/// @name Supporting Methods of Interest only to Subclasses

- (void) loadImage;

@end