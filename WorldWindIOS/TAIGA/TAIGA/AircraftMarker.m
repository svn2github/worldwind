/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "AircraftMarker.h"
#import "WorldWind/Geometry/WWPosition.h"
#import "WorldWind/Render/WWDrawContext.h"
#import "WorldWind/Shapes/WWShapeAttributes.h"
#import "WorldWind/Shapes/WWSphere.h"
#import "WorldWind/Util/WWColor.h"

static const NSTimeInterval ShapeRadius = 10.0;

@implementation AircraftMarker

- (AircraftMarker*) init
{
    self = [super init];

    _displayName = @"Aircraft Marker";
    _enabled = YES;
    _position = [[WWPosition alloc] initWithZeroPosition];
    _color = [[WWColor alloc] initWithR:1 g:1 b:1 a:1];

    shape = [[WWSphere alloc] initWithPosition:_position radiusInPixels:ShapeRadius];
    shapeAttrs = [[WWShapeAttributes alloc] init];
    [shapeAttrs setInteriorColor:_color];
    [shape setAttributes:shapeAttrs];

    return self;
}

- (void) render:(WWDrawContext*)dc
{
    if (!_enabled)
    {
        return;
    }

    [shapeAttrs setInteriorColor:_color];
    [shape setPosition:_position];
    [shape render:dc];
}

@end