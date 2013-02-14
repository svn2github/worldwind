/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

@class WWColor;

/**
* Specifies color and other attributes for shapes.
*/
@interface WWShapeAttributes : NSObject

/// @name Shape Attributes

/// Indicates whether a shape's interior is drawn.
@property (nonatomic) BOOL interiorEnabled;

/// Indicates the color of a shape's interior.
@property (nonatomic) WWColor* interiorColor;

/// Indicates whether a shape's outline is drawn.
@property (nonatomic) BOOL outlineEnabled;

/// Indicates the color of a shape's outline.
@property (nonatomic) WWColor* outlineColor;

/// Indicates the line width of a shape's outline.
@property (nonatomic) float outlineWidth;

/// @name Initializing Shape Attributes

/**
* Initializes this attributes instance to default values.
*
* The defaults indicate that both interior and outline are
* drawn, an interior color of white, an outline color of light gray, and an outline width of 1.
*
* @return This attributes instance initialized to default values.
*/
- (WWShapeAttributes*) init;

/**
* Initializes this instance to the values of a specified shape attributes instance.
*
* @param attributes The shape attributes instance whose values are used to initialize this instance.
*
* @return This attributes instance initialized to the specified values.
*
* @exception NSInvalidArgumentException If the specified attributes instance is nil.
*/
- (WWShapeAttributes*) initWithAttributes:(WWShapeAttributes*)attributes;

@end