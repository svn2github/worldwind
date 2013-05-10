/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>

@class WWColor;
@class WWOffset;

/**
* Specifies the image and color attributes for a WWPointPlacemark.
*
* Point placemarks may be drawn either as an image or as a square with a specified size. When the placemark attributes
* have a valid imagePath the placemark's image is drawn as a screen rectangle in the image's original dimensions, scaled
* by the imageScale. Otherwise, the placemark is drawn as a screen square with width and height equal to imageScale.
*/
@interface WWPointPlacemarkAttributes : NSObject

/// @name Point Placemark Attributes

/// Indicates the full file-system path to the placemark's image. May be nil to indicate the placemark is drawn as a
/// square in its imageColor.
@property (nonatomic) NSString* imagePath;

/// Indicate the placemark's color. When the placemark attributes have a valid imagePath the placemark's image is
/// multiplied by this color to achieve the final placemark color. Otherwise, placemark is drawn in this color.
@property (nonatomic) WWColor* imageColor;

/// Indicates the location of the placemark relative to its geographic position. When the placemark attributes have a
/// valid imagePath this offset is relative to the image dimensions. Otherwise, this offset is relative to a square with
/// width and height equal to imageScale. May be nil to indicate the placemark's lower left corner is placed at its
/// geographic position.
@property (nonatomic) WWOffset* imageOffset;

/// Indicates the amount to scale the placemark's image. When the placemark attributes have a valid imagePath this scale
/// is applied to the image's dimensions. Otherwise, this scale indicates the dimensions of a square drawn at the point
/// placemark's geographic position. Setting imageScale to 0.0 causes the placemark to disappear.
@property (nonatomic) double imageScale;

/// @name Initializing Shape Attributes

/**
* Initializes this attributes instance to default values.
*
* The defaults indicate a placemark displayed as a white 1x1 square centered on the placemark's geographic position.
*
* @return This attributes instance initialized to default values.
*/
- (WWPointPlacemarkAttributes*) init;

/**
* Initializes this instance to the values of a specified point placemark attributes instance.
*
* @param attributes The point placemark attributes instance whose values are used to initialize this instance.
*
* @return This attributes instance initialized to the specified values.
*
* @exception NSInvalidArgumentException If the specified attributes instance is nil.
*/
- (WWPointPlacemarkAttributes*) initWithAttributes:(WWPointPlacemarkAttributes*)attributes;

@end