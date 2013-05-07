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

@interface WWPickSupport : NSObject

@property(nonatomic, readonly) NSMutableDictionary* pickableObjects;

- (WWPickSupport*) init;

- (void) addPickableObject:(WWPickedObject*)pickedObject;

- (void) clearPickList;

- (WWPickedObject*) getTopObject:(WWDrawContext*)dc pickPoint:(WWVec4*)pickPoint;

- (WWPickedObject*) resolvePick:(WWDrawContext*)dc pickPoint:(WWVec4*)pickPoint layer:(WWLayer*)layer;

@end