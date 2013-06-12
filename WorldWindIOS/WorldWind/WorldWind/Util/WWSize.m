/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "WorldWind/Util/WWSize.h"
#import "WorldWind/WorldWindConstants.h"
#import "WorldWind/WWLog.h"

@implementation WWSize

//--------------------------------------------------------------------------------------------------------------------//
//-- Initializing Sizes --//
//--------------------------------------------------------------------------------------------------------------------//

- (WWSize*) initWithWidth:(double)width
                   height:(double)height
               widthUnits:(NSString*)widthUnits
              heightUnits:(NSString*)heightUnits
{
    self = [super init];

    _width = width;
    _height = height;
    _widthUnits = widthUnits;
    _heightUnits = heightUnits;

    return self;
}

- (WWSize*) initWithPixelsWidth:(double)width height:(double)height
{
    self = [super init];

    _width = width;
    _height = height;
    _widthUnits = WW_PIXELS;
    _heightUnits = WW_PIXELS;

    return self;
}

- (WWSize*) initWithFractionWidth:(double)width height:(double)height
{
    self = [super init];

    _width = width;
    _height = height;
    _widthUnits = WW_FRACTION;
    _heightUnits = WW_FRACTION;

    return self;
}

- (WWSize*) initWithOriginalSize
{
    self = [super init];

    _width = 0;
    _height = 0;
    _widthUnits = WW_ORIGINAL_SIZE;
    _heightUnits = WW_ORIGINAL_SIZE;

    return self;
}

- (WWSize*) initWithSize:(WWSize*)size
{
    if (size == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Size is nil")
    }

    self = [super init];

    _width = size->_width;
    _height = size->_height;
    _widthUnits = size->_widthUnits;
    _heightUnits = size->_heightUnits;

    return self;
}

//--------------------------------------------------------------------------------------------------------------------//
//-- Computing the Absolute Size --//
//--------------------------------------------------------------------------------------------------------------------//

- (CGSize) sizeForOriginalWidth:(double)originalWidth
                 originalHeight:(double)originalHeight
                 containerWidth:(double)containerWidth
                containerHeight:(double)containerHeight
{
    double width;
    if ([_widthUnits isEqualToString:WW_FRACTION])
    {
        width = containerWidth * _width;
    }
    else if ([_widthUnits isEqualToString:WW_ORIGINAL_SIZE])
    {
        width = originalWidth;
    }
    else if ([_widthUnits isEqualToString:WW_ORIGINAL_ASPECT])
    {
        width = originalWidth; // replaced below once the height is known
    }
    else // default to WW_PIXELS
    {
        width = _width;
    }

    double height;
    if ([_heightUnits isEqualToString:WW_FRACTION])
    {
        height = containerHeight * _height;
    }
    else if ([_heightUnits isEqualToString:WW_ORIGINAL_SIZE])
    {
        height = originalHeight;
    }
    else if ([_heightUnits isEqualToString:WW_ORIGINAL_ASPECT])
    {
        height = originalHeight; // replaced below once the width is known
    }
    else // default to WW_PIXELS
    {
        height = _height;
    }

    if ([_widthUnits isEqualToString:WW_ORIGINAL_ASPECT])
    {
        width = (originalWidth != 0) ? height * originalHeight / originalWidth : 0;
    }

    if ([_heightUnits isEqualToString:WW_ORIGINAL_ASPECT])
    {
        height = (originalHeight != 0) ? width * originalWidth / originalHeight : 0;
    }

    return CGSizeMake((CGFloat) width, (CGFloat) height);
}

@end