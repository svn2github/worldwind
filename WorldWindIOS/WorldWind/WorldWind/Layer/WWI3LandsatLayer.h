/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WorldWind/Layer/WWTiledImageLayer.h"


/**
* Represents Landsat imagery contributed by i-cubed.
*/
@interface WWI3LandsatLayer : WWTiledImageLayer

/// @name Initializing the Layer

/**
* Initializes the layer.
*
* @return The initialized layer.
*/
- (WWI3LandsatLayer*) init;

@end