/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

@class WorldWindView;
@class WWWMSCapabilities;

/**
* Displays the details of a WMS layer and allows selection of its sub-layers.
*/
@interface WMSLayerDetailController : UITableViewController
{
    NSString* layerID; // a unique identifying string for the layer
}

/// @name WMS Server Detail Controller Attributes

/// The WMS layer capabilities specified at initialization.
@property(nonatomic, readonly) WWWMSCapabilities* serverCapabilities;

/// The WMS server capabilities specified at initialization.
@property(nonatomic, readonly) NSDictionary* layerCapabilities;

/// The World Wind View specified at initialization.
@property(nonatomic, readonly) WorldWindView* wwv;

/**
* Initialize this instance.
*
* @param serverCapabilities The WMS capabilities of the associated server.
* @param layerCapabilities The WMS layer capabilities of the associated layer.
* @param size The popover size for the detail controller view.
* @param wwv The application's World Wind View.
*
* @return The initialized instance.
*
* @exception NSInvalidArgumentException If the specified server capabilities is nil.
* @exception NSInvalidArgumentException If the specified layer capabilities is nil.
* @exception NSInvalidArgumentException If the specified World Wind View is nil.
*/
- (WMSLayerDetailController*) initWithLayerCapabilities:(WWWMSCapabilities*)serverCapabilities
                                      layerCapabilities:(NSDictionary*)layerCapabilities
                                                   size:(CGSize)size
                                                 wwView:(WorldWindView*)wwv;

@end