/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "WorldWind/Util/WWOffset.h"
#import "WorldWind/Geometry/WWVec4.h"
#import "WorldWind/WorldWindConstants.h"
#import "WorldWind/WWLog.h"

@implementation WWOffset

- (WWOffset*) initWithX:(double)x y:(double)y xUnits:(NSString*)xUnits yUnits:(NSString*)yUnits
{
    self = [super init];

    _x = x;
    _y = y;
    _xUnits = xUnits;
    _yUnits = yUnits;

    return self;
}

- (WWOffset*) initWithPixelsX:(double)x y:(double)y
{
    self = [self initWithX:x y:y xUnits:WW_PIXELS yUnits:WW_PIXELS];

    return self;
}

- (WWOffset*) initWithInsetPixelsX:(double)x y:(double)y
{
    self = [self initWithX:x y:y xUnits:WW_INSET_PIXELS yUnits:WW_INSET_PIXELS];

    return self;
}

- (WWOffset*) initWithFractionX:(double)x y:(double)y
{
    self = [self initWithX:x y:y xUnits:WW_FRACTION yUnits:WW_FRACTION];

    return self;
}

- (WWOffset*) initWithOffset:(WWOffset*)offset
{
    if (offset == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Offset is nil")
    }

    self = [super init];

    _x = offset->_x;
    _y = offset->_y;
    _xUnits = offset->_xUnits;
    _yUnits = offset->_yUnits;

    return self;
}

- (void) addOffsetForWidth:(double)width height:(double)height xScale:(double)xScale yScale:(double)yScale
                    result:(WWVec4*)result
{
    if (result == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Result is nil")
    }

    double x = [result x];
    double y = [result y];

    if ([_xUnits isEqualToString:WW_FRACTION])
    {
        x += (width * _x) * xScale;
    }
    else if ([_xUnits isEqualToString:WW_INSET_PIXELS])
    {
        x += (width - _x) * xScale;
    }
    else // default to WW_PIXELS
    {
        x += _x * xScale;
    }

    if ([_xUnits isEqualToString:WW_FRACTION])
    {
        y += (height * _y) * yScale;
    }
    else if ([_xUnits isEqualToString:WW_INSET_PIXELS])
    {
        y += (height - _y) * yScale;
    }
    else // default to WW_PIXELS
    {
        y += _y * yScale;
    }

    [result set:x y:y];
}

- (void) subtractOffsetForWidth:(double)width height:(double)height xScale:(double)xScale yScale:(double)yScale
                         result:(WWVec4*)result;
{
    if (result == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Result is nil")
    }

    double x = [result x];
    double y = [result y];

    if ([_xUnits isEqualToString:WW_FRACTION])
    {
        x -= (width * _x) * xScale;
    }
    else if ([_xUnits isEqualToString:WW_INSET_PIXELS])
    {
        x -= (width - _x) * xScale;
    }
    else // default to WW_PIXELS
    {
        x -= _x * xScale;
    }

    if ([_xUnits isEqualToString:WW_FRACTION])
    {
        y -= (height * _y) * yScale;
    }
    else if ([_xUnits isEqualToString:WW_INSET_PIXELS])
    {
        y -= (height - _y) * yScale;
    }
    else // default to WW_PIXELS
    {
        y -= _y * yScale;
    }

    [result set:x y:y];
}

@end