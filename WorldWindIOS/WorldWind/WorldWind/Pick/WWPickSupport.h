/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

@class WWPickedObject;
@class WWDrawContext;
@class WWVec4;
@class WWLayer;

/**
* Provides support methods and data structures for shapes and other items that participate in picking. This class is
* typically not used by applications.
*/
@interface WWPickSupport : NSObject

/// @name Pick Support Attributes

/// A list of picked objects that have been added to this instance.
@property(nonatomic, readonly) NSMutableDictionary* pickableObjects;

/**
* Indicates the object considered visibly on top of all the picked objects in this instance's picked object list.
*
* This method causes a frame-buffer read of the color at the pick position and should therefore be used sparingly.
*
* @param dc The current draw context.
* @param pickPoint The pick point used to resolve the pick.
*
* @return The top picked object, or nil if no object in this instance's picked object list is at the pick point.
*/
- (WWPickedObject*) topObject:(WWDrawContext*)dc pickPoint:(WWVec4*)pickPoint;

/// @name Initializing Pick Support Instances

/**
* Initialize this pick support instance.
*
* @return This instance initialized.
*/
- (WWPickSupport*) init;

/// @name Operations on Pick Support instances

/**
* Add a picked object to this instance's list of picked objects.
*
* @param pickedObject The object to add.
*/
- (void) addPickableObject:(WWPickedObject*)pickedObject;

/**
* Invokes topObject to determine which this instance's picked objects or on top at the pick point, and adds that top
* object to the draw contexts picked object list.
*
* This instance's picked object list is cleared by this method.
*
* @param dc The current draw context.
* @param layer The layer to associate with the top picked object.
*
* @return The top picked object.
*/
- (WWPickedObject*) resolvePick:(WWDrawContext*)dc layer:(WWLayer*)layer;

@end