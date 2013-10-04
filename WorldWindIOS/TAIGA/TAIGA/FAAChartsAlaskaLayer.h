/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WorldWind/Layer/WWRenderableLayer.h"

/**
* Displays FAA charts for Alaska.
*/
@interface FAAChartsAlaskaLayer : WWRenderableLayer

/// @name Initializing.

/**
* Initialize this instance.
*
* @return This instance initialized.
*/
- (FAAChartsAlaskaLayer*) init;

@end