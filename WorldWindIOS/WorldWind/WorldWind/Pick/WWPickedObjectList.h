/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

@class WWPickedObject;

/**
* Holds a collection of picked objects, one of which is typically marked as "on top".
*/
@interface WWPickedObjectList : NSObject

/// @name Picked Object List Attributes

/// The collection of picked objects. May be empty.
@property(nonatomic, readonly) NSMutableArray* objects;

/**
* Indicates whether the list contains picked objects that are not terrain, i.e., shapes.
*
* @return YES if the list contains non-terrain objects, otherwise NO.
*/
- (BOOL) hasNonTerrainObjects;

/**
* Returns the picked object marked as visibly on top of the other other picked objects in the list.
*
* @return The top picked object, or nil if there are no objects in the list.
*/
- (WWPickedObject*) topPickedObject;

/**
* If the list contains a terrain object, returns that object.
*
* @return The terrain picked object.
 */
- (WWPickedObject*) terrainObject;

/// @name Initializing Picked Object Lists

/**
* Initialize this picked object list. The initial list contains no objects.
*
* @return The initialized object.
*/
- (WWPickedObjectList*) init;

/// @name Operations on Picked Object Lists

/**
* Add a picked object to the list.
*
* This method is typically not called by applications.
*
* @param pickedObject The picked object to add to the list. If nil, the list remains unchanged.
*/
- (void) add:(WWPickedObject*)pickedObject;

/**
* Remove all picked objects from the list.
*
* This method is typically not called by applications.
*/
- (void) clear;

@end