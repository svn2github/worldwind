/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>
#import <OpenGLES/ES2/gl.h>
#import <UIKit/UIKit.h>

/**
* Represents an RGBA color.
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

/**
* Returns a packed 32-bit integer representation of this RGBA color.
*
* @return A packed unsigned integer containing the r, g, b and a values, in that order.
*/
- (GLuint) colorInt;

/**
* Returns a UIColor representation of this color.
*
* @return A UIColor containing this color's r, g, b and a values.
*/
- (UIColor*) uiColor;

/**
* Stores this color's premultiplied red, green, blue and alpha components in the specified array as 32-bit floating
* point values in the range [0,1].
*
* The array must have space for at least 4 elements. This color's red, green, blue and alpha components are stored in
* array elements 0, 1, 2 and 3, respectively. The red, green and blue components are then multiplied by the alpha
* component.
*
* @param array An array of at least 4 elements. Contains the color's premultiplied red, green, blue and alpha components
* in elements 0, 1, 2, and 3 after this method returns.
*
* @exception NSInvalidArgumentException If the array is NULL.
*/
- (void) premultipliedComponents:(float[])array;

/// @name Initializing Colors

/**
* Initialize this color with specified red, green, blue and alpha components.
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
* Initializes this color with the red, green, blue and alpha components in a packed 32-bit integer representation of an
* RGBA color.
*
* @param colorInt A packed unsigned integer containing the r, g, b and a values, in that order.
*
* @return This color initialized to the specified colorInt's values.
*/
- (WWColor*) initWithColorInt:(GLuint)colorInt;

/**
* Initializes this color with the red, green, blue and alpha components in the specified UIColor.
*
* @param uiColor The UIColor containing the r, g, b and a values.
*
* @return This color initialized to the specified UIColor's values.
*
* @exception NSInvalidArgumentException If the UIColor is nil or cannot be converted into RGB format.
*/
- (WWColor*) initWithUIColor:(UIColor*)uiColor;

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

/// @name Setting the Contents of Colors

/**
* Sets this color's components to the specified red, green, blue and alpha components.
*
* @param r This color's new red component in the range [0,1].
* @param g This color's new green component in the range [0,1].
* @param b This color's new blue component in the range [0,1].
* @param a This color's new alpha component in the range [0,1].
*
* @return This color set to the specified components.
*/
- (WWColor*) setToR:(float)r g:(float)g b:(float)b a:(float)a;

/**
* Sets this color to the components of the specified color.
*
* @param color The color whose components are assigned to this instance's.
*
* @return This color with its components set to those of the specified color.
*
* @exception NSInvalidArgumentException If the color is nil.
*/
- (WWColor*) setToColor:(WWColor*)color;

/// @name Operations on Colors

/**
* Multiplies this color's red, green and blue values by this color's alpha value.
*/
- (void) preMultiply;

/// @name Convenience Functions

/**
* Converts an RGBA color to a packed 32-bit integer representation.
*
* @param r The red value.
* @param g The green value.
* @param b The blue value.
* @param a The alpha value.
*
* @return A packed unsigned integer containing the r, g, b and a values, in that order.
*/
+ (unsigned int) makeColorInt:(GLubyte)r g:(GLubyte)g b:(GLubyte)b a:(GLubyte)a;

/**
* Computes the linear interpolation of two RGBA colors.
*
* The amount indicates the percentage of the two colors, and should be a number between 0.0 and 1.0, inclusive. The
* resultant color is undefined if amount < 0.0 or if amount > 1.0. Otherwise, the resultant color is a linear
* interpolation of the individual RGBA components of color1 and color2 appropriate for the specified amount. For
* example, if amount is 0.5 this outputs a color that is a 50% blend of color1 and color2.
*
* @param color1 The first color.
* @param color2 The second color.
* @param amount The amount to interpolate as a number between 0.0 and 1.0, inclusive.
* @param result A WWColor instance in which to return the linear interpolation of color1 and color2.
*
* @exception NSInvalidArgumentException If any argument is nil.
*/
+ (void) interpolateColor1:(WWColor*)color1 color2:(WWColor*)color2 amount:(double)amount result:(WWColor*)result;

@end