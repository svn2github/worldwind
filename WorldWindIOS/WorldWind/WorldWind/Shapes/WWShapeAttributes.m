/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Shapes/WWShapeAttributes.h"
#import "WorldWind/Util/WWColor.h"
#import "WorldWind/WWLog.h"

@implementation WWShapeAttributes

- (WWShapeAttributes*) init
{
    self = [super init];

    _interiorEnabled = YES;
    _interiorColor = [[WWColor alloc] initWithR:1 g:1 b:1 a:1];

    _outlineEnabled = YES;
    _outlineColor = [[WWColor alloc] initWithR:0 g:0 b:0 a:1];
    _outlineWidth = 1;

    return self;
}

- (WWShapeAttributes*) initWithAttributes:(WWShapeAttributes*)attributes
{
    if (attributes == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Draw context is nil")
    }

    self = [super init];

    _interiorEnabled = [attributes interiorEnabled];
    _outlineEnabled = [attributes outlineEnabled];
    _outlineWidth = [attributes outlineWidth];
    _interiorColor = [[WWColor alloc] initWithColor:[attributes interiorColor]];
    _outlineColor = [[WWColor alloc] initWithColor:[attributes outlineColor]];

    return self;
}

@end