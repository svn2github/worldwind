/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WorldWind/Layer/WWTiledImageLayer.h"

/**
* Provides a layer for Open Weather Map data.
*/
@interface OpenWeatherMapLayer : WWTiledImageLayer
{
    NSTimer* timer;
}

/// @name Initializing the Open Weather Map Layer

/**
* Initializes the Open Weather Map layer.
*
* @param layerName The Open Weather Map layer name.
* @param displayName The layer's display name.
*
* @return The initialized layer.
*
* @throws NSInvalidArgumentException If either argument is nil.
*/
- (OpenWeatherMapLayer*) initWithLayerName:(NSString*)layerName displayName:(NSString*)displayName;

@end