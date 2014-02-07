/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Pick/WWPickedObject.h"
#import "WorldWind/Geometry/WWPosition.h"

@implementation WWPickedObject

- (WWPickedObject*) initWithColorCode:(int)colorCode
                            pickPoint:(CGPoint)pickPoint
                           userObject:(id)userObject
                             position:(WWPosition*)position
                          parentLayer:(WWLayer*)parentLayer
{
    self = [super init];

    _colorCode = colorCode;
    _pickPoint = pickPoint;
    _userObject = userObject;
    _position = position;
    _parentLayer = parentLayer;
    _isTerrain = NO;

    return self;
}

- (WWPickedObject*) initWithColorCode:(int)colorCode
                            pickPoint:(CGPoint)pickPoint
                      terrainPosition:(WWPosition*)terrainPosition
{
    self = [super init];

    _colorCode = colorCode;
    _pickPoint = pickPoint;
    _userObject = nil;
    _position = terrainPosition;
    _parentLayer = nil;
    _isTerrain = YES;

    return self;
}

@end