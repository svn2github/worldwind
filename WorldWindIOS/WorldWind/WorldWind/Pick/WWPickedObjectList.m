/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Pick/WWPickedObjectList.h"
#import "WorldWind/Pick/WWPickedObject.h"

@implementation WWPickedObjectList

- (WWPickedObjectList*) init
{
    self = [super init];

    pickedObjects = [[NSMutableArray alloc] init];

    return self;
}

- (BOOL) hasNonTerrainObjects
{
    return [pickedObjects count] > 1 || ([pickedObjects count] == 1 && [self terrainObject] == nil);
}

- (void) add:(WWPickedObject*)pickedObject
{
    if (pickedObject != nil)
    {
        [pickedObjects addObject:pickedObject];
    }
}

- (void) clear
{
    [pickedObjects removeAllObjects];
}

- (WWPickedObject*) topPickedObject
{
    int size = [pickedObjects count];

    if (size > 1)
    {
        for (NSUInteger i = 0; i < size; i++)
        {
            if ([[pickedObjects objectAtIndex:i] isOnTop])
            {
                return [pickedObjects objectAtIndex:i];
            }
        }
    }

    if (size > 0)
    {
        return [pickedObjects objectAtIndex:0];
    }

    return nil;
}

- (WWPickedObject*) terrainObject
{
    for (NSUInteger i = 0; i < [pickedObjects count]; i++)
    {
        if ([[pickedObjects objectAtIndex:i] isTerrain])
        {
            return [pickedObjects objectAtIndex:i];
        }
    }

    return nil;
}

@end