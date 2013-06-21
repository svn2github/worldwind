/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Util/WWColor.h"
#import "WorldWind/WWLog.h"

@implementation WWColor

//--------------------------------------------------------------------------------------------------------------------//
//-- Color Attributes --//
//--------------------------------------------------------------------------------------------------------------------//

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

@end