/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WorldWind/Layer/WWTiledImageLayer.h"

@class WWWMSCapabilities;

/**
* Provides a Tiled Image Layer that can be easily configured from a WMS capabilities document.
*
* See WWWMSCapabilities for more information about WMS capabilities documents and their representation in World Wind.
*/
@interface WWWMSTiledImageLayer : WWTiledImageLayer
{
    NSString* cachePath;
    id screenOverlay;
}

/// @name WMS Tiled Image Layer Attributes

/// The WMS server capabilities specified at initialization.
@property(nonatomic, readonly) WWWMSCapabilities* serverCapabilities;

/// The WMS layer capabilities specified at initialization.
@property(nonatomic, readonly) NSDictionary* layerCapabilities;

@property (nonatomic) BOOL showLegend;

/// @name Initializing WMS Tiled Image Layer

/**
* Initialize this instance from a specified WMS capabilities and one of the layer capabilities entries it contains.
*
* @param serverCapabilities A capabilities object describing the WMS server's capabilities.
* @param layerCapabilities A layer capabilities object describing the layer represented by this instance. The layer
* must describe a WMS named layer, i.e., a layer with a "NAME" element in the capabilities document.
*
* @exception NSInvalidArgumentException If the specified server capabilities is nil.
* @exception NSInvalidArgumentException If the specified layer capabilities is nil.
* @exception NSInvalidArgumentException If the layer capabilities indicate a layer without a name.
* @exception NSInvalidArgumentException If the server capabilities does not contain a GetMap URL.
*/
- (WWWMSTiledImageLayer*)initWithWMSCapabilities:(WWWMSCapabilities*)serverCapabilities
                               layerCapabilities:(NSDictionary*)layerCapabilities;

@end