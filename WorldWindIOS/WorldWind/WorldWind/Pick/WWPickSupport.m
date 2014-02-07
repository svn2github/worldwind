/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Pick/WWPickSupport.h"
#import "WorldWind/Pick/WWPickedObject.h"
#import "WorldWind/Render/WWDrawContext.h"

@implementation WWPickSupport

- (WWPickSupport*) init
{
    self = [super init];

    _pickableObjects = [[NSMutableDictionary alloc] init];

    return self;
}

- (void) addPickableObject:(WWPickedObject*)pickedObject
{
    [_pickableObjects setValue:pickedObject forKey:[[NSString alloc] initWithFormat:@"%d", [pickedObject colorCode]]];
}

- (WWPickedObject*) topObject:(WWDrawContext*)dc pickPoint:(CGPoint)pickPoint
{
    if ([_pickableObjects count] == 0)
    {
        return nil;
    }

    unsigned int colorCode = [dc readPickColor:pickPoint];
    if (colorCode == 0) // getPickColor returns 0 if the pick point selects the clear color
    {
        return nil;
    }

    return [_pickableObjects valueForKey:[[NSString alloc] initWithFormat:@"%d", colorCode]];
}

- (WWPickedObject*) resolvePick:(WWDrawContext*)dc
{
    WWPickedObject* pickedObject = [self topObject:dc pickPoint:[dc pickPoint]];
    if (pickedObject != nil)
    {
        [dc addPickedObject:pickedObject];
    }

    [_pickableObjects removeAllObjects]; // clear the pick list to avoid dangling references

    return pickedObject;
}

@end