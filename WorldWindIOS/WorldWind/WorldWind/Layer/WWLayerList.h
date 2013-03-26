/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

@class WWLayer;

/**
* Holds a list of WWLayer instances in the order in which they are to be rendered.
*/
@interface WWLayerList : NSObject
{
@protected
    NSMutableArray* layers;
}

/// @name Layer List Attributes

- (NSUInteger) count;

/// @name Initializing

/**
* Initialize a layer list.
*
* @return This layer list, initialized with an empty list.
*/
- (WWLayerList*) init;

/// @name Querying a Layer List

/**
* Returns the layer at a specified location in this layer list.
*
* @param index The index, 0 origin, of the layer to return.
*
* @return The layer at the specified index.
*
* @exception NSRangeException if the index is greater than or equal to the number of layers in the list.
*/
- (WWLayer*) layerAtIndex:(NSUInteger)index;

/// @name Operations on Layer Lists

/**
* Appends a specified layer to the end of this layer list.
*
* @param layer The layer to add.
*
* @exception NSInvalidArgumentException If the specified layer is nil.
*/
- (void) addLayer:(WWLayer*)layer;

/**
* Inserts a specified layer into this layer list at the specified position.
*
* Layers at and beyond the specified position prior to inserting the layer are shifted to their next higher positions.
*
* @param layer The layer to insert.
* @param atIndex The position, 0 origin, at which to insert the layer.
*
* @exception NSInvalidArgumentException If the specified layer is nil.
* @exception NSRangeException If the specified position is greater than or equal to the number of layers in the list.
*/
- (void) insertLayer:(WWLayer*)layer atIndex:(NSUInteger)atIndex;

/**
* Remove a specified layer from this layer list.
*
* @param layer The layer to remove.
*
* @exception NSInvalidArgumentException if the specified layer is nil.
*/
- (void) removeLayer:(WWLayer*)layer;

/**
* Remove a layer at a specified location in the layer list.
*
* @param rowIndex The index, 0 origin, of the layer to remove.
*
* @exception NSInvalidArgumentException If the specified index is invalid.
*/
- (void) removeLayerAtRow:(int)rowIndex;

/**
* Moves a layer from one position to another in the layer list.
*
* @param fromIndex The index, 0 origin, of the layer to move.
* @param toIndex The index, 0 origin, of the layer's new location. Other layers are moved further down the list as
* necessary to accommodate the layer at its new position.
*
* @exception NSInvalidArgumentException if either index is invalid.
*/
- (void) moveLayerAtRow:(int)fromIndex toRow:(int)toIndex;

@end
