/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

@class WWPickedObject;

@interface WWPickedObjectList : NSObject
{
    NSMutableArray* pickedObjects;
}

- (WWPickedObjectList*) init;

- (BOOL) hasNonTerrainObjects;

- (void) add:(WWPickedObject*)pickedObject;

- (void) clear;

- (WWPickedObject*) getTopPickedObject;

- (WWPickedObject*) getTerrainObject;

@end