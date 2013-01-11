/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WorldWind/Layer/WWTiledImageLayer.h"

/**
* Provides a multi-resolution layer for Blue Marble Next Generation imagery. The imagery is retrieved as needed from
* the NASA World Wind servers. This layer is typically used as the primary low-resolution layer for basic Earth
* imagery. Its best resolution is approximately 90 meters per pixel. As for all layers,
* this layer must be added to the World Wind layer list in order to be displayed.
*/
@interface WWBMNGLayer : WWTiledImageLayer

/// @name Initializing the Blue Marble Next Generation Layer

/**
* Initializes a Blue Marble Next Generation layer.
*
* @return The initialized layer.
*/
- (WWBMNGLayer*) init;

@end