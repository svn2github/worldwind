/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Pick/WWPickedObject.h"
#import "WorldWind/Geometry/WWVec4.h"
#import "WorldWind/Geometry/WWPosition.h"
#import "WorldWind/WWLog.h"

@implementation WWPickedObject

- (WWPickedObject*) initWithColorCode:(int)colorCode
                           userObject:(id)userObject
                            pickPoint:(WWVec4*)pickPoint
                             position:(WWPosition*)position
                            isTerrain:(BOOL)isTerrain
{
    if (pickPoint == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Pick point is nil")
    }

    self = [super init];

    _colorCode = colorCode;
    _userObject = userObject;
    _pickPoint = pickPoint;
    _position = position;
    _isTerrain = isTerrain;

    return self;
}

@end