/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WorldWind/Layer/WWRenderableLayer.h"

@class WWWMSCapabilities;
@class WWWMSTiledImageLayer;
@class WWScreenImage;

/**
* Displays WMS layers that contain dimensions. Enables the application to choose which dimension to display.
*/
@interface WWWMSDimensionedLayer : WWRenderableLayer
{
    NSDictionary* layerCapabilities;
    NSString* cachePath;
    WWScreenImage* legendOverlay;
}

/// WMS Dimensioned Layer Attributes

/// The 0-origin ordinal number of the enabled dimension.
@property (nonatomic) int enabledDimensionNumber;

/// Indicates whether the layer's legend, if any, is displayed.
@property (nonatomic) BOOL legendEnabled;

/// The number of dimensions for the layer.
- (NSUInteger) dimensionCount;

/// The layer associated with the currently displayed dimension.
- (WWWMSTiledImageLayer*) enabledLayer;

/// Initializing

/**
* Initialize this layer.
*
* @param serverCaps The WMS service capabilities for the layer.
* @param layerCaps The WMS layer capabilities for the layer.
*
* @return The initialized layer.
*
* @exception NSInvalidArgumentException If the server or layer caps are nil.
*/
- (WWWMSDimensionedLayer*) initWithWMSCapabilities:(WWWMSCapabilities*)serverCaps layerCapabilities:(NSDictionary*)layerCaps;

@end