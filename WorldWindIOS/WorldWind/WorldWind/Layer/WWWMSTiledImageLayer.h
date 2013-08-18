/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WorldWind/Layer/WWTiledImageLayer.h"

@class WWScreenImage;
@class WWWMSCapabilities;
@class WWWMSDimension;

/**
* Provides a Tiled Image Layer that can be easily configured from a WMS capabilities document.
*
* See WWWMSCapabilities for more information about WMS capabilities documents and their representation in World Wind.
*/
@interface WWWMSTiledImageLayer : WWTiledImageLayer

/// @name WMS Tiled Image Layer Attributes

@property WWScreenImage* legendOverlay;

/**
* Specifies the WMS dimension associated with this layer.
*
* @param dimension The WMS dimension associated with this layer.
*/
- (void)setDimension:(WWWMSDimension*)dimension;

/**
* Returns the WMS dimension associated with this layer.
*
* @return The WMS dimension associated with this layer.
*/
- (WWWMSDimension*)dimension;

/**
* Specifies the WMS dimension string associated with this layer.
*
* @param The WMS dimension string associated with this layer.
*/
- (void)setDimensionString:(NSString*)dimensionString;

/**
* Returns the WMS dimension string associated with this layer.
*
* @return The WMS dimension string associated with this layer.
*/
- (NSString*)dimensionString;

/// The WMS server capabilities specified at initialization.
@property(nonatomic, readonly) WWWMSCapabilities* serverCapabilities;

/// The WMS layer capabilities specified at initialization.
@property(nonatomic, readonly) NSDictionary* layerCapabilities;

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