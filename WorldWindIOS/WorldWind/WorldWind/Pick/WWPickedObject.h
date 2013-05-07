/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

@class WWVec4;
@class WWLayer;
@class WWPosition;

@interface WWPickedObject : NSObject

@property(nonatomic, readonly) WWVec4* pickPoint;
@property(nonatomic, readonly) int colorCode;
@property(nonatomic, readonly) id userObject;
@property(nonatomic) BOOL isOnTop;
@property(nonatomic) BOOL isTerrain;
@property(nonatomic) WWLayer* parentLayer;
@property(nonatomic) WWPosition* position;

- (WWPickedObject*) initWithColorCode:(int)colorCode userObject:(id)userObject;

- (WWPickedObject*) initWithColorCode:(int)colorCode
                           userObject:(id)userObject
                            pickPoint:(WWVec4*)pickPoint
                             position:(WWPosition*)position
                            isTerrain:(BOOL)isTerrain;

@end