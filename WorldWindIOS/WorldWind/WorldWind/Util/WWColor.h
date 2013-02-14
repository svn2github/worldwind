/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

/**
* Represents and RGBA color.
*/
@interface WWColor : NSObject

/// @name Color Attributes

/// The color's red component in the range [0,1].
@property (nonatomic) float r;

/// The color's green component in the range [0,1].
@property (nonatomic) float g;

/// The color's blue component in the range [0,1].
@property (nonatomic) float b;

/// The color's alpha component in the range [0,1].
@property (nonatomic) float a;

/// @name Initializing Colors

/**
* Initialize this color with specified red, green, blue and alpha values.
*
* @param r The color's red component in the range [0,1].
* @param g The color's green component in the range [0,1].
* @param b The color's blue component in the range [0,1].
* @param a The color's alpha component in the range [0,1].
*
* @return This color initialized to the specified values.
*/
- (WWColor*) initWithR:(float)r g:(float)g b:(float)b a:(float)a;

/**
* Initialize this color with a specified color.
*
* @param color The color identifying this colors initial values.
*
* @return This color initialized to the specified color's values.
*
* @exception NSInvalidArgumentException If the specified color is nil.
*/
- (WWColor*) initWithColor:(WWColor*)color;

/// @name Operations on Colors

/**
* Multiplies this color's red, green and blue values by this color's alpha value.
*/
- (void) preMultiply;

@end