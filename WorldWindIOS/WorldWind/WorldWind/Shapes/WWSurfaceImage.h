/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WorldWind/Render/WWSurfaceTile.h"
#import "WorldWind/Render/WWRenderable.h"

@class WWDrawContext;
@class WWTexture;

/**
* Provides a surface image shape. A surface image renders an image onto the globe's terrain.
*/
@interface WWSurfaceImage : NSObject <WWSurfaceTile, WWRenderable>

/// @name Surface Image Attributes

/// This surface image's display name.
@property (nonatomic) NSString* displayName;

/// Indicates whether this surface image should be displayed.
@property(nonatomic) BOOL enabled;

/// The sector over which the image is displayed. The image is stretched to fill this region.
@property (readonly, nonatomic) WWSector* sector;

/// The full file-system path to the image.
@property (readonly, nonatomic) NSString* imagePath;

/// The opacity with which to draw the image.
@property (nonatomic) float opacity;

/// @name Initializing Surface Images

/**
* Initialize this surface image instance with a specified image and the sector in which it's displayed.
*
* @param sector The sector over which to spread the image.
* @param imagePath The full file-system path to the image to display.
*
* @return This instance initialized with the specified sector and image.
*
* @exception NSInvalidArgumentException If the specified sector or image path is nil or the image path is empty.
*/
- (WWSurfaceImage*) initWithImagePath:(WWSector*)sector imagePath:(NSString*)imagePath;

/// @name Rendering Surface Images

/**
* Render this surface image.
*
* An OpenGL context must be current when this method is called.
*
* @param dc The current draw context.
*/
- (void) render:(WWDrawContext*)dc;

/// @name Methods of Interest Only to Subclasses

/**
* Makes this surface image's texture the current OpenGL texture.
*
* This method is not meant to be called by applications. It is called internally as needed.
*
* @param dc The current draw context.
*
* @return YES if the texture was successfully bound, otherwise NO.
*/
- (BOOL) bind:(WWDrawContext*)dc;

@end