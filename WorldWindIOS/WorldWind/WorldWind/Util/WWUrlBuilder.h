/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

@class WWTile;

/**
* Provides in interface for creating URLs.
*/
@protocol WWUrlBuilder

/// @name Creating a URL for an Image or Elevation Tile

/**
* Create a URL for an image or elevation tiles resource.
*
* @param tile The tile for which to create the URL.
* @param imageFormat The image format to include in the URL if necessary.
*
* @return A URL for the specified tiles resource.
*
* @exception NSInvalidArgumentException if the specified tile is nil or if the image format is nil but necessary.
*/
- (NSURL*) urlForTile:(WWTile*)tile imageFormat:(NSString*)imageFormat;

@end