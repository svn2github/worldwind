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

    _objects = [[NSMutableArray alloc] init];

    return self;
}

- (BOOL) hasNonTerrainObjects
{
    return [_objects count] > 1 || ([_objects count] == 1 && [self terrainObject] == nil);
}

- (void) add:(WWPickedObject*)pickedObject
{
    if (pickedObject != nil)
    {
        [_objects addObject:pickedObject];
    }
}

- (void) clear
{
    [_objects removeAllObjects];
}

- (WWPickedObject*) topPickedObject
{
    int size = [_objects count];

    if (size > 1)
    {
        for (NSUInteger i = 0; i < size; i++)
        {
            if ([[_objects objectAtIndex:i] isOnTop])
            {
                return [_objects objectAtIndex:i];
            }
        }
    }

    if (size > 0)
    {
        return [_objects objectAtIndex:0];
    }

    return nil;
}

- (WWPickedObject*) terrainObject
{
    for (NSUInteger i = 0; i < [_objects count]; i++)
    {
        if ([[_objects objectAtIndex:i] isTerrain])
        {
            return [_objects objectAtIndex:i];
        }
    }

    return nil;
}

@end