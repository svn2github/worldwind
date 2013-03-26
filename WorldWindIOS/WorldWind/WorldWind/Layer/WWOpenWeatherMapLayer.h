/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WorldWind/Layer/WWTiledImageLayer.h"

@interface WWOpenWeatherMapLayer : WWTiledImageLayer

/// @name Initializing the Open Weather Map Precipitation Layer

/**
* Initializes a Open Weather Map Precipitation layer.
*
* @return The initialized layer.
*/
- (WWOpenWeatherMapLayer*) init;

@end