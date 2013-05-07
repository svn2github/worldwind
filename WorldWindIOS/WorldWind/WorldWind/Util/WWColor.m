/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Util/WWColor.h"
#import "WorldWind/WWLog.h"

@implementation WWColor

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

    _r = [color r];
    _g = [color g];
    _b = [color b];
    _a = [color a];

    return self;
}

- (void) preMultiply
{
    _r *= _a;
    _g *= _a;
    _b *= _a;
}

+ (GLuint) makeColorInt:(GLubyte)r g:(GLubyte)g b:(GLubyte)b a:(GLubyte)a;
{
    return r << 24 | g << 16 | b << 8 | a;
}

@end