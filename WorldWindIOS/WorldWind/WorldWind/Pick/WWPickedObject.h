/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>
#import <CoreGraphics/CGGeometry.h>

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

/// The color code used to distinguish this object from others during picking. Not normally used by applications.
@property(nonatomic, readonly) int colorCode;

/// The UIKit screen coordinate pick point used to determine this picked object.
///
/// The pick point is understood to be in the UIKit coordinate system of the WorldWindView, with its origin in the
/// top-left corner and axes that extend down and to the right from the origin point. See the section titled View
/// Geometry and Coordinate Systems in the [View Programming Guide for iOS](http://developer.apple.com/library/ios/#documentation/WindowsViews/Conceptual/ViewPG_iPhoneOS/WindowsandViews/WindowsandViews.html).
@property(nonatomic, readonly) CGPoint pickPoint;

/// The user-recognizable object actually picked, such as a shape the user created.
@property(nonatomic, readonly) id userObject;

/// The geographic position of the picked object. For terrain this is the terrain position. For shapes it is typically
/// the shape's reference position. It may be nil.
@property(nonatomic, readonly) WWPosition* position;

/// The layer in effect when this picked object was picked, typically the layer containing the picked object.
@property(nonatomic, readonly) WWLayer* parentLayer;

/// Indicates whether the picked object is terrain rather than a shape.
@property(nonatomic, readonly) BOOL isTerrain;

/// Indicates whether this picked object is visibly on top of other picked objects in a picked object list.
@property(nonatomic) BOOL isOnTop;

/// @name Initializing Picked Objects

/**
* Initializes a picked object for a non-terrain object to specified values.
*
* This method is typically not called by applications. It is used by shapes to create picked object instances. The
* returned object is assumed to represent a non-terrain object. Sending the isTerrain message to the returned object
* always returns NO.
*
* @param colorCode The color code used to distinguish this object from others during picking. See the colorCode
* property description.
* @param pickPoint The UIKit screen coordinate pick point used to determine this picked object. See the property description.
* @param userObject The user-recognizable object actually picked. See the userObject property description.
* @param position The geographic position of this picked object. See the property description.
* @param parentLayer The layer in effect when this picked object was picked. See the property description.
*/
- (WWPickedObject*) initWithColorCode:(int)colorCode
                            pickPoint:(CGPoint)pickPoint
                           userObject:(id)userObject
                             position:(WWPosition*)position
                          parentLayer:(WWLayer*)parentLayer;

/**
* Initializes a picked object for terrain to specified values.
*
* This method is typically not called by applications. It is used by the tessellator to create picked object instances.
* The returned object is assumed to represent the terrain. Sending the isTerrain message to the returned object always
* returns YES. Additionally, the returned object's userObject and parentLayer are both nil.
*
* @param colorCode The color code used to distinguish the terrain from other objects during picking. See the colorCode
* property description.
* @param pickPoint The UIKit screen coordinate pick point used to determine this picked terrain position. See the property description.
* @param terrainPosition The geographic position of terrain at the pick point. See the property description.
*/
- (WWPickedObject*) initWithColorCode:(int)colorCode
                            pickPoint:(CGPoint)pickPoint
                      terrainPosition:(WWPosition*)terrainPosition;

@end