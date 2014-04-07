/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Util/WWColor.h"
#import "WorldWind/Util/WWMath.h"
#import "WorldWind/WWLog.h"

@implementation WWColor

//--------------------------------------------------------------------------------------------------------------------//
//-- Color Attributes --//
//--------------------------------------------------------------------------------------------------------------------//

- (GLuint) colorInt
{
    GLubyte r = (GLubyte) (255 * _r);
    GLubyte g = (GLubyte) (255 * _g);
    GLubyte b = (GLubyte) (255 * _b);
    GLubyte a = (GLubyte) (255 * _a);

    return r << 24 | g << 16 | b << 8 | a;
}

- (UIColor*) uiColor
{
    return [UIColor colorWithRed:_r green:_g blue:_b alpha:_a];
}

- (void) premultipliedComponents:(float[])array
{
    if (!array)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Array is NULL");
    }

    array[0] = _r * _a;
    array[1] = _g * _a;
    array[2] = _b * _a;
    array[3] = _a;
}

//--------------------------------------------------------------------------------------------------------------------//
//-- Initializing Colors --//
//--------------------------------------------------------------------------------------------------------------------//

- (WWColor*) initWithR:(float)r g:(float)g b:(float)b a:(float)a
{
    self = [super init];

    _r = r;
    _g = g;
    _b = b;
    _a = a;

    return self;
}

- (WWColor*) initWithColorInt:(GLuint)colorInt
{
    self = [super init];

    _r = (0xff & (GLubyte) (colorInt >> 24)) / 255.0;
    _g = (0xff & (GLubyte) (colorInt >> 16)) / 255.0;
    _b = (0xff & (GLubyte) (colorInt >> 8)) / 255.0;
    _a = (0xff & (GLubyte) colorInt) / 255.0;

    return self;
}

- (WWColor*) initWithUIColor:(UIColor*)uiColor
{
    if (uiColor == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"UIColor is nil")
    }

    self = [super init];

    CGFloat r, g, b, a; // use a local CGFloat to correctly handle differences between CGFloat and float
    if (![uiColor getRed:&r green:&g blue:&b alpha:&a])
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"UIColor cannot be converted to RGB format")
    }

    _r = r;
    _g = g;
    _b = b;
    _a = a;

    return self;
}

- (WWColor*) initWithColor:(WWColor*)color
{
    if (color == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Color is nil")
    }

    self = [super init];

    _r = color->_r;
    _g = color->_g;
    _b = color->_b;
    _a = color->_a;

    return self;
}

- (WWColor*) setToR:(float)r g:(float)g b:(float)b a:(float)a
{
    _r = r;
    _g = g;
    _b = b;
    _a = a;

    return self;
}

- (WWColor*) setToColor:(WWColor*)color
{
    if (color == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Color is nil")
    }

    _r = color->_r;
    _g = color->_g;
    _b = color->_b;
    _a = color->_a;

    return self;
}

//--------------------------------------------------------------------------------------------------------------------//
//-- Operations on Colors --//
//--------------------------------------------------------------------------------------------------------------------//

- (void) preMultiply
{
    _r *= _a;
    _g *= _a;
    _b *= _a;
}

//--------------------------------------------------------------------------------------------------------------------//
//-- Convenience Functions --//
//--------------------------------------------------------------------------------------------------------------------//

+ (GLuint) makeColorInt:(GLubyte)r g:(GLubyte)g b:(GLubyte)b a:(GLubyte)a;
{
    return r << 24 | g << 16 | b << 8 | a;
}

+ (void) interpolateColor1:(WWColor*)color1 color2:(WWColor*)color2 amount:(double)amount result:(WWColor*)result
{
    if (color1 == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Color 1 is nil")
    }

    if (color2 == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Color 2 is nil")
    }

    if (result == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Output color is nil")
    }

    float r = (float) [WWMath interpolateValue1:[color1 r] value2:[color2 r] amount:amount];
    float g = (float) [WWMath interpolateValue1:[color1 g] value2:[color2 g] amount:amount];
    float b = (float) [WWMath interpolateValue1:[color1 b] value2:[color2 b] amount:amount];
    float a = (float) [WWMath interpolateValue1:[color1 a] value2:[color2 a] amount:amount];
    [result setToR:r g:g b:b a:a];
}

@end