/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

@class WWLayer;

/**
* Displays layer controls and information.
*/
@interface LayerDetailController : UITableViewController

/// @name Attributes

/// The associated layer.
@property (readonly, nonatomic, weak) WWLayer* layer;

/**
* Initialize this instance for a specified layer.
*
* @param layer The layer to associate with this instance.
*
* @exception NSInvalidArgumentException If the specified layer is nil.
*/
- (LayerDetailController*) initWithLayer:(WWLayer*)layer;

/**
* Called by the opacity slider when the user changes the opacity.
*/
- (void) opacityValueChanged:(UISlider*)opacitySlider;

@end