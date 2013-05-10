/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "WorldWind/Shapes/WWPointPlacemarkAttributes.h"
#import "WorldWind/Util/WWColor.h"
#import "WorldWind/Util/WWOffset.h"
#import "WorldWind/WWLog.h"

@implementation WWPointPlacemarkAttributes

- (WWPointPlacemarkAttributes*) init
{
    self = [super init];

    _imageColor = [[WWColor alloc] initWithR:1 g:1 b:1 a:1];
    _imageOffset = [[WWOffset alloc] initWithFractionX:0.5 y:0.5];
    _imageScale = 1;

    return self;
}

- (WWPointPlacemarkAttributes*) initWithAttributes:(WWPointPlacemarkAttributes*)attributes
{
    if (attributes == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Attributes is nil")
    }

    self = [super init];

    _imagePath = attributes->_imagePath;
    _imageColor = [[WWColor alloc] initWithColor:attributes->_imageColor];
    _imageOffset = [[WWOffset alloc] initWithOffset:attributes->_imageOffset];
    _imageScale = attributes->_imageScale;

    return self;
}

@end