/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WorldWind/Layer/WWTiledImageLayer.h"

@interface WWOpenWeatherMapLayer : WWRenderableLayer
{
    NSTimer* timer;
}

/// @name Initializing the Open Weather Map Layer

/**
* Initializes the Open Weather Map layer.
*
* @return The initialized layer.
*/
- (WWOpenWeatherMapLayer*) init;

@end