/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

@class WWVec4;
@class WWLayer;
@class WWPosition;

/**
* Represents a picked object. Picked objects are returned from the WorldWindView pick method. The picked object may
* be terrain, in which case a the picked object contains a WWPosition, or a shape,
* in which case the picked object may or may not contain a WWPosition, depending on the particular shape picked.
* Generally, shapes return their reference position as their pick position.
*/
@interface WWPickedObject : NSObject

/// @name Picked Object Attributes

/// The screen coordinate pick point used to determine this picked object.
@property(nonatomic, readonly) WWVec4* pickPoint;

/// The color code used to distinguish this object from others during picking. Not normally used by applications.
@property(nonatomic, readonly) int colorCode;

/// The user-recognizable object actually picked, such as a shape the user created.
@property(nonatomic, readonly) id userObject;

/// Indicates whether this picked object is visibly on top of other picked objects in a picked object list.
@property(nonatomic) BOOL isOnTop;

/// Indicates whether the picked object is terrain rather than a shape.
@property(nonatomic) BOOL isTerrain;

/// The layer in effect when this picked object was picked, typically the layer containing the picked object.
@property(nonatomic) WWLayer* parentLayer;

/// The geographic position of the picked object. For terrain this is the terrain position. For shapes it is typically
/// the shape's reference position. It may be nil.
@property(nonatomic) WWPosition* position;

/// @name Initializing Picked Objects

/**
* Initializes a picked object to specified values.
*
* This method is typically not called by applications. It is used the tessellator and shapes to create picked object
* instances.
*
* @param colorCode The color code used to distinguish this object from others during picking. See the colorCode
* property description.
* @param userObject The user-recognizable object actually picked. See the userObject property description.
* @param pickPoint The screen coordinate pick point used to determine this picked object. See the property description.
* @param position The geographic position of this picked object. See the property description.
* @param isTerrain Indicates whether this picked object is terrain. See the property description.
*
* @exception NSInvalidArgumentException If the specified pick point is nil.
*/
- (WWPickedObject*) initWithColorCode:(int)colorCode
                           userObject:(id)userObject
                            pickPoint:(WWVec4*)pickPoint
                             position:(WWPosition*)position
                            isTerrain:(BOOL)isTerrain;

@end